---
name: multi-agent-army-task-queue
description: "Task queue and kanban system for multi-agent army - Flutter/Dart project. Hierarchical task distribution, progress tracking, work isolation."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [multi-agent, task-queue, kanban, orchestration, work-isolation, flutter, dart]
    category: autonomous-ai-agents
---

# Multi-Agent Army: Task Queue & Kanban System (Flutter/Dart)

## Overview

A lightweight task management system for hierarchical agent orchestration.
Uses file-based queues (JSONL) for persistence and live transcript monitoring for real-time progress.
Optimized for **personelapp2** (Flutter + Dart + Riverpod + Drift).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR (depth 0)                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Task Queue: tasks/orchestrator/queue.jsonl         │   │
│  │  In Progress: tasks/orchestrator/active.jsonl       │   │
│  │  Done: tasks/orchestrator/done.jsonl                │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│          ┌───────────────┼───────────────┐                 │
│          ▼               ▼               ▼                 │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐   │
│  │ TEAM LEAD UI  │ │ TEAM LEAD     │ │ TEAM LEAD     │   │
│  │ (depth 1)     │ │ STATE/DATA    │ │ TESTS         │   │
│  │               │ │ (depth 1)     │ │ (depth 1)     │   │
│  └───────┬───────┘ └───────┬───────┘ └───────┬───────┘   │
│          │                 │                 │             │
│    ┌─────┴─────┐     ┌─────┴─────┐     ┌─────┴─────┐     │
│    ▼           ▼     ▼           ▼     ▼           ▼     │
│  WORKER    WORKER  WORKER    WORKER  WORKER    WORKER     │
│ (Screen)  (Widget) (Provider) (DAO) (WidgetTest)(UnitTest)│
│  depth 2  depth 2  depth 2  depth 2  depth 2    depth 2  │
```

## Task Schema (Flutter-Aware)

```json
{
  "id": "task-<uuid>",
  "title": "Short descriptive title",
  "description": "Detailed specification with acceptance criteria",
  "role": "flutter_coder|flutter_tester|flutter_reviewer|flutter_refactorer|flutter_documenter",
  "priority": "critical|high|medium|low",
  "status": "pending|assigned|in_progress|review|done|blocked",
  "assignee": "worker-id-or-team-lead-id",
  "parent_task_id": "task-<uuid>|null",
  "workdir": "C:/Users/baba/wt-<domain>",
  "platform_targets": ["windows", "android", "ios", "web"],
  "dependencies": ["task-<uuid>"],
  "created_at": "ISO8601",
  "started_at": "ISO8601|null",
  "completed_at": "ISO8601|null",
  "result": {
    "summary": "...",
    "files_changed": ["lib/features/nobet/presentation/nobet_screen.dart"],
    "tests_added": ["test/widget/nobet_screen_test.dart"],
    "quality_gates": {
      "flutter_analyze": true,
      "dart_format": true,
      "flutter_test": true
    }
  },
  "metadata": {
    "estimated_hours": 2,
    "actual_hours": 1.5,
    "retry_count": 0,
    "quality_gate": "passed|failed|pending",
    "thinking_budget": 2000,
    "model_tier": "standard"
  }
}
```

## Queue Operations

### Initialize Flutter Project Task Structure
```powershell
# Run once per project (Windows PowerShell)
New-Item -ItemType Directory -Force -Path tasks\orchestrator
New-Item -ItemType Directory -Force -Path tasks\team-lead-ui
New-Item -ItemType Directory -Force -Path tasks\team-lead-state
New-Item -ItemType Directory -Force -Path tasks\team-lead-tests
```

### Enqueue Task (Orchestrator → Team Lead)
```python
import uuid
from datetime import datetime

# Orchestrator writes to team lead's queue
task = {
    "id": f"task-{uuid.uuid4()}",
    "title": "Implement NobetListesiScreen",
    "description": "Build scrollable list screen for duty assignments. Follow dashboard_screen.dart patterns. Use ResponsiveCenter. Acceptance: renders widget tree, 0 flutter analyze issues.",
    "role": "flutter_coder",
    "priority": "high",
    "status": "pending",
    "assignee": "team-lead-ui",
    "parent_task_id": None,
    "workdir": "C:/Users/baba/wt-ui",
    "platform_targets": ["windows", "android"],
    "dependencies": [],
    "created_at": datetime.utcnow().isoformat(),
    "started_at": None,
    "completed_at": None,
    "result": None,
    "metadata": {
        "estimated_hours": 2,
        "quality_gate": "pending",
        "thinking_budget": 2000,
        "model_tier": "standard"
    }
}
append_jsonl("tasks/team-lead-ui/queue.jsonl", task)
```

### Claim Task (Team Lead → Worker)
```python
# Team Lead reads queue, assigns to worker, moves to active
task = pop_from_queue("tasks/team-lead-ui/queue.jsonl")
task["status"] = "assigned"
task["assignee"] = "worker-screen-1"
task["started_at"] = datetime.utcnow().isoformat()
append_jsonl("tasks/team-lead-ui/active.jsonl", task)

