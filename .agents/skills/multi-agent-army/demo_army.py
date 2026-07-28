#!/usr/bin/env python3
"""
Multi-Agent Army Demo: 3-Level Hierarchy with Full Optimization Stack
Orchestrator (depth 0) → Team Leads (depth 1) → Workers (depth 2)

Features Included:
1. Dynamic Model Routing (LOCAL/CHEAP/STANDARD/PREMIUM)
2. Per-Role Thinking Budgets
3. Context Compression & Sliding Window
4. Structured Inter-Agent Communication (JSON Schemas)
5. Tool Output Caching
6. Quality Control Gates Execution Engine
7. Self-Healing Architecture with Semantic Error Feedback
8. Human-In-The-Loop (HITL) Risk Triggers
9. Git Worktree Work Isolation
"""

import json
import os
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Dict, List, Any

# Import our new optimization modules
import sys
sys.path.insert(0, str(Path(__file__).parent))
from model_router import route_task, ModelTier
from context_compressor import compress_agent_output, sliding_window_history
from tool_cache import get_cache, cached_tool_call
from optimization_integration import (
    init_optimizations,
    get_optimization_context,
    create_worker_delegation_context,
    apply_optimizations_to_delegation,
    OptimizationConfig,
)

# =============================================================================
# CONFIGURATION
# =============================================================================

# Use temp directory for demo to avoid permission issues
DEMO_ROOT = Path(tempfile.mkdtemp(prefix="multi-agent-army-demo-")).resolve()
PROJECT_ROOT = DEMO_ROOT / "project"
WORKTREES_ROOT = DEMO_ROOT / "worktrees"
TASKS_ROOT = PROJECT_ROOT / "tasks"

ARMY_CONFIG = {
    "epic": "Build a complete user authentication system with JWT tokens",
    "team_leads": [
        {
            "id": "backend",
            "name": "Backend Team Lead",
            "domain": "REST API + Database",
            "workdir": WORKTREES_ROOT / "backend",
            "workers": [
                {"id": "be-1", "role": "coder", "task": "Implement User model + PostgreSQL schema"},
                {"id": "be-2", "role": "coder", "task": "Implement JWT token generation + validation"},
                {"id": "be-3", "role": "coder", "task": "Implement /auth/register, /auth/login, /auth/refresh endpoints"},
                {"id": "be-4", "role": "tester", "task": "Write unit tests for auth endpoints (90% coverage)"},
                {"id": "be-5", "role": "reviewer", "task": "Security review: SQL injection, token leakage, timing attacks"},
            ]
        },
        {
            "id": "frontend",
            "name": "Frontend Team Lead",
            "domain": "React SPA",
            "workdir": WORKTREES_ROOT / "frontend",
            "workers": [
                {"id": "fe-1", "role": "coder", "task": "Build Login/Register forms with validation"},
                {"id": "fe-2", "role": "coder", "task": "Implement JWT token storage (httpOnly cookie + memory)"},
                {"id": "fe-3", "role": "coder", "task": "Create protected routes + auth context provider"},
                {"id": "fe-4", "role": "tester", "task": "Write E2E tests for auth flows (Cypress/Playwright)"},
                {"id": "fe-5", "role": "reviewer", "task": "Accessibility audit + XSS vulnerability check"},
            ]
        },
        {
            "id": "qa",
            "name": "QA Team Lead",
            "domain": "Integration & Contract Testing",
            "workdir": WORKTREES_ROOT / "qa",
            "workers": [
                {"id": "qa-1", "role": "tester", "task": "Write contract tests for auth API (Pact/Schemathesis)"},
                {"id": "qa-2", "role": "tester", "task": "Write integration tests: register -> login -> refresh -> logout"},
                {"id": "qa-3", "role": "documenter", "task": "Generate OpenAPI spec + Postman collection"},
                {"id": "qa-4", "role": "coder", "task": "Set up CI pipeline: lint, test, build, deploy preview"},
            ]
        }
    ]
}

