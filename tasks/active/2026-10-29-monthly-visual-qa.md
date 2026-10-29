# Monthly visual QA and modern daily details

User authorized emulator and native Excel visual inspection, fixes for overflow/missing content, and modernization of daily chart bottom sheet.
Scope: primary emulator/Excel visual QA, daily unique-person model and integration tests; UI worker daily detail sheet and focused tests; review read-only. Preserve dirty unrelated and concurrent personnel-label work. No release/publication.
Safety: only AVD nizam-nobet-test, synthetic data in memory, no actual-user database restore or clearing. Existing installed package/signature checked before any install. Excel opened locally, no upload or sharing.
Design: draggable rounded daily sheet, date/status, separate person/assignment KPIs, task/team tabs, readable rows with long-name wrapping, explicit unknown/empty states.
Checks: targeted regressions, emulator evidence, native Excel summary/daily/duties/matrix/quality review, source and workbook validation.
Status: SUPERSEDED. User canceled further Excel visual checks and approved a revised scrollable daily detail design. Implementation and emulator acceptance completed under tasks/active/2026-10-29-monthly-fixed-header.md; do not treat interrupted Excel reopening as verified.
