# Safe task team history implementation plan

> Agentic workers: bounded parallel implementation with TDD, one final independent review. User explicitly authorized implementation; no additional plan approval needed.

**Goal:** Safe settings repair and prevention of missing/incorrect historical task teams.
**Architecture:** Shared conservative resolver; transactional repair service and audit; settings UI saves/reopens exact backup before apply; repository enforces dated snapshots.
**Tech Stack:** Existing Flutter, Drift, Riverpod, file gateway, shared_preferences.
**Spec:** ../specs/2026-10-29-safe-team-history-design.md

## Global constraints
Preserve user edits and real data. No new dependency, push, deployment or device writes. Worktree branch codex/safe-team-history from ac3cf74. Tests synthetic only. Existing main has unrelated concurrent work.

## Review focus
Same-day conflicting history; current-team fallback in imported past activities; stale preview after saving backup; backup serializer filtering existing data; rollback/audit consistency.

## Task 1: resolver + repair backend (worker)
- [x] Add failing resolver, service, authorization, backup validation, stale preview, rollback, idempotency tests.
- [x] Implement core/services/task_team_history.dart and task_team_repair*.dart. Shared interface: TaskTeamSnapshot(int? teamId, String teamName); TaskTeamHistory(db).resolve(int personnelId, String date) -> Future<TaskTeamSnapshot?>; returns null for unknown, explicit outside snapshot for verified removal.
- [x] TaskTeamRepairService(db, {AppBackupService? backupService}): prepare(UserSessionState actor) -> Future<TaskTeamRepairPreview>; apply({required preview, required String verifiedBackupJson, required UserSessionState actor}) -> Future<int>. Preview exposes backupJson, candidates (assignmentId, activityId, personnelId, date, teamId, teamName), unknownCount, outsideCount; immutable and provenance revalidated in service. UI uses actual actor per action.
- [x] Add durable audit with additive schema migration and optional backup field; remove restore automatic repair; protect migration backfill with shared resolver.
- [x] Run owned tests and report red/green.

## Task 2: settings repair UI (worker)
- [x] Add widget tests for admin-only, zero candidates, cancel/save failure, mismatched reopen, stale state and success.
- [x] Implement features/personnel/presentation/dialogs/task_team_repair_dialog.dart + small widgets. Inject backup/file gateway/service for tests. Preview lists IDs/date/proposed tim, unresolved preserved; save then reopen verify; explicit Apply; busy state blocks duplicate actions/dismissal. Add settings entry only for admin and invalidate affected providers.
- [x] Run widget tests after backend ready.

## Task 3: prevent recurrence (primary)
- [x] Add failing repository tests: backdated no history rejects atomically; dated past team used instead of current; explicit team/outside accepted; today's current snapshot remains stable; mismatched single-assignment supplied date cannot bypass; transfers across dates/date edits cannot keep stale snapshots; import doesn't pass current membership as explicit evidence.
- [x] Thread activity date through central assignment creation; extend input with explicit outside choice, use resolver on non-today dates, validate scope. Expose explicit selection in entry/import error recovery.
- [x] Preserve dated membership logs and avoid false baseline history; distinguish explicit Tim dışı in analytics notice if needed without touching concurrent analytics source.

## Task 4: integration and review (primary + read-only reviewer)
- [x] Format; run narrow tests, dart analyze, full flutter test; fix new regressions, record baseline failures separately.
- [x] Independent source/diff review with fixed file hashes; address actionable findings and rerun affected tests.
- [x] Save evidence, inspect diff/status, deliver patch and concise result. No automatic commit/push or Git merge. Local patch integration preserves pre-existing main edits.