ROLE_GATES = {
    "coder":      ["ruff check .", "mypy .", "pytest -x", "ruff format --check ."],
    "tester":     ["pytest --cov=src --cov-fail-under=90"],
    "reviewer":   ["bandit -r .", "detect-secrets scan ."],
    "refactorer": ["pytest -x", "pytest --cov=src --cov-fail-under=90"],
    "documenter": ["markdown-link-check *.md"],
}

# =============================================================================
# UTILITIES
# =============================================================================

def run(cmd: str, cwd: Path = None, check: bool = True) -> subprocess.CompletedProcess:
    """Run shell command, return result."""
    print(f"$ {cmd}")
    if os.name == 'nt':
        win_cmd = cmd.replace("'", '"')
        full_cmd = f'cmd /c {win_cmd}'
    else:
        full_cmd = cmd
    result = subprocess.run(full_cmd, shell=True, cwd=cwd or PROJECT_ROOT, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout[:2000])
    if result.stderr and check:
        print(f"STDERR: {result.stderr[:1000]}")
    if check and result.returncode != 0:
        raise RuntimeError(f"Command failed ({result.returncode}): {cmd}")
    return result

def ensure_dirs():
    """Create required directory structure."""
    WORKTREES_ROOT.mkdir(parents=True, exist_ok=True)
    TASKS_ROOT.mkdir(parents=True, exist_ok=True)
    for level in ["orchestrator"] + [tl["id"] for tl in ARMY_CONFIG["team_leads"]]:
        for q in ["queue", "active", "done", "checkpoints"]:
            (TASKS_ROOT / level / f"{q}.jsonl").parent.mkdir(parents=True, exist_ok=True)

def init_git_repo():
    """Initialize git repo if needed."""
    if not (PROJECT_ROOT / ".git").exists():
        run("git init", cwd=PROJECT_ROOT)
        run("git config user.email 'army@demo.local'", cwd=PROJECT_ROOT)
        run("git config user.name 'Multi-Agent Army'", cwd=PROJECT_ROOT)
        (PROJECT_ROOT / "README.md").write_text("# Demo Project\n")
        run("git add README.md", cwd=PROJECT_ROOT)
        run("git commit -m 'chore: initial commit'", cwd=PROJECT_ROOT)

def create_worktrees():
    """Create git worktrees for each team lead."""
    result = run("git symbolic-ref --short HEAD", cwd=PROJECT_ROOT, check=False)
    default_branch = result.stdout.strip() if result.returncode == 0 else "master"
    
    for tl in ARMY_CONFIG["team_leads"]:
        workdir = Path(tl["workdir"])
        if not workdir.exists():
            print(f"Creating worktree: {workdir}")
            branch = f"team/{tl['id']}"
            run(f"git branch {branch} 2>nul || true", cwd=PROJECT_ROOT)
            run(f"git worktree add \"{workdir}\" {branch}", cwd=PROJECT_ROOT)
        else:
            print(f"Worktree exists: {workdir}")

def write_task(queue_file: Path, task: Dict):
    """Append task to JSONL queue."""
    with queue_file.open("a") as f:
        f.write(json.dumps(task) + "\n")

def read_queue(queue_file: Path) -> List[Dict]:
    """Read all tasks from JSONL queue."""
    if not queue_file.exists():
        return []
    with queue_file.open() as f:
        return [json.loads(line) for line in f if line.strip()]

# =============================================================================
# QUALITY GATES & SELF-HEALING ENGINES
# =============================================================================

