# Monthly analytics verification — 2026-10-29

## Scope and decisions

Approved monthly concept implemented in `Aylık Döküm` and the existing optional charts section. The UI and XLSX exporter consume the identical immutable `MonthlyAnalyticsReport` snapshot. Overall assignments include authorized unknown-team entries; the team matrix uses historical team snapshots only and includes authorized zero-record teams. Current personnel membership never supplies a missing historical team.

An assignment is unique by activity/person/historical team/normalized duty and belongs to its source activity date. Two-day coverage is not counted as another new assignment. HAZIRKITA spelling variants map to HAZIR KITA before coverage/filter/dedup; ambiguous custom names remain visible and flagged for review. Operational filters, assignment status and repository authorization remain enforced. Future source dates are planned, while past dates do not establish completion. Missing day records do not mean zero actual work.

## Reproducible checks

Cwd: `F:/personelapp2`; base: `ac3cf74b82d54a01a2a46e9babb4a04b1657b9e3`; Flutter 3.47.2. Final source hashes are recorded in local `output/monthly-analytics-verification/source-manifest.json`.

- Domain RED: missing report API; GREEN: initial 5 tests. Added zero-record team regression.
- Repository alias RED: two-day carryover/filter returned zero rows; GREEN after canonicalization.
- Chart RED: final month day outside viewport; GREEN after compact whole-month chart. Final tick collision 30/31 has an assertion.
- `flutter test test/features/analytics --reporter compact`: PASS, 54 tests; log `output/monthly-focused-final.log`.
- `dart analyze lib test tool/verify_monthly_analytics.dart`: PASS, no issues; log `output/monthly-scoped-analyze-final.log`.
- `git diff --check -- lib/features/analytics test/features/analytics`: PASS.
- Synthetic Flutter render with actual app dark theme and loaded fonts: PASS; local image `output/monthly-analytics-synthetic.png`. Capture harness preserved as `output/monthly_capture_test.dart.txt`; no real personnel fixture used.
- Independent source review: no open actionable findings after tick collision correction; 17-file review manifest SHA256 `EDD3EA4999BE17B6CC98F9CAC7D00BE2E974F363082B68B1F08CF55DE0B43005`, 2026-10-29T19:48:37Z.

## Read-only real-backup reconciliation

`dart run tool/verify_monthly_analytics.dart <local-backup.json> output/monthly-analytics-verification`

The local version-2 backup exported on 2026-10-28 was read without restoring or modifying any database. Independent source-date checks reconcile total, unique people, record days, known-team totals, daily sums, duty sums and matrix sums for all four months. Reference date is the backup export date in Europe/Istanbul for reproducible planned-date classification.

| Month | Assignments | People | Record days | Known-team assignments | Unknown-team assignments |
|---|---:|---:|---:|---:|---:|
| 2026-07 | 61 | 45 | 2 | 0 | 61 |
| 2026-08 | 1903 | 174 | 31 | 28 | 1875 |
| 2026-09 | 584 | 165 | 9 | 16 | 568 |
| 2026-10 | 2407 | 178 | 30 | 2305 | 102 |

Four real-data XLSX files were generated locally (not committed). Independent bundled openpyxl readback passed all four: summary = daily sum = assignment count; matrix sum = known-team assignments; charts appear only on Günlük (two recorded/planned series) and Görevler (one series). Native charts contain cell references and matching caches. Tests inspect XML relationships, content types, empty reports and formula-like labels as literal text. The base excel package's orphan drawing relationship was removed after external readback exposed a phantom summary chart.

## Limits

No physical-device E2E, Excel GUI rendering, APK build/install, commit, push or release. Native share dialog itself is not exercised by widget tests; export snapshot, busy guard, recovery and generated XLSX content are tested. Real-backup reconciliation bypasses repository loading; authorization is covered by repository tests and source review. Unrelated existing working-tree changes were preserved.

`flutter test --reporter compact`: PASS, 797 tests passed, 1 skipped, exit 0 (63 seconds). Log: `output/monthly-full-tests-final.log`. Earlier exploratory runs exposed the template relationship bug and a narrow-screen test tapping outside the viewport; both have final passing regressions.
