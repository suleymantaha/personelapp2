import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:personelapp2/features/watch_roster/presentation/watch_roster_screen.dart';
import 'watch_roster_test.dart' show entry;

void main() {
  testWidgets(
      'month navigation, explicit month selection and authorized personnel details',
      (tester) async {
    AnalyticsFilter? observed;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          teamAnalyticsProvider.overrideWith((ref, filter) {
            observed = filter;
            return Stream.value(TeamAnalytics(filter: filter, entries: [
              entry(1, 1, '2026-10-01'),
            ], unknownEntries: [
              entry(1, 2, '2026-10-01', team: null)
            ]));
          }),
        ],
        child: MaterialApp(
            home: WatchRosterScreen(initialMonth: DateTime(2026, 10)))));
    await tester.pumpAndSettle();
    expect(observed!.start, '2026-10-01');
    expect(observed!.end, '2026-10-31');
    await tester.tap(find.byKey(const ValueKey('watch-day-2026-10-01')));
    await tester.pumpAndSettle();
    expect(find.text('MEBS'), findsWidgets);
    expect(find.text('GARAJ'), findsWidgets);
    expect(find.text('TTZA'), findsWidgets);
    expect(find.text('NÖB. SB.'), findsWidgets);

    expect(find.text('Personel 1'), findsOneWidget);
    expect(find.text('Personel 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('watch-day-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('watch-next-month')));
    await tester.pumpAndSettle();
    expect(observed!.start, '2026-11-01');
    expect(observed!.end, '2026-11-30');
    expect(find.textContaining('Bu ay için'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('watch-previous-month')));
    await tester.pumpAndSettle();
    expect(observed!.start, '2026-10-01');
    expect(
        tester
            .widget<Semantics>(
                find.byKey(const ValueKey('watch-day-2026-10-01')))
            .properties
            .selected,
        isFalse);
    await tester.tap(find.byKey(const ValueKey('watch-select-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Önceki yıl'));
    await tester.tap(find.text('Seç'));
    await tester.pumpAndSettle();
    expect(observed!.start, '2025-10-01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and error retry remain usable', (tester) async {
    final controller = StreamController<TeamAnalytics>();
    var calls = 0;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          teamAnalyticsProvider.overrideWith((ref, filter) {
            calls++;
            return calls == 1
                ? controller.stream
                : Stream.value(TeamAnalytics(filter: filter, entries: []));
          }),
        ],
        child: MaterialApp(
            home: WatchRosterScreen(initialMonth: DateTime(2026, 2)))));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    controller.addError(StateError('test'));
    await tester.pumpAndSettle();
    expect(find.text('Nöbet kayıtları yüklenemedi.'), findsOneWidget);
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.textContaining('Bu ay için'), findsOneWidget);
    unawaited(controller.close());
  });
}
