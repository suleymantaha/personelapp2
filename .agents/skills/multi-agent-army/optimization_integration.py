"""
Optimization Integration Layer for Multi-Agent Army
Combines all optimization strategies into unified configuration.
"""
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

sys.path.insert(0, str(Path(__file__).parent))

from model_router import route_task, ModelTier
from context_compressor import (
    compress_agent_output,
    sliding_window_history,
    summarize_tool_output,
)
from tool_cache import get_cache, cached_tool_call, CACHEABLE_TOOLS


@dataclass
class OptimizationConfig:
    """Unified configuration for all optimization strategies."""
    
    # Model Routing
    enable_model_routing: bool = True
    default_tier: ModelTier = ModelTier.STANDARD
    
    # Context Compression
    enable_context_compression: bool = True
    max_agent_output_chars: int = 3000
    sliding_window_size: int = 15
    compress_delegation_results: bool = True
    
    # Thinking Budgets
    enable_thinking_caps: bool = True
    default_thinking_budget: int = 2000
    max_thinking_budget: int = 8000
    
    # Structured Communication
    enforce_structured_output: bool = True
    worker_output_schema: str = "json"  # json | yaml | structured_text
    
    # Caching
    enable_caching: bool = True
    cache_ttl_seconds: int = 3600
    cacheable_tools: set = field(default_factory=lambda: CACHEABLE_TOOLS)
    
    # Cost Tracking
    track_costs: bool = True
    cost_per_million_tokens: dict = field(default_factory=lambda: {
        "local": 0.0,
        "cheap": 0.25,
        "standard": 3.0,
        "premium": 15.0,
    })
    
    # Performance Targets
    target_cost_reduction_pct: int = 70
    target_latency_reduction_pct: int = 50


class OptimizationContext:
    """
    Runtime context that holds optimization state and provides
    utility methods for agents to use optimizations.
    """
    
    def __init__(self, config: OptimizationConfig):
        self.config = config
        self.cache = get_cache() if config.enable_caching else None
        self.total_cost = 0.0
        self.total_tokens = 0
        self.api_calls = 0
        self.cache_hits = 0
        self.cache_misses = 0
    
    def route_model(self, task_description: str, role: str) -> dict:
        """Determine optimal model for task."""
        if not self.config.enable_model_routing:
            return {"tier": self.config.default_tier.value, "model": "default"}
        return route_task(task_description, role)
    
    def compress_output(self, raw_output: str) -> str:
        """Compress agent output for context efficiency."""
        if not self.config.enable_context_compression:
            return raw_output
        if len(raw_output) <= self.config.max_agent_output_chars:
            return raw_output
        
        result = compress_agent_output(raw_output, self.config.max_agent_output_chars)
        return result
    
    def apply_window(self, messages: list) -> list:
        """Apply sliding window to message history."""
        if not self.config.enable_context_compression:
            return messages
        return sliding_window_history(messages, self.config.sliding_window_size)
    
    def get_thinking_budget(self, tier: str, role: str) -> int:
        """Get thinking budget for model tier and role."""
        if not self.config.enable_thinking_caps:
            return 0  # No cap
        
        base_budgets = {
            "local": 0,
            "cheap": 500,
            "standard": 2000,
            "premium": 8000,
        }
        
        role_multipliers = {
            "coder": 1.0,
            "tester": 0.5,
            "reviewer": 1.5,
            "refactorer": 0.8,
            "documenter": 0.3,
            "orchestrator": 2.0,
            "team_lead": 1.5,
        }
        
        base = base_budgets.get(tier, self.config.default_thinking_budget)
        multiplier = role_multipliers.get(role, 1.0)
        budget = int(base * multiplier)
        return min(budget, self.config.max_thinking_budget)
    
    def wrap_tool_call(self, tool: str, args: dict, call_func):
        """Execute tool call with caching."""
        if not self.config.enable_caching or tool not in self.config.cacheable_tools:
            return call_func()
        
        output = cached_tool_call(tool, args, call_func, self.config.cache_ttl_seconds)
        if output.startswith("[CACHED]"):
            self.cache_hits += 1
        else:
            self.cache_misses += 1
        return output
    
    def track_usage(self, tier: str, input_tokens: int, output_tokens: int):
        """Track token usage and cost."""
        if not self.config.track_costs:
            return
        
        self.total_tokens += input_tokens + output_tokens
        self.api_calls += 1
        
        cost_per_m = self.config.cost_per_million_tokens.get(tier, 3.0)
        cost = (input_tokens + output_tokens) / 1_000_000 * cost_per_m
        self.total_cost += cost
    
    def get_stats(self) -> dict:
        """Get optimization statistics."""
        cache_stats = self.cache.stats() if self.cache else {}
        return {
            "cost_usd": round(self.total_cost, 4),
            "total_tokens": self.total_tokens,
            "api_calls": self.api_calls,
            "cache_hits": self.cache_hits,
            "cache_misses": self.cache_misses,
            "cache_hit_rate": round(
                self.cache_hits / max(1, self.cache_hits + self.cache_misses), 2
            ),
            "cache_entries": cache_stats.get("entries", 0),
            "cache_size_mb": cache_stats.get("size_estimate_mb", 0),
        }


