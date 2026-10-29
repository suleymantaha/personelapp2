# Daily detail: fixed summary and scrollable list

User approved the dark daily detail concept and chose vertical scrolling instead of pagination. Date/status, person/assignment cards and task/team tabs remain fixed; only the selected list scrolls. Excel work was explicitly canceled.

## Implementation

The modal has a bounded height and a fixed summary sibling above an Expanded ListView. Its ScrollController is owned/disposed by the sheet and resets on tab changes. Count cards keep clear person/assignment units. Narrow layouts use shorter labels and split count/unit lines without removing their full accessible labels. Duplicate child announcements are excluded from the KPI semantics.

The existing calculation model and source assignments were preserved. The preview and emulator test use synthetic data only, in a separate com.example.personelapp2.analyticsqa application. No existing application uninstall, data clear, or actual backup restore was performed.

## Verification

- RED regression: fixed header key and coordinate checks initially failed with previous scrolling KPI implementation.
- 4 dedicated sheet tests PASS, including 320px/2x text, last team heading visible after scrolling, unchanged header/KPI positions, tabs and close still reachable, empty/planned states, and one accessible count announcement.
- `flutter test --no-pub test/features/analytics --reporter compact`: 79 PASS, exit 0. Log output/monthly-fixed-focused.log.
- Scoped `dart analyze`: no issues. Log output/monthly-fixed-analyze.log.
- Independent source review clear after the KPI semantics fix.
- Android integration on verified nizam-nobet-test / emulator-5554: PASS, exit 0. Includes separate person/assignment totals, task/team tabs, list offset increases while header/KPI coordinates stay equal, close/reopen and matrix navigation. Log output/monthly-visual-qa/emulator-run.log.
- Real Android screenshots examined: monthly-detail-duties-android.png and monthly-detail-teams-scroll-android.png in output/monthly-visual-qa/emulator/. No overflow observed at actual 320x640 viewport.

The QA harness under output/monthly-visual-qa/harness uses directory junctions to actual lib/assets/integration_test/test_driver source directories and its own native build directory and package ID. Existing product package is distinct. The interactive preview target integration_test/monthly_visual_preview.dart opens the same sheet without the integration-test binding, so the emulator remains usable after the automated test resets its viewport.

Earlier Android harness failures were assertion/layout-coordinate issues: compact cards render number and unit on separate Text widgets, so tests now verify visible count and complete accessible labels within the sheet; ensureVisible centers the tap target away from the app bar. One disconnected emulator was reopened. These did not change production counts or bypass interactions.

No commit, push, product APK delivery, physical-device run or release. Gradle emitted existing Kotlin/plugin and SDK-tool compatibility warnings; the QA build completed successfully.

Interactive Android preview opened successfully; manually switched to Timler and scrolled only the body. Compared interactive-final.png with interactive-scrolled.png: date, counts, caption and tabs remain at the same coordinates. Files under output/monthly-visual-qa/emulator/.
