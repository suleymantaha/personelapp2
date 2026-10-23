import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_screen.dart';
import 'package:personelapp2/features/watch_roster/presentation/watch_roster_screen.dart';

void main() {
  testWidgets('settings update dates and filters after asynchronous reload',
      (tester) async {
    final streams = <StreamController<TeamAnalytics>>[];
    AnalyticsFilter? latest;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          teamAnalyticsProvider.overrideWith((ref, filter) {
            latest = filter;
            final stream = StreamController<TeamAnalytics>();
            streams.add(stream);
            return stream.stream;
          }),
        ],
        child: MaterialApp(
            home: TeamAnalyticsScreen(
                initialFilter:
                    AnalyticsFilter(start: '2026-10-23', end: '2026-10-23')))));
    await tester.pump();
    streams.last
        .add(TeamAnalytics(filter: latest!, entries: [], teams: {1: '1-B'}));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('analytics-date')), findsNothing);
    expect(find.byTooltip('Yenile'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('analytics-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analytics-next-day')));
    await tester.pump();
    expect(latest!.start, '2026-10-24');
    expect(find.text('24.10.2026'), findsOneWidget);
    streams.last
        .add(TeamAnalytics(filter: latest!, entries: [], teams: {1: '1-B'}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team-null')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1-B').last);
    await tester.pump();
    expect(latest!.teamId, 1);
    expect(latest!.start, '2026-10-24');
    streams.last
        .add(TeamAnalytics(filter: latest!, entries: [], teams: {1: '1-B'}));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('team-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('analytics-settings-close')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('analytics-active-filters')), findsOneWidget);
    expect(find.byKey(const ValueKey('analytics-date')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    for (final stream in streams) {
      unawaited(stream.close());
    }
  });

  testWidgets('independent watch roster opens selected month from analytics',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          teamAnalyticsProvider.overrideWith((ref, filter) =>
              Stream.value(TeamAnalytics(filter: filter, entries: []))),
        ],
        child: MaterialApp(
            home: TeamAnalyticsScreen(
                initialFilter:
                    AnalyticsFilter(start: '2026-09-12', end: '2026-09-12')))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analytics-watch-roster')));
    await tester.pumpAndSettle();
    final screen =
        tester.widget<WatchRosterScreen>(find.byType(WatchRosterScreen));
    expect(screen.initialMonth, DateTime(2026, 9, 12));
    expect(find.text('Eylül 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
