import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/watch_roster/domain/watch_roster.dart';
import 'package:personelapp2/features/watch_roster/presentation/watch_roster_days.dart';
import 'watch_roster_test.dart' show entry;

void main() {
  for (final month in [
    DateTime(2024, 2),
    DateTime(2026, 2),
    DateTime(2026, 11)
  ]) {
    testWidgets('all days and Monday-first alignment $month', (tester) async {
      final days = DateTime(month.year, month.month + 1, 0).day;
      final prefix = month.toIso8601String().substring(0, 7);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: WatchRosterDays(
        month: month,
        roster: WatchRoster(TeamAnalytics(
            filter: AnalyticsFilter(start: '$prefix-01', end: '$prefix-$days'),
            entries: [])),
      ))));
      for (var day = 1; day <= days; day++) {
        expect(
            find.byKey(ValueKey(
                'watch-day-$prefix-${day.toString().padLeft(2, '0')}')),
            findsOneWidget);
      }
      final first =
          tester.getCenter(find.byKey(ValueKey('watch-day-$prefix-01')));
      final weekday = tester.getCenter(find.text([
        'Pzt',
        'Sal',
        'Çar',
        'Per',
        'Cum',
        'Cmt',
        'Paz'
      ][month.weekday - 1]));
      expect(first.dx, closeTo(weekday.dx, 1));
      expect(
          find.byKey(ValueKey('watch-day-$prefix-${days + 1}')), findsNothing);
    });
  }
  testWidgets('single tap exposes personnel, unknown teams and empty cards',
      (tester) async {
    final month = DateTime(2026, 10);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WatchRosterDays(
      month: month,
      roster: WatchRoster(TeamAnalytics(
          filter: AnalyticsFilter(start: '2026-10-01', end: '2026-10-31'),
          entries: [entry(1, 1, '2026-10-01')],
          unknownEntries: [entry(1, 2, '2026-10-01', team: null)])),
    ))));
    await tester.tap(find.byKey(const ValueKey('watch-day-2026-10-01')));
    await tester.pumpAndSettle();
    expect(find.text('Personel 1'), findsOneWidget);
    expect(find.text('Personel 2'), findsOneWidget);
    expect(find.text('Timi bilinmiyor'), findsNWidgets(2));
    expect(find.byType(ExpansionTile), findsNothing);
    for (final duty in watchDuties.values) {
      expect(find.text(duty), findsOneWidget);
    }
    expect(find.text('Kayıt yok'), findsNWidgets(3));
    await tester.tap(find.byKey(const ValueKey('watch-day-close')));
    await tester.pumpAndSettle();
    final selected = tester
        .widget<Semantics>(find.byKey(const ValueKey('watch-day-2026-10-01')));
    expect(selected.properties.selected, isTrue);
    await tester.tap(find.byKey(const ValueKey('watch-day-2026-10-02')));
    await tester.pumpAndSettle();
    expect(find.text('Personel 1'), findsNothing);
    expect(find.text('Kayıt yok'), findsNWidgets(4));
  });
}
