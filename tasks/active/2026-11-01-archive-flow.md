# Archive flow correctness and redesign

| Field | Value |
|---|---|
| Task | 2026-11-01-archive-flow |
| Goal | Fix all actionable audit issues, preserve functions, implement approved archive/output design, regression + integration validation |
| Tier | 3: authority, historic assignment integrity, import writes |
| Mode | Native parent + bounded workers; single writer per file |
| Scope | Authorized local implementation/tests; no commit/push/release/deployment |
| Root/base | F:/personelapp2-archive-flow / 6f8d1d6dff8ca5fccdac11a764ddf1a942708352 |
| Branch | codex/archive-flow-redesign |
| Initial user changes | Original checkout untracked .playwright-cli/, .serena/, output/ preserved; new worktree excludes these |
| Status | DONE |
| Contract | Existing schema/actor APIs; explicit scoped fresh read, staged import, same five roster formats |
| Active agents | Max 3 total, no subdelegation; 30 tool operations/15min checkpoints |
| Coordinator | /root, sole task/ledger writer |
| Plan | docs/superpowers/plans/2026-11-01-archive-flow.md |

## Packages and ownership
- Security investigator: read only.
- Export worker (after investigation): scoped report helper, archive actions, activity_detail_assignments, TEM import and tests.
- Import worker (after investigation): bulk import/learning draft/write files and tests.
- Parent: archive/detail/cards/groups, export UI, edit dialog, task record, integration and test orchestration.
- Shared files and test fixture contracts coordinated before edits; no overlapping writers.

## Baseline
- Source unchanged since prior audit: 665 selected tests PASS, scoped analyze PASS; root analyze had 14 pre-existing output/ info messages.
- Fresh worktree setup generated plugin registrant rewrites; task-owned generated rewrites restored immediately.
- Native worktree attachment rejects F:/ source outside chat roots. Used git worktree fallback at verified new F:/personelapp2-archive-flow; original checkout untouched.

## Decisions
- User explicitly authorized execution of already approved design; proceed without another plan approval round.
- No schema changes, dependency upgrade or global behavior rewrite.
- Fresh report scope uses approved operational duties consistent with roster; report remains editable.
- Security defects fixed before exposing/reporting new UI; positive commander/admin controls required.

## Checks
| Check | Result |
|---|---|
| Focused RED/GREEN | PASS: report, staged import, authority, lifecycle, route and hours |
| Full unit/widget | PASS: 1013; 1 existing opt-in dashboard capture SKIP |
| Analyze | PASS: No issues found |
| Independent review | 63-file hash-verified candidate; 3 concrete findings reproduced/fixed; parent final acceptance |
| Safe Android integration | PASS: read-only nizam-nobet-test, emulator-5554, verified .qa APK, four screenshots |
| Physical printer/device | NOT_RUN |

## Recovery
All edits isolated to this worktree. No user production data used. Review task-owned diff; do not reset/clean original repository.
No irreversible action, commit, push, merge or distribution required.

## Final decisions and evidence
- Shared requireOutputAuthority is now used for report snapshots, combined reads, matrix reads and assignment deletion transactions.
- Report operationalActivities excludes foreign-only/pending-only source titles; fresh original sources still validate identity.
- Selection callbacks remain mounted on empty rows; whole-activity controls hide while team selection is active.
- Actual GoRouter history preservation regression PASS.
- Android first attempt exposed missing integration locale init and unpropagated QA env suffix; fixed and rebuilt with target-based suffix, aapt guard before final install. Read-only base release persisted unchanged.
- Final evidence: output/archive-flow-verification/; summary docs/qa/archive-flow-2026-11-01.md.
- Physical device/printer/iOS/web NOT_RUN. Android OS share endpoint mocked intentionally; no messages sent.
- No commit/push/merge/release. Original checkout user changes preserved.
- Model backend usage/cost metrics unavailable; no savings claims.
