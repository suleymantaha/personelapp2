# Monthly default and collapsed team cards

- DONE; Tier 2 UI behavior; user approved current calendar month default and closed team cards in Tim Görev Analizi.
- Preserve explicit initialFilter, daily selection via settings, monthly/daily tab behavior and existing details/calculations. No database/preferences changes.
- Worker monthly_collapsed owns analytics screen/report presentation + analytics tests/daily integration. Parent owns ledger/verification. Independent review after freeze.
- Current main plus preexisting uncommitted edits preserved; no commit/push.
- Tests only on dedicated nizam-nobet-test emulator-5560, never baba emulator-5554. No user emulator installation requested this turn.
- PASS: `flutter test --reporter expanded` 719, exit 0, build/monthly-collapsed-full-tests.log. Targeted analytics 39 and report details 4 also passed.
- PASS: `flutter analyze` zero issues, exit 0, build/monthly-collapsed-analyze.log.
- PASS: `flutter drive --driver=test_driver/daily_analytics_screenshots.dart --target=integration_test/daily_team_analytics_android_test.dart -d emulator-5560 --keep-app-running`, exit 0, one scenario + teardown, synthetic DB unchanged. build/monthly-collapsed-android.log. Explicit daily fixture used; current-month default covered by widget test.
- Visually checked build/daily-analytics-evidence/teams-collapsed.png. Independent source review by verify PASS, two production hashes match docs/verification/monthly-collapsed-teams.sha256.
- Protected DB/provider/domain/repository/calendar files unchanged; git diff --check PASS. UTC verification 2026-10-23T22:54Z, F:/personelapp2, Flutter 3.47.2.
