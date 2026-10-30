# METİ matrix display correction — 30 October 2026

User correction: monthly personnel matrix must show X for METİ, not METİ text.
Duty identity remains METİ in stored assignments and details; coverage is one day.

Cwd: F:/personelapp2; branch main; base 5a83833b984fd36806295c1beccc73ae64198d5a.
No dependency/schema change. Existing unrelated untracked files preserved.

Removed the METİ display-code exception in MatrixDayCell and now use the shared
operational X path. Removed redundant METİ-specific matrix color/Excel branches.
Updated matrix repository and Excel regressions to require X generated from a
real METİ entry; verified stored duty remains METİ and no next-day continuation.
Existing X-day roster counting applies to METİ through its ordinary X cell.

Verification (Windows, Flutter 3.47.2 / Dart 3.13.2):

- RED: flutter test --no-pub test/unit/meti_matrix_test.dart test/features/matrix/meti_excel_test.dart --reporter expanded
  failed as expected: 4 X-vs-METİ failures, 1 passed, exit 1.
- Focused GREEN: flutter test --no-pub test/unit/meti_matrix_test.dart test/features/matrix/meti_excel_test.dart test/unit/matrix_repository_test.dart test/unit/roster_matrix_x_rule_test.dart test/unit/duty_coverage_test.dart test/unit/meti_duty_test.dart --reporter expanded
  passed 17, exit 0.
- flutter test --no-pub --reporter expanded: 887 passed, 1 optional visual test
  skipped, exit 0. Log output/meti-matrix-x-full-tests.log.
- dart analyze lib test: no issues, exit 0. Log output/meti-matrix-x-analyze.log.
- dart format on changed regression tests/domain: complete.
- git diff --check: exit 0 (Windows line-ending conversion notices only).
- Task source/test SHA-256 manifest: output/meti-matrix-x.sha256.

No commit, push, APK build or device installation performed.
