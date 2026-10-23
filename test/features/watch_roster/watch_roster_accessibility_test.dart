import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:personelapp2/features/watch_roster/presentation/watch_roster_screen.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('small screen large text month and personnel dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            teamAnalyticsProvider.overrideWith((ref, filter) =>
                Stream.value(TeamAnalytics(filter: filter, entries: [
                  AnalyticsEntry(
                      activityId: 1,
                      activityName: 'Örnek uzun nöbet heyeti adı',
                      sourceDate: '2026-10-01',
                      personnelId: 1,
                      personnelName: 'Örnek Uzun Personel Adı Soyadı',
                      teamId: 1,
                      teamName: 'Örnek Tim',
                      duty: 'MEBS NÖB.',
                      status: 'onaylandi',
                      coveredDates: ['2026-10-01', '2026-10-02'])
                ]))),
          ],
          child: MaterialApp(
              theme: dark ? AppTheme.darkMilitaryTheme : AppTheme.militaryTheme,
              home: WatchRosterScreen(initialMonth: DateTime(2026, 10)))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('watch-day-2026-10-01')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Örnek Uzun Personel Adı Soyadı'));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('NÖB. SB.'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('watch-day-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('watch-select-month')));
      await tester.pumpAndSettle();
      expect(find.text('Ay seç'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