def execute_quality_gates(role: str, workdir: Path) -> Dict[str, Any]:
    """Quality Gate Execution Engine: executes quality check commands for a role."""
    gates = ROLE_GATES.get(role, [])
    results = []
    all_passed = True
    feedback = []

    for gate_cmd in gates:
        try:
            res = run(gate_cmd, cwd=workdir, check=False)
            passed = (res.returncode == 0)
            if not passed:
                all_passed = False
                feedback.append(f"[FAIL] Quality Gate Failed: `{gate_cmd}`\nStderr:\n{res.stderr or 'No stderr'}\nStdout:\n{res.stdout}")
            results.append({"cmd": gate_cmd, "passed": passed, "stdout": res.stdout, "stderr": res.stderr})
        except Exception as e:
            all_passed = False
            feedback.append(f"[ERROR] Gate Execution Exception: `{gate_cmd}` -> {str(e)}")
            results.append({"cmd": gate_cmd, "passed": False, "error": str(e)})

    return {
        "passed": all_passed,
        "role": role,
        "workdir": str(workdir),
        "details": results,
        "semantic_feedback": "\n\n".join(feedback) if not all_passed else "All quality gates passed successfully."
    }

def check_hitl_trigger(action_type: str, details: Dict[str, Any]) -> bool:
    """Human-In-The-Loop (HITL) Safety Gate."""
    HIGH_RISK_ACTIONS = ["merge_to_main", "delete_database", "deploy_production", "hard_reset"]
    if action_type in HIGH_RISK_ACTIONS:
        print(f"[HITL Trigger] Action '{action_type}' requires Human Approval!")
        return True
    if details.get("failure_count", 0) >= 3:
        print(f"[HITL Trigger] Task '{details.get('task_id')}' exceeded failure threshold ({details.get('failure_count')}). Operator intervention required.")
        return True
    return False

def self_healing_retry_loop(task: Dict[str, Any], role: str, workdir: Path, max_retries: int = 3) -> Dict[str, Any]:
    """Self-Healing Architecture Engine with semantic error feedback & exponential backoff."""
    for attempt in range(1, max_retries + 1):
        print(f"\n[Self-Healing] Attempt {attempt}/{max_retries} for task '{task.get('id')}'...")
        gate_result = execute_quality_gates(role, workdir)
        
        if gate_result["passed"]:
            print(f"[Self-Healing OK] Task '{task.get('id')}' passed all quality gates on attempt {attempt}.")
            return {"status": "success", "attempts": attempt, "details": gate_result}
        
        print(f"[Self-Healing FAIL] Attempt {attempt} failed. Generating Semantic Error Feedback:")
        print(gate_result["semantic_feedback"])
        
        if attempt < max_retries:
            backoff_seconds = 2 ** attempt
            print(f"[Backoff] Delay: {backoff_seconds}s before retrying with semantic error context...")
            time.sleep(backoff_seconds)
        else:
            hitl_required = check_hitl_trigger("max_retries_exceeded", {"task_id": task.get("id"), "failure_count": attempt})
            return {
                "status": "hitl_escalation_required" if hitl_required else "failed",
                "attempts": attempt,
                "semantic_feedback": gate_result["semantic_feedback"]
            }

# =============================================================================
# CONTEXT BUILDERS (with Optimization Integration)
# =============================================================================

def spawn_orchestrator():
    """Build the orchestrator's initial task and context."""
    # Initialize optimizations
    opt_ctx = get_optimization_context()
    
    # Get routing for orchestrator task
    routing = opt_ctx.route_model(
        "Orchestrate: Build complete auth system with JWT tokens. Spawn 3 team leads, track progress, merge results.",
        "orchestrator"
    )
    thinking_budget = opt_ctx.get_thinking_budget(routing.tier, "orchestrator")
    
    context = f"""You are the ORCHESTRATOR (depth 0) of a multi-agent army.

EPIC: {ARMY_CONFIG['epic']}

TEAM LEADS TO SPAWN (depth 1):
{json.dumps([{"id": tl["id"], "name": tl["name"], "domain": tl["domain"], "workdir": str(tl["workdir"])} for tl in ARMY_CONFIG["team_leads"]], indent=2)}

YOUR MISSION:
1. For EACH team lead, call delegate_task with:
   - role: "orchestrator"
   - goal: Specific domain objective
   - context: Full project context + workdir + worker roster
   - workdir: Their isolated git worktree

2. Track progress in: {TASKS_ROOT}/orchestrator/queue.jsonl, active.jsonl, done.jsonl

3. Quality Gates per role:
{json.dumps(ROLE_GATES, indent=2)}

4. When ALL team leads report done:
   - Request HITL approval before merging worktrees back to main
   - Run integration tests across all components

OPTIMIZATION DIRECTIVES (Auto-Applied):
{create_worker_delegation_context({
    "goal": "Orchestrate multi-agent army for auth system",
    "role": "orchestrator"
})["optimization_directives"]}"""
    return {
        "role": "orchestrator",
        "goal": f"Orchestrate: {ARMY_CONFIG['epic']}. Spawn 3 team leads, track progress, merge results.",
        "context": context
    }

