# Archive conveniences implementation plan

**Goal:** Add selected-team duty reassignment and copy-card-to-date shortcuts without changing assignment rules.
**Architecture:** Reuse updateExistingAssignmentDuties and existing add/create assignment operations. No schema or dependency changes.
**Tech Stack:** Flutter, Riverpod, Drift.
**Spec:** User-approved chat scope: move selected teams to another duty; copy exact card personnel/duties to chosen date, source unchanged; preserve existing rules.

## Constraints and review focus
- Preserve source assignments and current team/date/conflict/status rules.
- Verify selection uses saved task teams, not current roster; mobile toolbar must fit.
- Copy must preserve source notes/duties and handle cancellation, stale source, duplicates and month boundary.
- Validate matrix, archive, analytics and actual Excel workbook readback.

## Tasks
- [x] Add selected-team callback and preselected existing-duty dialog; widget regression tests.
- [x] Add copy repository operation composed from existing writes; transactional regression tests.
- [x] Connect admin card menu to date picker and existing task-team confirmation, result reporting.
- [x] Run focused tests, full flutter test, dart analyze, diff review and independent review.

User already authorized implementation; no additional approval checkpoint. No commit/push/release requested.
