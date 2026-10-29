# Personnel count clarity — 2026-10-29

User-approved follow-up to monthly analytics. UI and XLSX now separate current active personnel headcount (dated snapshot), unique personnel assigned within the selected period, and total assignments. One person's assignments are never presented as a full-team count. The legacy monthly view's participation numbers were removed from display; internal legacy metrics remain compatible.

## Semantics

- Repository headcount is active, non-demo personnel in the authorized current team scope AND selected team, independent of selected period, duty and assignment status. No actor/authority means unavailable, not zero. The snapshot date is separate from the selected month. No historical roster or utilization ratio is inferred.
- Monthly team and duty cells carry distinct personnel and assignment counts. A team's distinct total is the union of personnel IDs across duties, not their sum. Repeated assignment of one person remains one distinct person.
- Team scope comes from historical assignment snapshots. Missing historical teams are not filled from current membership. Explicit outside-team assignments retain the existing exclusion behavior introduced by the separate team-history work.
- Current headcount, period people and assignments share the immutable report consumed by both UI and XLSX. Unknown headcount exports as text; a known empty roster remains numeric zero.

## Evidence

Base main/ac3cf74; Flutter 3.47.2. Scope limited to analytics, its tests, read-only verification tool and task documents. Other existing navigation, activity and team-history changes preserved. No commit/push/release.

- RED: missing headcount/distinct-team contract; log output/personnel-count-red.log.
- Domain/repository GREEN: 26 tests. Tests exercise current roster independent of period/status/duty, inactive/demo exclusion, authority denial, selected-team authorization, nullable versus zero, and one person across three assignments and two duties.
- Full analytics GREEN: 62 tests, exit 0; output/personnel-count-focused.log. Includes 320px and large-text views, literal XLSX labels, editable chart refs/caches, empty reports, paired matrix columns, and outside-team behavior.
- Layout regression: renamed legacy trailing label initially overflowed by 2px at 320px. Diagnostic pinpointed team_monthly_duty_view.dart duty row; participation displays removed and replaced with person assignment totals. Final screen tests pass.
- `dart analyze lib test tool/verify_monthly_analytics.dart`: no issues, exit 0; output/personnel-count-analyze.log.
- Diff whitespace check: PASS.
- Independent source review clear after verification-tool outside-team parity correction. Snapshot 21 files at 2026-10-29T20:16:53Z, manifest SHA256 BE6F69838E5FD8F4C064CAEDF20A253C91FFD526F2FC50E250E8AC83C7EBD225.

## Real backup and independent workbook readback

Original 28 October backup path no longer existed. Reconciliation used the available newer full backup exported 2026-10-29 22:53 Europe/Istanbul, read-only (no restore). Four months PASS. Each exported workbook records the roster snapshot date; October: 185 current active personnel, 178 unique assigned personnel, 2407 assignments, 2305 known-team assignments, 102 unknown-team assignments. Future-date assignments are based on the backup export date for reproducibility.

Outputs (local, uncommitted): output/personnel-count-verification/reconciliation.json, four monthly_YYYY-MM.xlsx files, openpyxl-readback.json. Independent openpyxl verified all four workbook headcounts, unique people, assignments, daily and matrix assignment sums, per-duty people <= assignments, native chart sheet associations, and every numeric chart cache versus its referenced worksheet range.

Synthetic CLI fixture containing one explicit-outside, one unknown-team and one known-team assignment: PASS, 2 assignments, 1 unknown, 1 known; explicit outside excluded. Complements the application repository outside-team regression.

Synthetic dark-theme Flutter capture with loaded fonts: PASS; output/personnel-count-synthetic.png. Image uses synthetic data and is not a real-record screenshot.

Final `flutter test --reporter compact`: 860 passed, 1 skipped, exit 0 (45 seconds); output/personnel-count-full-tests.log. Physical device, native share dialog and Excel GUI checks were not run. No APK build/install.