def build_team_lead_context(team_lead: Dict) -> str:
    """Build context for a team lead agent."""
    workers = team_lead["workers"]
    return f"""You are the TEAM LEAD: {team_lead['name']} (depth 1)

DOMAIN: {team_lead['domain']}
WORKDIR: {team_lead['workdir']} (ISOLATED GIT WORKTREE)

YOUR WORKERS (depth 2 - leaf):
{json.dumps([{"id": w["id"], "role": w["role"], "task": w["task"]} for w in workers], indent=2)}

YOUR MISSION:
1. For EACH worker, call delegate_task with:
   - role: "leaf"
   - goal: Their specific task
   - context: Standards + quality gates + self-healing retry loop
   - workdir: Sub-worktree under {team_lead['workdir']}/workers/<worker_id>

2. ENFORCE QUALITY GATES & SELF-HEALING RETRIES before accepting worker results:
{json.dumps(ROLE_GATES, indent=2)}
"""

def build_worker_context(worker: Dict, team_lead: Dict) -> str:
    """Build context for a leaf worker with quality gates & self-healing."""
    gates = ROLE_GATES.get(worker["role"], [])
    # Get optimization context for this worker
    opt_context = create_worker_delegation_context({
        "goal": worker["task"],
        "role": worker["role"]
    })
    return f"""You are a LEAF WORKER (depth 2).
ROLE: {worker['role'].upper()}
TASK: {worker['task']}
TEAM: {team_lead['name']} ({team_lead['domain']})
WORKDIR: {team_lead['workdir']}/workers/{worker['id']} (ISOLATED)

QUALITY GATES YOU MUST PASS:
{json.dumps(gates, indent=2)}

SELF-HEALING INSTRUCTIONS:
- Run quality gate checks after implementation.
- If gates fail, read the Semantic Error Feedback and perform self-healing retries up to 3 times before escalating.

{opt_context['optimization_directives']}"""

# =============================================================================
# DEMO EXECUTION
# =============================================================================

def print_army_structure():
    """Print the army hierarchy and optimization summary."""
    print("=" * 70)
    print("MULTI-AGENT ARMY: FULL OPTIMIZATION STACK")
    print("=" * 70)
    print(f"EPIC: {ARMY_CONFIG['epic']}")
    print()
    print("+-- ORCHESTRATOR (depth 0)")
    for tl in ARMY_CONFIG["team_leads"]:
        print(f"|   +-- {tl['name']} (depth 1) -- {tl['domain']}")
        print(f"|   |   Workdir: {tl['workdir']}")
        for w in tl["workers"]:
            # Show routing for each worker
            routing = route_task(w["task"], w["role"])
            print(f"|   |   +-- {w['id']} [{w['role']} | {routing.tier}]: {w['task']}")
    print("=" * 70)