# Spawn worker with delegate_task
delegate_task(tasks=[{
    "goal": task["description"],
    "context": build_flutter_worker_context(task),
    "role": "leaf"
}], workdir=task["workdir"])
```

### Complete Task (Worker → Team Lead → Orchestrator)
```python
# Worker returns result via delegate_task return value
# Team Lead updates task after quality gate verification
task["status"] = "done"
task["completed_at"] = datetime.utcnow().isoformat()
task["result"] = worker_result
task["metadata"]["quality_gate"] = "passed"  # after flutter analyze + flutter test
move_task("tasks/team-lead-ui/active.jsonl", "tasks/team-lead-ui/done.jsonl", task["id"])
```

## Kanban Board Visualization (Terminal)

```python
def render_flutter_kanban():
    columns = ["Backlog", "Ready", "In Progress", "Review", "Done", "Blocked"]
    for col in columns:
        tasks = query_tasks(status=col.lower().replace(" ", "_"))
        print(f"\n{col} ({len(tasks)})")
        for t in tasks[:5]:  # Show top 5
            role_icon = {
                "flutter_coder": "🎯",
                "flutter_tester": "🧪",
                "flutter_reviewer": "🔍",
                "flutter_refactorer": "♻️",
                "flutter_documenter": "📝",
            }.get(t.get("role", ""), "❓")
            platform = ",".join(t.get("platform_targets", ["?"]))
            print(
                f"  [{t['id'][:8]}] {role_icon} {t['title']} "
                f"@{t['assignee']} [{platform}] "
                f"⏱{t['metadata'].get('estimated_hours', '?')}h "
                f"[{t['metadata'].get('model_tier', '?')}]"
            )
        if len(tasks) > 5:
            print(f"  ... and {len(tasks)-5} more")
```

## Work Isolation Patterns (Windows Compatible)

### Pattern 1: Git Worktrees (Best for Git Repos — Windows)
```powershell
# Orchestrator/Team Lead sets up before delegation (Windows PowerShell)
cd C:\Users\baba\personelapp2

git worktree add C:\Users\baba\wt-ui main
git worktree add C:\Users\baba\wt-state main
git worktree add C:\Users\baba\wt-tests main

