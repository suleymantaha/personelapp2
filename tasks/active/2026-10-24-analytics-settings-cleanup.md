# Analytics settings and watch roster location correction

- State DONE; Tier 2 UI change approved by user screenshot.
- Scope: NÖBET card inside Tim Görev Analizi, not dashboard. Date/today/range/filters/info/theme/refresh in top-right settings. Aligned duty rows; existing calculations and records unchanged.
- Base main cd89b6b00691c7cf0e7a9c4cabd1fabe5e8bd42b plus previous task dirty edits. Preserve all unrelated changes, sources read-only.
- Owners: coordinator dashboard/navigation/watch Android test/ledger; analytics_cleanup worker analytics UI/tests/daily Android test; independent reviewer after implementation. No shared writers.
- Device: dedicated existing nizam-nobet-test emulator-5560 only. User emulator-5554 forbidden for tests/install/data writes.
- Decisions: keep existing report tabs, read-only date/filter summary, independent monthly roster opens selected month, no DB/schema/model/repository changes.
- Red/green: dashboard absence regression failed before removal, 13 dashboard tests passed after removal.
- Worker: 36 existing analytics + 2 focused settings/navigation tests PASS. Parent small-screen test extended to scroll settings to refresh in dark/light; initial locator failed because offscreen ListView child not built, corrected to actual scrolling; targeted 2 PASS. No production fix needed.
- Analyze: `flutter analyze` PASS exit 0; build/analytics-cleanup-analyze-final.log.
- Android: both `flutter drive --driver=test_driver/daily_analytics_screenshots.dart --target=integration_test/daily_team_analytics_android_test.dart -d emulator-5560 --keep-app-running` and `flutter drive --driver=test_driver/watch_roster_screenshots.dart --target=integration_test/watch_roster_android_test.dart -d emulator-5560 --keep-app-running` PASS exit 0 (one behavior scenario each plus teardown). Synthetic memory DB unchanged. Logs build/analytics-cleanup-android.log and build/analytics-cleanup-watch-android.log.
- Visual inspection PASS: build/daily-analytics-evidence/daily-teams-dark.png and daily-settings-dark.png.
- Independent source review by verify PASS, no findings; parent compared hashes, exact match docs/verification/analytics-settings-cleanup.sha256. Review did not claim runtime tests.
- Existing dashboard and its menu test restored to pre-NÖBET content; no diff against HEAD. Domain/repository/database unchanged. providers.dart SHA256 still 2B854CE4BFBDC5A3DCEC3907BE5D9E579BB1FEF494FA64B1041A8B9419223B27.
- Final full suite `flutter test --reporter expanded`: 714 PASS, exit 0; build/analytics-cleanup-full-tests-final.log. Final verification UTC 2026-10-23T22:27Z, cwd F:/personelapp2, Flutter 3.47.2. git diff --check PASS.
- User emulator not accessed or installed; no live-data writes. New view available in source and dedicated emulator evidence only. Main branch, no commit/push.
- No commit/push/deployment authorized or performed.
