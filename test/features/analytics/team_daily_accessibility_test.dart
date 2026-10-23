import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_screen.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('320px scaled screen and details $brightness', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final day = AnalyticsFilter(start: '2026-10-23', end: '2026-10-23');
      final entry = AnalyticsEntry(
          activityId: 1,
          activityName: 'Uzun Faaliyet Kartı',
          sourceDate: day.start,
          personnelId: 1,
          personnelName: 'Uzun Personel Adı',
          teamId: 1,
          teamName: '1-B Timi',
          duty: 'NÖBETÇİ HEYETİ',
          status: 'onaylandi',
          coveredDates: [day.start]);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            teamAnalyticsProvider.overrideWith((ref, filter) => Stream.value(
                TeamAnalytics(
                    filter: filter,
                    entries: [entry],
                    teams: {1: '1-B Timi'},
                    duplicateAssignments: 2,
                    possibleDuplicateActivities: 1))),
          ],
          child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: TeamAnalyticsScreen(initialFilter: day))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('1-B Timi'));
      await tester.pumpAndSettle();
      final duty = find.byKey(const ValueKey('report-duty-1-NÖBETÇİ HEYETİ'));
      await tester.ensureVisible(duty);
      await tester.tap(duty);
      await tester.pumpAndSettle();
      expect(find.text('Uzun Personel Adı'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.text('Uzun Personel Adı'))).pop();
      await tester.pumpAndSettle();
      final notice = find.byKey(const ValueKey('analytics-record-checks'));
      await tester.scrollUntilVisible(notice, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(notice);
      await tester.pumpAndSettle();
      expect(find.textContaining('2 tekrarlanan atama tekilleştirildi.'),
          findsOneWidget);
      expect(find.textContaining('1 olası mükerrer faaliyet ayrı tutuldu.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('analytics-settings')));
      await tester.pumpAndSettle();
      expect(find.text('Analiz ayarları'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Yenile'), 150,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('analytics-settings-close')));
      await tester.pumpAndSettle();
    });
  }
}
