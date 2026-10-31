# Archive conveniences

- Tier 2: new shortcuts composing existing repository rules; no schema or policy changes.
- State: DONE. Coordinator: root. Base: e40f083cdb6c1d049ee70b5c8900bbbe5cabe760.
- Branch: feat/special-duty-diger-column-merge.
- Preserved pre-existing untracked paths: .playwright-cli/, .serena/, output/.
- Ownership: root UI/docs; copy_backend copy repository + tests; ui_regression new widget tests.
- Scope: selected team duty changes, entire card copy to date; existing rules unchanged.
- Authorization: user explicitly requested implementation and matrix/archive/analytics/Excel tests. No commit/push/release.
- Verification: PASS as recorded below. Physical device: NOT_RUN.
- Ruling: stay on current clean tracked working tree, preserve existing untracked outputs; no unrelated branch integration.

## Verification evidence

Final check UTC: 2026-10-31T21:42:13.060130+00:00

| Command (F:/personelapp2) | Result | Exit |
|---|---|---|
| flutter test --no-pub --reporter expanded | PASS: 960 passed, 1 skipped | 0 |
| flutter test --no-pub test/features/activity/archive_convenience_flow_test.dart test/features/activity/activity_copy_preservation_test.dart | PASS: 3 additional tests | 0 |
| dart analyze lib test (after final tests added) | PASS: No issues found | 0 |
| dart analyze | 14 info-only avoid_print findings, all in pre-existing untracked output/; no app/test issues | 0 |
| dart format --output=none --set-exit-if-changed (9 new Dart files) | PASS: 0 changed | 0 |
| git diff --check | PASS | 0 |

Full suite finished before final 3 test cases were added; production files unchanged afterwards. Additional tests run separately. Narrow initial flow test attempt during full run hit sqlite3.dll file lock; rerun after suite completion passed, no file deletion or process termination used.

Logs: %TEMP%/personelapp2-archive-conveniences-tests.log and %TEMP%/personelapp2-archive-conveniences-analyze.log.

Independent review: reviewer agent, read-only, no P1/P2 issues; follow-up reviewed actual toolbar-save flow, target preservation and live matrix emission tests. Production hashes match reviewed artifact. Matrix and analytics Excel bytes decoded/read back in tests. Existing archive/export tests included in full suite.

NOT_RUN: physical-device validation, Excel GUI, APK/build/release. No real personnel data changed. No commit, push, merge or deployment. Existing .playwright-cli/, .serena/, output/ untouched.

## Final artifact SHA-256

- de4c45307fed986387f01f7fd16ac2c801277fdb88b4bd70c2d923094b868c84  lib/features/activity/data/activity_repository.dart
- 52010c8dd99626bde2cf6c7ad1bb74c6f0372419b484ded9af3d1dcd272a9f79  lib/features/activity/presentation/dialogs/reassign_existing_personnel_dialog.dart
- 2563bbd1690ff36e20446ad63a3681b00ff196160656413a061b2b996ddafa03  lib/features/activity/presentation/widgets/activity_assignment_groups.dart
- 9f6d33d1d586e5ac8fce8beb54eca2b45a578884927c108d4f06a0d052029427  lib/features/activity/presentation/widgets/activity_detail_assignments.dart
- 8061728a6cf8868e85044a9a6da04a32c4a9f8ff42d471f1e7b48d9322175f38  lib/features/activity/presentation/widgets/activity_summary_card.dart
- fc366f15c25558861a8302ece0e389c68d6ad0cd69439c6d1adbc6836011a5cc  lib/features/activity/data/activity_repository_copy.dart
- 6e3010abb4d306ae4cc6fdd5e5428e154a087e2a9d667f95926ae61731e3e749  lib/features/activity/presentation/widgets/activity_copy_action.dart
- b718e98d668c5feca76ee8ff5c7528f2ca205e130de18f15eda172234102932d  test/features/activity/archive_convenience_flow_test.dart
- fc4cbdacbc2d92ecc2776666d82fae87257fa29853d8f7a4e346f3a73c73a39e  test/features/activity/archive_convenience_widget_test.dart
- 6ecdfdb640429c55c7d58d3d9f56776c2bbed245a11a25230e23847cf3d6803b  test/features/activity/activity_copy_consumers_test.dart
- 6c7437df2d3f66b6bc241fc92940181f2efa3516abf5ea2108484ff6d929680a  test/features/activity/activity_copy_preservation_test.dart
- adb45b0c708864bf564e9f2998bbe493936966d5a59a572fa3b693f06903cd6f  test/features/activity/activity_copy_test.dart
- 7eb3a586c03ac0af3fe4565543a6332667ff420b31f0e6621ba037705e4bbce5  test/features/activity/archive_copy_action_widget_test.dart
- f0baa8bb3ae82c36f5f57474e62f1da4ac1e14d982aa43ea951dbffda4f3ce63  test/features/activity/archive_reassign_reporting_test.dart