def demo_setup():
    """Run the setup phase."""
    print("\n[SETUP] SETTING UP DEMO ENVIRONMENT")
    print("-" * 40)
    
    ensure_dirs()
    init_git_repo()
    create_worktrees()
    
    print(f"\n[OK] Project: {PROJECT_ROOT}")
    print(f"[OK] Worktrees: {WORKTREES_ROOT}")
    print(f"[OK] Tasks: {TASKS_ROOT}")
    
    # Initialize optimizations
    init_optimizations(OptimizationConfig(
        enable_model_routing=True,
        enable_context_compression=True,
        enable_thinking_caps=True,
        enforce_structured_output=True,
        enable_caching=True,
        track_costs=True,
    ))
    
    orch_task = spawn_orchestrator()
    write_task(TASKS_ROOT / "orchestrator" / "queue.jsonl", {
        "id": "orch-1",
        "type": "orchestrator",
        **orch_task
    })
    
    for tl in ARMY_CONFIG["team_leads"]:
        write_task(TASKS_ROOT / tl["id"] / "queue.jsonl", {
            "id": f"tl-{tl['id']}",
            "type": "team_lead",
            "team_lead": tl["id"],
            "role": "orchestrator",
            "goal": f"Lead {tl['domain']} implementation",
            "context": build_team_lead_context(tl)
        })
    
    print("\n[OK] Orchestrator & Team Lead tasks queued with optimization context")

def demo_optimization_features():
    """Demonstrate the new optimization features."""
    print("\n[TEST] DEMONSTRATING OPTIMIZATION FEATURES")
    print("-" * 50)
    
    opt_ctx = get_optimization_context()
    
    # 1. Model Routing Demo
    print("\n1. Dynamic Model Routing for each worker role:")
    test_tasks = [
        ("read_file config.yaml", "coder"),
        ("run pytest tests/", "tester"),
        ("implement JWT authentication", "coder"),
        ("security audit for SQL injection", "reviewer"),
    ]
    for task, role in test_tasks:
        routing = opt_ctx.route_model(task, role)
        budget = opt_ctx.get_thinking_budget(routing.tier, role)
        print(f"  Task: {task[:40]}... | Role: {role} -> Tier: {routing.tier} | Budget: {budget} tokens")
    
    # 2. Context Compression Demo
    print("\n2. Context Compression:")
    long_output = "Status: completed\nFiles changed: " + ", ".join([f"src/file{i}.py" for i in range(50)]) + "\n" + "Detail line\n" * 100
    compressed = opt_ctx.compress_output(long_output)
    print(f"  Original: {len(long_output)} chars -> Compressed: {len(compressed)} chars ({len(compressed)/len(long_output):.1%})")
    
    # 3. Tool Caching Demo
    print("\n3. Tool Caching:")
    cache = get_cache()
    cache.set("read_file", {"path": "test.py"}, "print('hello')")
    cached = cache.get("read_file", {"path": "test.py"})
    print(f"  Cache hit: {cached is not None}")
    print(f"  Cache stats: {cache.stats()}")
    
    # 4. Quality Gates Demo
    print("\n4. Quality Gate Engine:")
    gate_res = execute_quality_gates("coder", PROJECT_ROOT)
    print(f"  Status: {'PASSED' if gate_res['passed'] else 'FAILED (expected for empty demo dir)'}")
    
    # 5. HITL Trigger
    print("\n5. HITL Safety Gate:")
    check_hitl_trigger("merge_to_main", {"target": "main", "author": "orchestrator"})
    
    # 6. Optimization Stats
    print("\n6. Optimization Statistics:")
    stats = opt_ctx.get_stats()
    for k, v in stats.items():
        print(f"  {k}: {v}")

def main():
    print_army_structure()
    demo_setup()
    demo_optimization_features()
    
    print("\n" + "=" * 70)
    print("DEMO COMPLETE - FULL OPTIMIZATION STACK INTEGRATED!")
    print("=" * 70)
    print("""
Files created in skill directory:
  - model_router.py         # Dynamic model routing (LOCAL/CHEAP/STANDARD/PREMIUM)
  - context_compressor.py   # Output compression & sliding window
  - tool_cache.py           # Tool output caching (TTL, LRU)
  - optimization_integration.py  # Unified config & runtime context
  - orchestrator.md         # Updated with optimization section
  - leaf-workers.md         # Updated with cost optimization section
  - task-queue.md           # Updated with optimization integration
  - SKILL.md                # Hub doc with optimization summary
  - demo_army.py            # This file - demonstrates all features
""")

if __name__ == "__main__":
    main()