# Each worker gets unique workdir
delegate_task(tasks=[{
    "goal": "...",
    "workdir": "C:/Users/baba/wt-ui"  # Isolated!
}])
```

### Pattern 2: Temp Directories (Windows — Non-Git Scratch Work)
```powershell
$workdir = Join-Path $env:TEMP ("agent-worker-" + [System.Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $workdir
# Worker works in $workdir, returns results via JSON
```

### Pattern 3: Ephemeral Clones (CI/CD Style)
```powershell
$REPO_URL = "https://github.com/org/personelapp2.git"
$WORKDIR = Join-Path $env:TEMP "clone-$(Get-Random)"
git clone --depth 1 --branch main $REPO_URL $WORKDIR
# Worker works in $WORKDIR, pushes branch on completion
```

## Progress Monitoring (Real-Time)

### Live Transcript Tailing (Windows)
```powershell
# Each delegation creates: cache\delegation\live\<delegation_id>\task_<n>.log
Get-Content -Wait cache\delegation\live\abc123\task_1.log
```

### Dart MCP Server Monitoring
```
# Use dart_mcp_server/get_runtime_errors to detect active Flutter runtime errors
# Use dart_mcp_server/analyze_files to check analysis status without terminal
```

### Programmatic Monitoring
```python
import json, time
from pathlib import Path

def monitor_flutter_delegation(delegation_id, interval=5):
    log_dir = Path(f"cache/delegation/live/{delegation_id}")
    seen_lines = {}
    while True:
        for log_file in log_dir.glob("task_*.log"):
            content = log_file.read_text(encoding="utf-8", errors="replace")
            prev_count = seen_lines.get(str(log_file), 0)
            new_lines = content.splitlines()[prev_count:]
            if new_lines:
                print(f"=== {log_file.name} ===")
                for line in new_lines:
                    print(f"  {line}")
                seen_lines[str(log_file)] = prev_count + len(new_lines)
        time.sleep(interval)
```

## Quality Gates (Flutter/Dart — Automated)

```python
QUALITY_GATES = {
    "flutter_coder": [
        ("analyze", "flutter analyze"),
        ("format", "dart format --set-exit-if-changed ."),
        ("tests", "flutter test"),
        ("fix_check", "dart fix --dry-run"),
    ],
    "flutter_tester": [
        ("coverage", "flutter test --coverage"),
        ("widget_tests", "flutter test test/widget/"),
        ("unit_tests", "flutter test test/unit/"),
    ],
    "flutter_reviewer": [
        ("strict_analyze", "flutter analyze --fatal-warnings"),
    ],
    "flutter_refactorer": [
        ("tests_before", "flutter test"),           # Baseline
        # [apply refactoring here]
        ("tests_after", "flutter test"),            # Must match baseline
        ("analyze", "flutter analyze"),
        ("format", "dart format --set-exit-if-changed ."),
    ],
    "flutter_documenter": [
        ("doc_check", "dart doc --dry-run"),
        ("analyze", "flutter analyze"),
    ],
}

def run_flutter_quality_gate(role: str, workdir: str) -> tuple[bool, str]:
    """Run quality gates for a Flutter worker role."""
    import subprocess
    for name, cmd in QUALITY_GATES.get(role, []):
        result = subprocess.run(
            cmd.split(),
            cwd=workdir,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            return False, f"{name} failed:\n{result.stdout}\n{result.stderr}"
    return True, "All gates passed"
```

## Retry & Remediation Logic

```python
def handle_flutter_failure(task: dict, error: str, max_retries: int = 2) -> dict:
    task["metadata"]["retry_count"] = task["metadata"].get("retry_count", 0) + 1

    if task["metadata"]["retry_count"] <= max_retries:
        # Add specific Flutter error context
        flutter_hint = ""
        if "flutter analyze" in error:
            flutter_hint = "\n\nRUN: flutter analyze and fix ALL issues before marking done."
        elif "flutter test" in error:
            flutter_hint = "\n\nRUN: flutter test and fix ALL failing tests."
        elif "format" in error:
            flutter_hint = "\n\nRUN: dart format . to fix formatting."

        task["context"] = (
            task.get("context", "") +
            f"\n\nPREVIOUS ATTEMPT FAILED: {error}{flutter_hint}\nTRY DIFFERENT APPROACH."
        )
        task["status"] = "pending"
        requeue(task)
    else:
        task["status"] = "blocked"
        task["result"] = {"error": error, "requires_human": True}
        escalate_to_human(task)

    return task
```

## Example: Full Flutter Feature Flow (End-to-End)

```python
# 1. Orchestrator creates epic
epic = create_task(
    title="Nöbet Listesi Feature",
    description="Full duty roster: list screen, Riverpod provider, Drift DAO, widget tests",
    role="orchestrator",
    priority="high",
    platform_targets=["windows", "android"]
)

# 2. Orchestrator decomposes to Team Leads
decompose(epic, [
    {"title": "UI: NobetListesiScreen + NobetCard widget", "team": "team-lead-ui", "workdir": "C:/Users/baba/wt-ui"},
    {"title": "State/Data: NobetProvider (Riverpod) + NobetDao (Drift)", "team": "team-lead-state", "workdir": "C:/Users/baba/wt-state"},
    {"title": "Tests: Widget tests + Unit tests for Nobet feature", "team": "team-lead-tests", "workdir": "C:/Users/baba/wt-tests"},
])

# 3. Team Lead UI decomposes to Workers
decompose("UI: NobetListesiScreen", [
    {"role": "flutter_coder", "title": "NobetListesiScreen scaffold + routing", "workdir": "C:/Users/baba/wt-ui"},
    {"role": "flutter_coder", "title": "NobetCard reusable widget", "workdir": "C:/Users/baba/wt-ui"},
    {"role": "flutter_reviewer", "title": "Review: responsive layout + const constructors", "workdir": "C:/Users/baba/wt-ui"},
])

# 4. Team Lead State/Data decomposes
decompose("State/Data: NobetProvider + NobetDao", [
    {"role": "flutter_coder", "title": "NobetDao (Drift DAO): watchAll, insert, delete", "workdir": "C:/Users/baba/wt-state"},
    {"role": "flutter_coder", "title": "NobetProvider (AsyncNotifierProvider): watch DAO stream", "workdir": "C:/Users/baba/wt-state"},
])

# 5. Team Lead Tests decomposes
decompose("Tests", [
    {"role": "flutter_tester", "title": "Widget tests: NobetListesiScreen (empty, filled, filter)", "workdir": "C:/Users/baba/wt-tests"},
    {"role": "flutter_tester", "title": "Unit tests: NobetDao CRUD operations", "workdir": "C:/Users/baba/wt-tests"},
    {"role": "flutter_documenter", "title": "Dart docstrings for NobetDao public API", "workdir": "C:/Users/baba/wt-tests"},
])

# 6. Workers execute in parallel (max 5 concurrent)
# 7. Team Leads aggregate, run flutter analyze + flutter test
# 8. Orchestrator merges worktrees, runs full flutter test suite
# 9. Done!
```

## File Structure Summary

```
personelapp2\
├── tasks\
│   ├── orchestrator\
│   │   ├── queue.jsonl
│   │   ├── active.jsonl
│   │   └── done.jsonl
│   ├── team-lead-ui\
│   │   ├── queue.jsonl
│   │   ├── active.jsonl
│   │   └── done.jsonl
│   ├── team-lead-state\
│   │   ├── queue.jsonl
│   │   ├── active.jsonl
│   │   └── done.jsonl
│   └── team-lead-tests\
│       ├── queue.jsonl
│       ├── active.jsonl
│       └── done.jsonl
├── worktrees\          (created OUTSIDE project root on Windows)
│   (C:\Users\baba\wt-ui\)
│   (C:\Users\baba\wt-state\)
│   (C:\Users\baba\wt-tests\)
└── cache\delegation\live\  (auto-created by delegate_task)
    ├── <delegation_id>\
    │   ├── task_1.log
    │   ├── task_2.log
    │   └── ...
```

## Integration with Hermes delegate_task

The `delegate_task` tool already creates live transcripts. This system adds:
1. Persistent task queue (survives session restarts)
2. Hierarchical Flutter feature ownership (UI / State / Tests)
3. Work isolation via Windows-compatible workdirs
4. Flutter-specific quality gate automation
5. Visual kanban with Flutter role icons and platform targets

---

## Cost & Token Optimization (Auto-Applied)

### 1. Model Routing Per Flutter Task
Each queued task is analyzed by `model_router.route_task()` before delegation:
- **LOCAL** (FREE): `dart format`, `flutter pub get`, `build_runner`, `git`
- **CHEAP** (Haiku): `flutter test`, widget tests, doc updates
- **STANDARD** (Sonnet): Widget impl, Riverpod providers, Drift DAOs
- **PREMIUM** (Opus/o1): Architecture, complex state, security review

### 2. Thinking Budget Injection
```json
"metadata": {
  "thinking_budget": 2000,
  "model_tier": "standard",
  "quality_gate": "pending"
}
```

### 3. Context Compression
- Task descriptions auto-compressed if > 2000 chars
- `active.jsonl` stores compressed summaries, not full Dart file contents
- Full context preserved in live transcripts

### 4. Structured Queue Communication
Task results stored as strict JSON per `WORKER_RESULT_SCHEMA` — no free text.

### 5. Cache-Aware Queue Operations
- `read_file` / `dart_mcp_server/analyze_files` in queue ops use `cached_tool_call()`
- Cache hits reduce redundant analysis calls during monitoring

### 6. Cost Tracking in Task Metadata
```json
"metadata": {
  "estimated_cost_usd": 0.03,
  "actual_cost_usd": 0.025,
  "model_tier": "standard",
  "tokens_used": 12000,
  "cache_hits": 3
}
```

### Cost Summary in Kanban
```
Backlog (3)
  [task-a1] 🎯 NobetListesiScreen @ui-lead [windows,android] ⏱2h [$0.02] [standard]
  [task-a2] 🧪 Widget tests for Nobet @tests-lead [windows] ⏱1h [$0.01] [cheap]
  ...
Done (8)
  Total estimated: $0.28 | Actual: $0.22 | Cache hit: 32%
```