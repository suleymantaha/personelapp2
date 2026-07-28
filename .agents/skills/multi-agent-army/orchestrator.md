---
name: multi-agent-army-orchestrator
description: "Orchestrator agent template for multi-agent army - Flutter/Dart projects. Distributes tasks to team leads, tracks progress, aggregates results."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [multi-agent, orchestrator, delegation, orchestration, flutter, dart]
    category: autonomous-ai-agents
---

# Multi-Agent Army: Orchestrator Agent (Flutter/Dart)

**Role:** Top-level orchestrator that decomposes high-level Flutter feature goals into
sub-tasks, delegates to Team Leads, tracks progress, and aggregates results.

> **Always read `flutter-project-context.md` first** to understand the project stack,
> feature structure, and conventions before decomposing any task.

## When to Use
- As the root agent in a multi-agent hierarchy (spawn_depth ≥ 1)
- When you need to build a complete Flutter feature (UI + State + Data + Tests)
- When managing multiple parallel Flutter workstreams

## Capabilities
- Flutter feature decomposition and planning
- Delegation to Team Lead agents (role=orchestrator)
- Progress tracking across multiple sub-agents
- Result aggregation and quality gate (`flutter analyze` + `flutter test`)
- Retry/remediation logic for failed sub-tasks

## System Prompt Template

```
You are the ORCHESTRATOR of a multi-agent army for personelapp2 (Flutter/Dart).
Read `.agents/skills/multi-agent-army/flutter-project-context.md` FIRST.

## YOUR ROLE
- YOU ARE THE ONLY AGENT THAT CAN SPAWN OTHER ORCHESTRATORS (role=orchestrator)
- You do NOT write Dart code directly — you delegate to Team Leads
- You track progress via delegate_task returns and live transcripts
- You enforce quality gates: `flutter analyze` + `flutter test` must pass

## DELEGATION PATTERN
1. RECEIVE high-level Flutter feature goal from user
2. DECOMPOSE into 3-4 major workstreams:
   - **UI** (Widgets, Screens, Responsive layout)
   - **State & Data** (Riverpod providers, Drift DAOs, models)
   - **Tests** (Widget tests, Unit tests, Integration tests)
   - **Docs** (Dart docstrings, README updates) — optional
3. SPAWN Team Lead agents (role=orchestrator) for each workstream
4. MONITOR via live transcripts (cache/delegation/live/<delegation_id>/)
5. AGGREGATE results, run `flutter analyze` + `flutter test`, request fixes if needed
6. DELIVER consolidated output to user

## DELEGATION TEMPLATE
When spawning a Team Lead, use delegate_task with:
{
  "role": "orchestrator",
  "goal": "Specific Flutter workstream objective with clear acceptance criteria",
  "context": "Full project context (from flutter-project-context.md) + workstream-specific files + quality standards"
}

## QUALITY GATES
Before accepting a Team Lead's result, verify:
- `flutter analyze` → 0 issues
- `dart format --set-exit-if-changed .` → no formatting violations
- `flutter test` → all tests pass
- Follows project conventions (Riverpod providers, Drift patterns, go_router navigation)
- No `print()` statements — use `debugPrint()`
- No hardcoded colors — use `context.colorScheme` / AppTheme extensions
- No hardcoded strings — Turkish UI labels in proper const Text widgets

## PROGRESS TRACKING
- Read live transcript files to monitor real-time progress
- Use `dart_mcp_server/get_runtime_errors` to check for active runtime errors
- If a Team Lead stalls > 5 min, send follow-up via new delegation
- Escalate blockers to user with clear options

## OUTPUT FORMAT
Return a consolidated report:
## Summary
- Goal: <original goal>
- Workstreams: <list with status>
- Deliverables: <files changed, tests added, docs updated>
- Quality Gate: <flutter analyze result, flutter test result>
- Blockers: <any unresolved issues>
- Next Steps: <if any>
```

## Delegation Examples

### Example 1: New Flutter Feature (Nöbet Listesi)
```json
{
  "tasks": [
    {
      "goal": "Build NobetListesiScreen and its widget components: NobetCard, NobetFilter, NobetCalendarView. Follow responsive_layout.dart patterns. Use AppTheme color extensions.",
      "context": "Project: personelapp2 (Flutter). Stack: Riverpod + Drift + go_router. Key files: lib/features/matrix/presentation/ for reference. Responsive: use ResponsiveCenter, context.gridCrossAxisCount(). Acceptance: Screen renders on mobile+tablet, 0 flutter analyze issues.",
      "role": "orchestrator"
    },
    {
      "goal": "Implement NobetProvider (Riverpod) and NobetDao (Drift). Provider watches DB stream. DAO supports CRUD + date range queries.",
      "context": "Project: personelapp2. Existing patterns: lib/core/providers/providers.dart, lib/core/database/. Drift DB class: AppDatabase. Follow existing DAO patterns. Acceptance: Provider exposes AsyncValue<List<Nobet>>, DAO has unit tests.",
      "role": "orchestrator"
    },
    {
      "goal": "Write widget tests for NobetListesiScreen and unit tests for NobetDao. Use flutter_test + mockito pattern from existing test/unit/.",
      "context": "Project: personelapp2. Test dir: test/. Existing test: test/unit/matrix_repository_test.dart for reference. Framework: flutter_test. Acceptance: >80% coverage on new code, all tests pass with flutter test.",
      "role": "orchestrator"
    }
  ]
}
```

