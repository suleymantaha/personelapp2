"""
Dynamic Model Routing for Multi-Agent Army
Routes tasks to appropriate model tiers based on complexity analysis.

Optimized for Flutter/Dart projects (personelapp2).
"""

from enum import Enum
from dataclasses import dataclass
from typing import Optional
import re


class ModelTier(Enum):
    LOCAL = "local"           # Ollama/Llama.cpp - FREE
    CHEAP = "cheap"           # Haiku/GPT-4o-mini - $0.25-0.15/1M
    STANDARD = "standard"     # Sonnet/GPT-4o - $3-5/1M
    PREMIUM = "premium"       # Opus/o1 - $15-60/1M


@dataclass
class RoutingRule:
    task_patterns: list[str]      # keywords that trigger this rule
    required_tier: ModelTier
    max_tokens: int
    thinking_budget: int
    description: str = ""         # Human-readable description for debugging


@dataclass
class ModelConfig:
    tier: str
    model: str
    max_tokens: int
    thinking_budget: int


# Model mapping per tier (adjust based on your provider)
TIER_TO_MODEL = {
    ModelTier.LOCAL: "ollama/llama3.1:8b",
    ModelTier.CHEAP: "anthropic/claude-3-5-haiku-20241022",
    ModelTier.STANDARD: "anthropic/claude-sonnet-4-5",
    ModelTier.PREMIUM: "anthropic/claude-opus-4-5",
}

# OpenRouter alternatives (uncomment if using OpenRouter)
# TIER_TO_MODEL = {
#     ModelTier.LOCAL: "ollama/llama3.1:8b",
#     ModelTier.CHEAP: "openrouter/anthropic/claude-3.5-haiku",
#     ModelTier.STANDARD: "openrouter/anthropic/claude-sonnet-4-5",
#     ModelTier.PREMIUM: "openrouter/anthropic/claude-opus-4",
# }


