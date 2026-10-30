# Monthly day detail overflow — current revision verification

Date: 30 October 2026 (Europe/Istanbul). Task: investigate earlier general-suite
failure and ensure the current tests pass. Cwd: F:/personelapp2; branch main;
tested HEAD: 5bf4633f34d63ef625397572cfa3da37fb9b4760.

## Root cause and current fix

The prior log, docs/verification/meti-duty-all-pickers-tests.log, records a fixed
summary Column overflowing vertically by 431px at 320x900 with 2x text. The teams
tab was at y=1263, outside the 900px viewport. Header content left no usable room
for the Expanded list; this was a layout defect rather than evidence of a
test-order failure.

Current committed code already addresses this: monthly_day_detail_sheet.dart
uses compact date/header and team-tab labels for large text; the metrics widget
uses short labels and separate number/unit lines. Only the body list scrolls.
The existing regression retains 320x900/2x text and checks tab/close access,
scrolling to the last team, fixed header/KPI coordinates and no exceptions.

The old run finished at 2026-10-29T20:52:09Z. Relevant source/test modification
timestamps are later (sheet 20:52:32Z, metrics 20:54:45Z, test 20:57:23Z). More
decisively, the old log renders 'Timler (20)' where current 2x code renders
'Timler'. This supports a pre-fix run, not a demonstrated flaky current test.
The old run had no source hash, so its precise source bytes cannot be recovered
from that log alone. Existing correction is now in HEAD; no additional product
source changes were needed in this investigation.

## Fresh verification

Windows; Flutter 3.47.2, Dart 3.13.2. Logs/hashes under output/.

| Command | Result | Exit |
|---|---|---|
| flutter test --no-pub test/features/analytics/monthly_day_detail_test.dart --reporter expanded | 4 passed | 0 |
| flutter test --no-pub --reporter expanded | 887 passed, 1 skipped | 0 |
| dart analyze lib test | No issues found | 0 |
| flutter test --no-pub test/features/analytics --test-randomize-ordering-seed=20261030 --reporter expanded | 79 passed | 0 |
| git diff --check | clean | 0 |

Full log: output/monthly-overflow-current-full.log.
Analysis log: output/monthly-overflow-current-analyze.log.
Randomized log: output/monthly-overflow-randomized-analytics-recheck.log.
Tested analytics file hashes: output/monthly-overflow-current.sha256.
The skipped test is optional dashboard visual capture, gated by CAPTURE_DASHBOARD.

An attempted randomized run alongside the full suite did not start tests because
Flutter could not replace in-use build/native_assets/windows/sqlite3.dll.
Rerunning sequentially after the full suite resolved the tool conflict (79 PASS).
No process was killed and no shared build files were deleted manually.

Independent read-only review found no actionable issue in the current fix.
Reviewer did not rerun tests. Physical-device verification and APK build were not
performed in this task. No commit/push was made. An unrelated release task record
was modified elsewhere during verification and was preserved untouched.
