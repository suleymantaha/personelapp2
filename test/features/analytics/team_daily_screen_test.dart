import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_filters.dart';
import 'package:personelapp2/features/analytics/presentation/team_duty_report_view.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_screen.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('analytics-settings')));
  await tester.pumpAndSettle();
}

Future<void> closeSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('analytics-settings-close')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('default period includes the first and last day of this month',
      (tester) async {
    AnalyticsFilter? observed;
    await tester.pumpWidget(ProviderScope(overrides: [
      teamAnalyticsProvider.overrideWith((ref, filter) {
        observed = filter;
        return Stream.value(TeamAnalytics(filter: filter, entries: []));
      }),
    ], child: const MaterialApp(home: TeamAnalyticsScreen())));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');
    expect(observed!.start, format.format(DateTime(now.year, now.month)));
    expect(observed!.end, format.format(DateTime(now.year, now.month + 1, 0)));
    expect(find.text('Tim Görev Raporu'), findsOneWidget);
  });

  testWidgets(
      'explicit day navigates dates and monthly returns to selected day',
      (tester) async {
    AnalyticsFilter? observed;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          teamAnalyticsProvider.overrideWith((ref, filter) {
            observed = filter;
            return Stream.value(TeamAnalytics(filter: filter, entries: []));
          }),
        ],
        child: MaterialApp(
            home: TeamAnalyticsScreen(
                initialFilter: AnalyticsFilter(
                    start: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    end: DateFormat('yyyy-MM-dd').format(DateTime.now()))))));
    await tester.pumpAndSettle();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    expect(observed!.start, today);
    expect(observed!.end, today);
    expect(find.text('Günlük Tim Görevleri'), findsOneWidget);
    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('analytics-previous-day')));
    await tester.pumpAndSettle();
    final previous = observed!.start;
    expect(analyticsDate(today).difference(analyticsDate(previous)).inDays, 1);
    await closeSettings(tester);
    await tester.tap(find.byKey(const ValueKey('tab-monthly')));
    await tester.pumpAndSettle();
    expect(observed!.start.endsWith('-01'), isTrue);
    expect(observed!.end, isNot(observed!.start));
    await tester.tap(find.byKey(const ValueKey('tab-overview')));
    await tester.pumpAndSettle();
    expect(observed!.start, previous);
    expect(observed!.end, previous);
    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('analytics-next-day')));
    await tester.pumpAndSettle();
    expect(observed!.start, today);
    await tester.tap(find.byKey(const ValueKey('analytics-previous-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analytics-today')));
    await tester.pumpAndSettle();
    expect(observed!.start, today);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly filters survive returning to the selected day',
      (tester) async {
    AnalyticsFilter? observed;
    final day = AnalyticsFilter(start: '2026-10-23', end: '2026-10-23');
    await tester.pumpWidget(ProviderScope(overrides: [
      teamAnalyticsProvider.overrideWith((ref, filter) {
        observed = filter;
        return Stream.value(TeamAnalytics(
            filter: filter,
            entries: [],
            teams: {1: '1-B Timi', 2: '2-B Timi'}));
      }),
    ], child: MaterialApp(home: TeamAnalyticsScreen(initialFilter: day))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-monthly')));
    await tester.pumpAndSettle();
    await openSettings(tester);
    tester
        .widget<TeamAnalyticsFilters>(find.byType(TeamAnalyticsFilters))
        .onChanged(AnalyticsFilter(
            start: observed!.start,
            end: observed!.end,
            teamId: 1,
            duty: 'HEYBET',
            status: 'beklemede'));
    await tester.pumpAndSettle();
    await closeSettings(tester);
    await tester.tap(find.byKey(const ValueKey('tab-overview')));
    await tester.pumpAndSettle();
    expect(observed!.start, day.start);
    expect(observed!.end, day.end);
    expect(observed!.teamId, 1);
    expect(observed!.duty, 'HEYBET');
    expect(observed!.status, 'beklemede');
  });

  testWidgets('excluded teams are not reported as having zero records',
      (tester) async {
    final data = TeamAnalytics(
        filter:
            AnalyticsFilter(start: '2026-10-23', end: '2026-10-23', teamId: 1),
        entries: [],
        teams: {1: '1-B Timi', 2: '2-B Timi'});
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body:
                SingleChildScrollView(child: TeamDutyReportView(data: data)))));
    await tester.tap(find.byKey(const ValueKey('report-inactive-teams')));
    await tester.pumpAndSettle();
    expect(find.text('1-B Timi'), findsOneWidget);
    expect(find.text('2-B Timi'), findsNothing);
  });

  testWidgets(
      'unknown historical teams remain inspectable without current-team inference',
      (tester) async {
    final day = AnalyticsFilter(start: '2026-10-23', end: '2026-10-23');
    final unknown = AnalyticsEntry(
        activityId: 1,
        activityName: 'Faaliyet',
        sourceDate: day.start,
        personnelId: 1,
        personnelName: 'Test Personeli',
        teamId: null,
        teamName: '',
        duty: 'HEYBET',
        status: 'onaylandi',
        coveredDates: [day.start]);
    await tester.pumpWidget(ProviderScope(overrides: [
      teamAnalyticsProvider.overrideWith((ref, filter) => Stream.value(
          TeamAnalytics(
              filter: filter, entries: [], unknownEntries: [unknown]))),
    ], child: MaterialApp(home: TeamAnalyticsScreen(initialFilter: day))));
    await tester.pumpAndSettle();
    final notice = find.byKey(const ValueKey('analytics-unknown-teams'));
    await tester.ensureVisible(notice);
    await tester.tap(notice);
    await tester.pumpAndSettle();
    expect(find.textContaining('Güncel tim bilgisi geçmişe uygulanmaz.'),
        findsOneWidget);
    expect(find.text('Test Personeli'), findsOneWidget);
    expect(find.textContaining('1 görev kaydı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
