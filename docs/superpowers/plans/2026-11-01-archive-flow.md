# Archive Flow Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or executing-plans; preserve single file ownership.

**Goal:** Correct the audited data/authority defects, then implement the approved six-screen archive/output flow without losing existing functions.
**Architecture:** Keep Drift schema and repository transactions. Share fresh authorized assignment loading at report boundaries; keep report drafts distinct from roster formats. Present compact archive cards opening a dedicated detail route; explicit team selection and one short format sheet.
**Tech Stack:** Existing Flutter, Riverpod, Drift, GoRouter, printing, excel, share_plus. No new dependency or migration.
**Spec:** User-approved audit/design at C:/Users/baba/.codex/visualizations/2026/10/31/01a193fd-e085-7ed3-9eb1-4ea4060a8d4d/archive-flow-audit-20261101/AUDIT-AND-DESIGN.md and its two boards.

## Constraints and contracts
- Preserve all admin card actions, single assignment actions, team/person transfers, add-personnel/text/OCR, conflict and task-team confirmation.
- Keep activity names distinct from assignment duties; use historical team snapshot display.
- Report/roster reads require fresh session/current commander authority, explicit selected IDs, approved operational assignments. Reject stale source date/selection, do not widen scope on refresh.
- TEMGÜNDRAP opens an editable draft; remove its unreachable combined-preview branch; keep active report entries separate from roster format menu.
- Stage bulk quick-add/alias changes until confirmed save, actor check at writes, target imports use target date consistently; assignment/metadata errors cannot masquerade as no write.
- Preserve card/day order, ID deduplication, rank output, X >20 threshold through selected day, signer storage/readiness, five formats and three PDF styles.
- Shared repository tracked clean at base 6f8d1d6; isolated worktree F:/personelapp2-archive-flow, codex/archive-flow-redesign. No commit/push/APK distribution.

## Review focus
1. Authority/session changing while a sheet is open must not disclose another team's people.
2. Stream updates must prune stale selections and preserve cancel semantics.
3. Canceling import must not persist staged people/aliases; metadata failures cannot duplicate committed assignments.
4. 320px, large text, keyboard, Android back/share return, desktop reorder vs selection.
5. Same names/different IDs, previous-day boundary, 20/21 X, signer failures and repeat export remain correct.

### Task 1: Security/data regressions (Tier 3)
Files: activity repository query/assignment helpers; new scoped report loader; archive actions; activity_detail_assignments; temgundrap import; bulk_import_dialog/actions/save_handler and draft helpers; matching tests.
Interfaces: existing actor/repository contracts retained; scoped report service takes DB+current actor and explicit activity/assignment IDs, returns fresh scoped assignments/personnel.
- [x] Fresh independent security-boundary trace; reconcile policy and legitimate workflows.
- [x] Add negative tests for mixed-team/revoked/stale reports, actorless quick-add, import cancel and target date; observe RED.
- [x] Implement shared boundary fixes and atomic staged writes; preserve positive admin/commander imports.
- [x] Run focused security/data tests and syntax analysis.

### Task 2: Archive/detail/selection (Tier 2 with protected mutations)
Files: activity_archive_screen/actions, widgets/activity_summary_card, activity_detail_sheet, activity_assignment_groups, collapsible_squad_card, archive_date_navigator; new dedicated detail screen and compact UI widgets; edit_assignment_dialog; regression tests.
Interfaces: ActivityCard still supports existing constructor/tests; detail route streams current activity+assignments; optional onDateChanged preserved.
- [x] Add regressions for compact navigation, explicit select/all/cancel, date bounds/year, stale/cancel selection, actor recheck on delete.
- [x] Implement compact summary cards, dedicated activity detail, role-gated add/admin menus and explicit team selection toolbar.
- [x] Make selection/reorder mutually exclusive, date limits consistent, historical names explicit; fix desktop/mobile edit save/error locking.
- [x] Run archive/widget/authorization/date/copy/transfer tests.

### Task 3: Common formats and combined output (Tier 2)
Files: archive_export_sheet + small time/options widget; roster_output_screen/preview widgets; archive_actions master time forwarding; regression tests.
Interfaces: ArchiveExportResult stays type+optional timeRange; explicit TEM report entry retained where active; no new format enum or mandatory PDF renderer.
- [x] Add tests for compact five formats, collapsed optional time, accurate scope, existing preset/clear behavior.
- [x] Implement short list and separate report action; propagate time across every master format.
- [x] Preserve current/previous card explicit selection/order, X/rank/signers/readiness/retry and fresh row validation.
- [x] Run exporter/image/print/share/X/rank/signature tests.

### Task 4: Integration, independent review and device checks
- [x] Format changed Dart, analyze lib/test/integration_test, full flutter test.
- [x] Add meaningful full flow integration test using synthetic DB: archive->detail->selection->output/cancel; verify scope and retained data; run on safe test target if available.
- [x] Independent reviewer: security boundary and regression review of immutable hash manifest; confirm findings and fix.
- [x] Run final owning checks and inspect final diff/status; log commands, UTC, exit codes and hash manifest in task evidence.
- [x] Report real pass/fail/not-run, worktree/branch and remaining physical-device/printer limits.