ROUTING_TABLE: list[RoutingRule] = [
    # ===================================================================
    # TIER 0: LOCAL (FREE)
    # Ultra simple, deterministic, formatting/tooling tasks
    # ===================================================================
    RoutingRule(
        description="File ops, formatting, pub, build_runner, git",
        task_patterns=[
            # File operations
            "read_file", "list_dir", "list_directory", "search_files",
            "grep", "find file", "cat ", "head ", "tail ",
            # Dart/Flutter tooling (deterministic)
            "dart format", "flutter pub get", "flutter pub upgrade",
            "build_runner", "dart run build_runner",
            "dart fix --apply", "dart fix --dry-run",
            "flutter clean",
            # Git
            "git status", "git diff", "git log", "git show",
            "git add", "git commit",
            # Python tooling (for non-Flutter tasks)
            "lint", "ruff check", "ruff format",
        ],
        required_tier=ModelTier.LOCAL,
        max_tokens=4000,
        thinking_budget=0,
    ),

    # ===================================================================
    # TIER 1: CHEAP (Haiku)
    # Routine coding, testing, simple analysis, doc updates
    # ===================================================================
    RoutingRule(
        description="Tests, widget tests, simple fixes, docs, config",
        task_patterns=[
            # Flutter/Dart testing
            "widget test", "flutter test", "dart test",
            "write test", "add test", "unit test",
            "testwidgets", "pumwidget", "widgettester",
            "mock", "mockito", "generateMocks",
            # Simple fixes
            "dart fix", "fix lint", "fix format", "fix import",
            "add import", "remove unused", "sort import",
            "missing const", "add const", "const constructor",
            # Config/docs
            "update readme", "update pubspec", "bump version",
            "docstring", "dart doc", "add documentation",
            "rename ", "move file",
            # Simple widget tweaks
            "fix color", "fix text style", "fix padding", "fix margin",
            "update string", "update label",
        ],
        required_tier=ModelTier.CHEAP,
        max_tokens=8000,
        thinking_budget=500,
    ),

    # ===================================================================
    # TIER 2: STANDARD (Sonnet)
    # Feature implementation, widgets, providers, DAOs
    # ===================================================================
    RoutingRule(
        description="Widget/screen impl, Riverpod providers, Drift DAOs, refactoring",
        task_patterns=[
            # Flutter UI
            "widget", "screen", "scaffold", "statelesswidget", "statefulwidget",
            "consumerwidget", "consumerstatewidget",
            "listview", "gridview", "column", "row", "stack",
            "appbar", "bottomnavigation", "drawer", "dialog", "bottomsheet",
            "form", "textfield", "elevated button", "inkwell",
            "responsive", "layoutbuilder", "mediaquery",
            # State management (Riverpod)
            "riverpod", "provider", "notifier", "asyncnotifier",
            "stateprovider", "futureprovider", "streamprovider",
            "watch", "read provider", "ref.watch", "ref.read",
            # Database (Drift)
            "drift", "dao", "table", "database", "sqlite",
            "query", "insert", "update", "delete", "stream",
            "databaseaccessor", "driftaccessor",
            # Navigation
            "go_router", "gorouter", "context.push", "context.go",
            "route", "navigation",
            # General implementation
            "implement", "create ", "build ", "develop ",
            "refactor", "restructure", "extract widget",
            "add feature", "new screen", "new widget", "new provider",
            "integration ", "connect ", "wire up",
            # Python/general (fallback)
            "class ", "function ", "model ", "schema ",
        ],
        required_tier=ModelTier.STANDARD,
        max_tokens=16000,
        thinking_budget=2000,
    ),

    # ===================================================================
    # TIER 3: PREMIUM (Opus/o1)
    # Architecture, security, complex state, performance
    # ===================================================================
    RoutingRule(
        description="Architecture decisions, complex state, security, performance",
        task_patterns=[
            # Architecture
            "architect", "architecture", "design system", "design pattern",
            "layered architecture", "clean architecture",
            "dependency injection", "service locator",
            # Flutter-specific complex topics
            "complex state", "state machine", "animation controller",
            "custom render", "custom painter", "platform channel",
            "performance optim", "render performance", "jank",
            "memory leak", "widget rebuild analysis",
            # Security
            "security review", "security audit", "vulnerability",
            "sensitive data", "encryption", "secure storage",
            # General complex
            "root cause", "race condition", "complex debug",
            "major refactor", "migration plan", "adr",
            "design decision", "tradeoff",
            "bottleneck", "profiling",
        ],
        required_tier=ModelTier.PREMIUM,
        max_tokens=32000,
        thinking_budget=8000,
    ),
]


def route_task(task_description: str, role: str = "") -> ModelConfig:
    """
    Analyze task description and role to determine optimal model tier.

    Args:
        task_description: What the agent needs to do
        role: Agent role (flutter_coder, flutter_tester, flutter_reviewer, etc.)

    Returns:
        ModelConfig with tier, model name, token limits, thinking budget
    """
    text = f"{task_description} {role}".lower()

    # Check each rule in order (first match wins — most specific first)
    for rule in ROUTING_TABLE:
        if any(pattern.lower() in text for pattern in rule.task_patterns):
            return ModelConfig(
                tier=rule.required_tier.value,
                model=TIER_TO_MODEL[rule.required_tier],
                max_tokens=rule.max_tokens,
                thinking_budget=rule.thinking_budget,
            )

    # Default: STANDARD tier
    return ModelConfig(
        tier=ModelTier.STANDARD.value,
        model=TIER_TO_MODEL[ModelTier.STANDARD],
        max_tokens=16000,
        thinking_budget=2000,
    )


