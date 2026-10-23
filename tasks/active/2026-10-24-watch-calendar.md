# Monthly watch calendar

- State DONE, Tier 2 UI-only approved change.
- User scope: NÖBET calendar with marked record days and date bottom sheet showing four duty categories/personnel. Preserve other screens, data, preferences. Dedicated emulator tests only.
- Base main cd89b6b00691c7cf0e7a9c4cabd1fabe5e8bd42b plus previous dirty edits; unrelated lib hashes captured build/watch-calendar-preserved-files.json.
- Owners: calendar_worker watch_roster presentation/tests; coordinator Android test/task/verification. Independent review after freeze.
- Design: Monday-first Turkish weekdays; complete real month including empty dates; source-date records only. Day details scroll, no second expansion needed. No provider/repository/domain/database changes or dependencies.
- Device: nizam-nobet-test emulator-5560 only, never emulator-5554 for testing. No installation to user emulator in this change.
- PASS: targeted tests 10, full `flutter test --reporter expanded` 718, exit 0; build/watch-calendar-full-tests.log. Covers leap/alignment, month reset, empty dates, unknown teams and 320px/1.3 light/dark.
- PASS: `flutter analyze`, zero issues exit 0; build/watch-calendar-analyze.log.
- PASS: `flutter drive --driver=test_driver/watch_roster_screenshots.dart --target=integration_test/watch_roster_android_test.dart -d emulator-5560 --keep-app-running`, exit 0, one scenario plus teardown; all synthetic DB tables unchanged. build/watch-calendar-android.log.
- PASS: visual inspection of build/watch-roster-evidence/watch-calendar-month.png and watch-calendar-personnel.png.
- PASS: independent source review by verify, no findings; hashes matched docs/verification/watch-calendar.sha256. Reviewer did not run runtime tests.
- PASS: baseline found zero changes outside watch_roster/presentation in lib; git diff --check. No user-emulator/data/preferences changes. UTC 2026-10-23T22:45Z, cwd F:/personelapp2, Flutter 3.47.2.
- Git: no commit/push requested.