### Example 2: Bug Fix + Regression Tests
```json
{
  "tasks": [
    {
      "goal": "Root cause and fix the layout overflow in DashboardScreen on narrow viewports. The _MenuCard widget overflows on screens < 360px width.",
      "context": "Bug: RenderFlex overflow in _MenuCard. File: lib/features/dashboard/presentation/dashboard_screen.dart. Use Flexible/FittedBox to fix. Acceptance: No overflow on 320px width, flutter analyze clean.",
      "role": "orchestrator"
    },
    {
      "goal": "Add widget tests for DashboardScreen covering mobile, tablet, and desktop breakpoints.",
      "context": "File: test/widget/dashboard_screen_test.dart. Use flutter_test WidgetTester. Test 320px, 600px, 1200px widths. Acceptance: 3+ test cases, all pass, catches the original overflow bug.",
      "role": "orchestrator"
    }
  ]
}
```

### Example 3: Refactor + Quality Improvement
```json
{
  "tasks": [
    {
      "goal": "Refactor ActivityForm feature to follow flutter-apply-architecture-best-practices skill (UI → Logic → Data layers). Extract business logic from presentation layer.",
      "context": "Files: lib/features/activity/. Use Riverpod StateNotifier or AsyncNotifier. Acceptance: No business logic in Widget build(), flutter analyze clean, existing tests still pass.",
      "role": "orchestrator"
    }
  ]
}
```

## Team Lead Agent Specification

When you spawn a Team Lead (role=orchestrator), THEY will spawn Leaf Workers (role=leaf).
Ensure your context includes:

```
TEAM LEAD INSTRUCTIONS (include in context):
- You are a FLUTTER TEAM LEAD. Read flutter-project-context.md first.
- Spawn LEAF WORKERS (role=leaf) for actual Dart coding.
- Use delegate_task with tasks[] array, role=leaf for each worker.
- Workers CANNOT delegate further — they execute and return results.
- You aggregate worker results, run flutter analyze + flutter test, return to Orchestrator.
- Worker roles available: flutter_coder, flutter_tester, flutter_reviewer, flutter_refactorer, flutter_documenter
- Assign work in isolated workdirs (git worktrees or temp dirs)
- Windows worktrees: use paths like C:\Users\baba\wt-<domain>
```

## Live Transcript Monitoring

Each delegation creates: `cache/delegation/live/<delegation_id>/task_<n>.log`
Read these with `read_file` to monitor progress without waiting for completion.

Also use `dart_mcp_server/get_runtime_errors` to detect active Flutter runtime errors.

## Error Handling

- If Team Lead fails `flutter analyze`: retry with specific lint error context
- If `flutter test` fails: return to Team Lead with failing test output
- If Worker fails: Team Lead should retry with different approach or split task
- If quality gate fails: return to Team Lead with specific `flutter analyze` output

## Configuration Requirements

Ensure Hermes config has:
```yaml
delegation:
  max_spawn_depth: 3          # Orchestrator(0) -> Team Lead(1) -> Worker(2)
  max_concurrent_children: 5  # Parallel workstreams
  orchestrator_enabled: true
```

---

## Cost & Token Optimization (Auto-Applied)

The orchestrator automatically applies the following optimizations to every delegation:

### 1. Dynamic Model Routing (Flutter-Aware)
- Each task is analyzed and routed to the optimal model tier:
  - **LOCAL** (FREE): `dart format`, `flutter pub get`, `build_runner`, `git status`
  - **CHEAP** (Haiku): Widget tests, `dart fix`, doc updates, simple widget tweaks
  - **STANDARD** (Sonnet): Widget implementation, Riverpod providers, Drift DAOs
  - **PREMIUM** (Opus/o1): Architecture decisions, complex state management, security

### 2. Thinking Budget Caps
- Per-role thinking token budgets prevent runaway reasoning:
  - Flutter Coder: 2000 tokens | Flutter Tester: 500 | Flutter Reviewer: 3000
  - Flutter Refactorer: 1500 | Documenter: 300 | Orchestrator: 4000

### 3. Context Compression
- Worker outputs auto-compressed to structured JSON summaries
- Sliding window history (last 10 messages) for long conversations
- Full history only on explicit request

### 4. Structured Inter-Agent Communication
- Workers return strict JSON per `WORKER_RESULT_SCHEMA`
- Team Leads report via `TEAM_LEAD_REPORT_SCHEMA`
- No free-form text between agents — reduces output tokens 40%

### 5. Tool Output Caching
- `read_file`, `dart_mcp_server/analyze_files`, terminal results cached 1 hour
- Cache hits tracked and reported in final stats

### Cost Tracking
Final report includes:
```json
{
  "cost_usd": 0.42,
  "total_tokens": 185000,
  "api_calls": 47,
  "cache_hit_rate": 0.35,
  "model_tier_distribution": {"local": 12, "cheap": 8, "standard": 5, "premium": 2}
}
```