def get_model_for_role(role: str) -> ModelConfig:
    """Fallback: route based on Flutter/Dart role alone when task description unavailable."""
    role_routing = {
        # Flutter-specific roles
        "flutter_coder": ModelTier.STANDARD,
        "flutter_tester": ModelTier.CHEAP,
        "flutter_reviewer": ModelTier.PREMIUM,
        "flutter_refactorer": ModelTier.STANDARD,
        "flutter_documenter": ModelTier.CHEAP,
        # Generic roles (backward compat)
        "coder": ModelTier.STANDARD,
        "tester": ModelTier.CHEAP,
        "reviewer": ModelTier.PREMIUM,
        "refactorer": ModelTier.STANDARD,
        "documenter": ModelTier.CHEAP,
    }
    tier = role_routing.get(role.lower(), ModelTier.STANDARD)
    return ModelConfig(
        tier=tier.value,
        model=TIER_TO_MODEL[tier],
        max_tokens=16000 if tier != ModelTier.CHEAP else 8000,
        thinking_budget=2000 if tier != ModelTier.CHEAP else 500,
    )


def explain_routing(task_description: str, role: str = "") -> str:
    """Debug helper: explain why a task was routed to a specific tier."""
    text = f"{task_description} {role}".lower()
    for rule in ROUTING_TABLE:
        matched = [p for p in rule.task_patterns if p.lower() in text]
        if matched:
            config = ModelConfig(
                tier=rule.required_tier.value,
                model=TIER_TO_MODEL[rule.required_tier],
                max_tokens=rule.max_tokens,
                thinking_budget=rule.thinking_budget,
            )
            return (
                f"Tier: {config.tier.upper()} ({rule.description})\n"
                f"Matched patterns: {matched[:3]}\n"
                f"Model: {config.model}\n"
                f"Max tokens: {config.max_tokens} | Thinking: {config.thinking_budget}"
            )
    return f"No pattern matched → DEFAULT: STANDARD tier ({TIER_TO_MODEL[ModelTier.STANDARD]})"


def estimate_cost(model_config: ModelConfig, input_tokens: int, output_tokens: int) -> float:
    """Rough cost estimation per model tier (USD per 1M tokens)."""
    cost_per_million = {
        ModelTier.LOCAL: 0.0,
        ModelTier.CHEAP: 0.25,      # Haiku: $0.25 input, $1.25 output
        ModelTier.STANDARD: 3.0,    # Sonnet: $3 input, $15 output
        ModelTier.PREMIUM: 15.0,    # Opus: $15 input, $75 output
    }
    tier = ModelTier(model_config.tier)
    rate = cost_per_million.get(tier, 3.0)
    # Blended rate approximation
    return (input_tokens + output_tokens) * rate / 1_000_000


if __name__ == "__main__":
    # Quick test — Flutter/Dart specific tasks
    test_tasks = [
        ("dart format lib/", "flutter_coder"),
        ("flutter pub get", ""),
        ("build_runner watch", "flutter_coder"),
        ("write widget test for DashboardScreen", "flutter_tester"),
        ("add unit test for NobetDao", "flutter_tester"),
        ("implement NobetListesiScreen scaffold with Riverpod", "flutter_coder"),
        ("create Drift DAO for Nobet table with watchAll and insert", "flutter_coder"),
        ("add Riverpod AsyncNotifierProvider for personnel list", "flutter_coder"),
        ("set up go_router route for new screen", "flutter_coder"),
        ("security review for sensitive data handling in auth feature", "flutter_reviewer"),
        ("architecture decision: Riverpod vs BLoC for complex state", ""),
        ("performance optimization: reduce widget rebuild count", "flutter_refactorer"),
    ]

    print("=" * 70)
    print("Flutter/Dart Model Router — Test Results")
    print("=" * 70)

    for task, role in test_tasks:
        config = route_task(task, role)
        explanation = explain_routing(task, role)
        print(f"\nTask: {task[:60]}")
        print(f"Role: {role or '(none)'}")
        print(f"  → {explanation.splitlines()[0]}")

    print("\n" + "=" * 70)
    print("Cost estimation examples:")
    standard = route_task("implement widget", "flutter_coder")
    cheap = route_task("flutter test", "flutter_tester")
    print(f"  Standard (10k tokens): ${estimate_cost(standard, 8000, 2000):.4f}")
    print(f"  Cheap (10k tokens):    ${estimate_cost(cheap, 8000, 2000):.4f}")