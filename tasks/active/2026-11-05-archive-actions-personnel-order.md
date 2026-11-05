# Archive actions and personnel order

## Task
- Tier 2: two bounded UI behaviors; no database/schema or authorization change.
- Authorization: user approved top actions and requested shared personnel ordering.
- Cwd: F:/personelapp2; branch fix/audit-hardening-apk-2026-11-01.
- Base: 7f2154e30cee549b2084f04497b7a465f8115a4b.
- Started UTC: 2026-11-05T20:42:55.977416+00:00.
- Existing untracked paths preserved: .playwright-cli/, .serena/, output/.
- Owner: primary agent; no shared source writers.
- Commit/push/APK/deployment: NOT_REQUESTED.

## Design and decisions
Use Faaliyet seç, Kartları birleştir, Sırala above archive cards. Remove normal-mode bottom bar; preserve selected-output bar. Existing mobile export menu becomes Günün çıktısını al. Flexible Row uses 3/4/2 width allocation and wraps labels inside buttons; 48px minimum targets remain available on narrow/enlarged text layouts. Existing output routes and team filters remain intact.

PersonnelPickerSheet currently re-sorts by rank/name and official team weight, ignoring persisted sortOrder. Reuse orderDisplayPersonnel and orderDisplaySquads; preserve order during grouping, searching and filtering. AddPersonnelToActivityDialog also orders its selected-person details via the shared helper.

## Implementation plan
- [x] Add regression tests and observe expected failures.
- [x] Move archive actions and preserve selected export/menu behavior.
- [x] Apply shared personnel/team ordering to picker, chips and continuation.
- [x] Format; run focused and full Flutter tests; analyze tracked source roots.
- [x] Review diff and independent review; record final hashes and results.

## Acceptance / evidence
Commands run from F:/personelapp2 on Windows; logs under output/2026-11-05-archive-actions/.
- TDD red: PASS (expected FAIL observed: persisted team order 178 vs114; normal bottom bar still present).
- Focused tests: PASS, 10 tests; layout/export rerun 13 PASS plus1 E2E PASS after updating desktop selector. Initial7 full-suite failures were old menu label/location expectations, all migrated without removing assertions.
- Full tests: PASS, 1035 passed / 1 skipped, exit0, 48s; final log below.
- Static analysis: PASS, flutter analyze --no-pub lib test integration_test tool; exit0; no issues. Final run7.3s. Scoped to actual project roots to exclude preexisting untracked output harness files.
- Device/APK: NOT_RUN, outside requested scope.
- Independent review: PASS, /root/review_archive (reviewer); initial and final deltas read-only, no actionable findings. Runtime results independently executed by primary, not reviewer.

## Recovery and scope
Revert only task-owned diff if needed. No user data written; tests use memory databases and synthetic personnel. Existing large source files receive small targeted edits; no unrelated split/refactor.

## Check details
- Cwd: F:/personelapp2, Windows host, Flutter3.47.2/Dart3.13.2.
- Final static analysis log: output/2026-11-05-archive-analyze-final.log.
- Full command: flutter test --no-pub --reporter expanded --timeout 2m.
- Final test log: output/2026-11-05-archive-full-final.log.
- Format: dart format --output=none --set-exit-if-changed (10 modified Dart files), exit0.
- git diff --check: PASS, exit0.
- One overlapping extra Flutter test invocation hit sqlite3.dll native asset lock; no filesystem deletion or permissions workaround used. Reran tests sequentially once full suite released the DLL.

## Final source/test SHA-256
Recorded UTC: 2026-11-05T20:48:58.366531+00:00

- lib/features/activity/presentation/activity_archive_screen.dart: `678b0d7bce043bd8f9c61f544f3b01b49a91621df835dd5dafb27022c48ef5d8`
- lib/features/activity/presentation/dialogs/add_personnel_dialog.dart: `88e55bf2c15d0ed910d824e9f339759ceb3cc0f40c6e7ab58ea5ff3bd2146467`
- lib/features/activity/presentation/widgets/personnel_picker_sheet.dart: `6ce9a2ede3bf631dbfcacd854565d1af0390bb6c1461fa39d38d427f581b9734`
- lib/features/activity/presentation/widgets/archive_action_bar.dart: `6340429ab12de6f150e62f5e38cacdbbe8c01507f9a555fd8cd557ba147918a4`
- test/features/activity/personnel_picker_saved_order_test.dart: `1d1a9c0b780e3b9aa63b2dbf3c759e1ac5d33f32dc9fa922a1b87ffc86cd341a`
- test/features/activity/archive_action_bar_test.dart: `98f9356368f9a47865c9b52b70447b279f15a88678e7f792a194297a537c2e00`
- test/features/activity/activity_archive_reorder_test.dart: `d7efe3922c3be6adc21c69c02a8a228c5615b65e74c26217779b5d8102bb83a3`
- test/features/activity/activity_archive_selection_test.dart: `98ac7af68b0d0b998001fbb08f293938b0a6cda4c574d2f683d41c0bf36f3a75`
- test/features/activity/approved_roster_export_test.dart: `6de2ac281404bfb8fa27881f07da4cc34692584ee6778683aa4f0258d7d77438`
- test/support/archive_flow_scenario.dart: `8dc8eca1434c75490df9ab5c60938a640c3f59afd1542523dab5cf162c84532b`

## Completion
- Status: DONE, 2026-11-05T20:49:10.765263+00:00 UTC.
- Source/test hashes above match final verification. Independent review clear.
- No database migration, dependency/version change, device install, APK, commit, push, merge or CI trigger.
- Device/physical visual acceptance: NOT_RUN; widget layout verified at320/360/390px and1x/1.5x text scale.
- Original unrelated untracked paths remain preserved.
