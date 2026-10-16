import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_screen.dart';

void main() {
  for (final width in [320.0, 1280.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('analytics $width $brightness filters and drill down',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final initial = AnalyticsFilter(start: '2026-10-01', end: '2026-10-31');
        final entry = AnalyticsEntry(
            activityId: 7,
            activityName: 'Özel Faaliyet',
            sourceDate: '2026-10-02',
            personnelId: 1,
            personnelName: 'Test Personeli',
            teamId: 1,
            teamName: '1-B',
            duty: 'HEYBET',
            status: 'onaylandi',
            coveredDates: ['2026-10-02']);
        await tester.pumpWidget(ProviderScope(
            overrides: [
              teamAnalyticsProvider.overrideWith((ref, filter) => Stream.value(
                  TeamAnalytics(
                      filter: filter,
                      entries: filter.status == 'onaylandi' ? [entry] : [],
                      teams: {1: '1-B'},
                      availableDuties: ['HEYBET', 'NÖBETÇİ']))),
            ],
            child: MaterialApp(
                theme: ThemeData(brightness: brightness),
                home: TeamAnalyticsScreen(initialFilter: initial))));
        await tester.pumpAndSettle();
        expect(find.text('Tim Görev Analizi'), findsOneWidget);
        expect(find.text('Tim Katılımı'), findsOneWidget);
        expect(find.text('Görev Karşılaştırması'), findsOneWidget);
        expect(find.text('Aylık Trend'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Tim Aylık Görevleri sekmesi testi
        final tabMonthly = find.byKey(const ValueKey('tab-monthly'));
        await tester.ensureVisible(tabMonthly);
        await tester.tap(tabMonthly);
        await tester.pumpAndSettle();
        expect(find.text('Timler Arası Görev Denge Analizi'), findsOneWidget);
        expect(find.text('Aylık Tim Görev Dağılım Tablosu'), findsOneWidget);

        // A single person's duty remains one participation and one person-task.
        final dutyRow = find.byKey(const ValueKey('team-duty-1-HEYBET'));
        await tester.scrollUntilVisible(dutyRow, 180,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(dutyRow);
        await tester.pumpAndSettle();
        expect(find.text('Görevdeki Personel'), findsOneWidget);
        expect(find.text('Test Personeli'), findsOneWidget);
        expect(find.textContaining('1 kişi-görev'), findsWidgets);
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Personel Detayı sekmesine geçiş ve drill down
        final tabDetails = find.byKey(const ValueKey('tab-details'));
        await tester.ensureVisible(tabDetails);
        await tester.tap(tabDetails);
        await tester.pumpAndSettle();
        for (final key in [
          'analytics-team-1',
          'analytics-duty-1-HEYBET',
          'analytics-date-1-HEYBET-2026-10-02',
          'analytics-activity-1-HEYBET-2026-10-02-7'
        ]) {
          final tile = find.byKey(ValueKey(key));
          await tester.scrollUntilVisible(tile, 200,
              scrollable: find.byType(Scrollable).first);
          final header =
              find.descendant(of: tile, matching: find.byType(ListTile)).first;

          await tester.ensureVisible(header);
          await tester.pumpAndSettle();
          await tester.tap(header);
          await tester.pumpAndSettle();
        }
        expect(find.text('Test Personeli'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('analytics-status')), -250,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.byKey(const ValueKey('duty-null')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('HEYBET').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('duty-HEYBET')));
        await tester.pumpAndSettle();
        expect(find.text('NÖBETÇİ'), findsOneWidget);
        await tester.tap(find.text('NÖBETÇİ').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('analytics-status')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bekleyen').last);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
            find.text('Seçilen filtrelerde görev kaydı yok.'), 250,
            scrollable: find.byType(Scrollable).first);
        expect(
            find.text('Seçilen filtrelerde görev kaydı yok.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