# Global optimization context (set by orchestrator)
_optimization_context: Optional[OptimizationContext] = None


def init_optimizations(config: Optional[OptimizationConfig] = None) -> OptimizationContext:
    """Initialize global optimization context."""
    global _optimization_context
    _optimization_context = OptimizationContext(config or OptimizationConfig())
    return _optimization_context


def get_optimization_context() -> OptimizationContext:
    """Get global optimization context."""
    if _optimization_context is None:
        return init_optimizations()
    return _optimization_context


def create_worker_delegation_context(worker_config: dict) -> dict:
    """
    Create enriched context for worker delegation with all optimizations applied.
    
    Adds to context:
    - model_tier: Recommended model tier
    - thinking_budget: Token budget for reasoning
    - output_schema: Expected output format
    - compression_notice: Reminder to keep output concise
    """
    ctx = get_optimization_context()
    
    task_desc = worker_config.get("goal", "")
    role = worker_config.get("role", "coder")
    
    routing = ctx.route_model(task_desc, role)
    thinking_budget = ctx.get_thinking_budget(routing.tier, role)
    
    optimization_block = f"""
╔═══════════════════════════════════════════════════════════════════╗
║                    OPTIMIZATION DIRECTIVES                       ║
╠═══════════════════════════════════════════════════════════════════╣
║ MODEL TIER: {routing.tier.upper():<12} │ THINKING BUDGET: {thinking_budget:>5} tokens     ║
║ OUTPUT: JSON only (structured) │ MAX OUTPUT: {ctx.config.max_agent_output_chars} chars   ║
║ CACHING: ENABLED │ THINKING CAP: {'ON' if ctx.config.enable_thinking_caps else 'OFF'}                    ║
╠═══════════════════════════════════════════════════════════════════╣
║ MANDATORY OUTPUT FORMAT (JSON):                                 ║
║ {{                                                                ║
║   "status": "completed|failed|blocked",                         ║
║   "summary": "1-2 sentence summary",                            ║
║   "files_changed": ["path/to/file.py", ...],                    ║
║   "tests_added": ["path/to/test.py", ...],                      ║
║   "quality_gates": {{"lint": true, "typecheck": true}},          ║
║   "notes": "Any blockers or decisions"                          ║
║ }}                                                                ║
║                                                                  ║
║ ⚠️  DO NOT include full code, logs, or explanations in output.  ║
║ ⚠️  Use tools with caching for repeated file reads.             ║
╚═══════════════════════════════════════════════════════════════════╝
"""
    
    return {
        **worker_config,
        "optimization": {
            "model_tier": routing.tier,
            "model_name": routing.model,
            "thinking_budget": thinking_budget,
            "max_output_chars": ctx.config.max_agent_output_chars,
            "output_schema": ctx.config.worker_output_schema,
            "enable_caching": ctx.config.enable_caching,
        },
        "optimization_directives": optimization_block,
    }


def apply_optimizations_to_delegation(delegation_params: dict) -> dict:
    """Apply all optimizations to a delegate_task call."""
    ctx = get_optimization_context()
    
    # Apply to each task in batch
    if "tasks" in delegation_params:
        for task in delegation_params["tasks"]:
            # Add optimization context
            opt_context = create_worker_delegation_context(task)
            task["context"] = task.get("context", "") + opt_context["optimization_directives"]
            task["optimization"] = opt_context["optimization"]
    
    # Add orchestrator-level settings
    delegation_params["optimization"] = {
        "model_routing": ctx.config.enable_model_routing,
        "context_compression": ctx.config.enable_context_compression,
        "thinking_caps": ctx.config.enable_thinking_caps,
        "structured_output": ctx.config.enforce_structured_output,
        "caching": ctx.config.enable_caching,
    }
    
    return delegation_params


# Demo
if __name__ == "__main__":
    config = OptimizationConfig()
    ctx = init_optimizations(config)
    
    # Test routing
    tasks = [
        ("Implement user authentication with JWT", "coder"),
        ("Run pytest and fix failing tests", "tester"),
        ("Security review for SQL injection", "reviewer"),
        ("Write README documentation", "documenter"),
    ]
    
    for task, role in tasks:
        routing = ctx.route_model(task, role)
        budget = ctx.get_thinking_budget(routing["tier"], role)
        print(f"Task: {task[:50]}...")
        print(f"  Role: {role} → Tier: {routing['tier']}, Budget: {budget} tokens")
    
    # Test compression
    long_output = "Line\n" * 500
    compressed = ctx.compress_output(long_output)
    print(f"\nCompression: {len(long_output)} → {len(compressed)} chars")
    
    # Test stats
    print(f"\nStats: {ctx.get_stats()}")