import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/analytics_details.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_screen.dart';
import 'package:personelapp2/features/analytics/presentation/team_monthly_duty_view.dart';

void main() {
  final filter = AnalyticsFilter(start: '2026-10-01', end: '2026-10-31');
  const names = <int, String>{
    1: '10-B Timi',
    2: '1-B',
    3: 'K.H',
    4: "1'inci Bl. K.H",
    5: '2-B Timi',
    6: 'METİ Timi',
    7: "2'nci Bl. K.H",
    8: 'Özel Tim',
    9: 'Özel Tim',
    10: 'Nöbet Heyeti',
  };
  const expected = <int>[10, 3, 4, 2, 5, 7, 1, 6, 8, 9];

  AnalyticsEntry entry(int id) => AnalyticsEntry(
        activityId: id,
        activityName: 'Faaliyet $id',
        sourceDate: '2026-10-02',
        personnelId: id,
        personnelName: 'Personel $id',
        teamId: id,
        teamName: names[id]!,
        duty: 'HEYBET',
        status: 'onaylandi',
        coveredDates: const ['2026-10-02'],
      );

  TeamAnalytics data({bool includeEntries = true}) => TeamAnalytics(
        filter: filter,
        entries: includeEntries
            ? [for (final id in names.keys) entry(id)]
            : <AnalyticsEntry>[],
        teams: names,
      );

  test('official squad order wins over alphabetical and numeric ordering', () {
    final snapshot = data();
    expect(snapshot.orderedTeamIds, expected);
    expect(snapshot.orderedAvailableTeamIds, expected);
    expect(snapshot.orderedTeamIds, snapshot.orderedTeamIds);
    expect(snapshot.metrics.personnelTasks, names.length);
  });

  test('filter lists authorized teams even without activity records', () {
    final snapshot = data(includeEntries: false);
    expect(snapshot.orderedTeamIds, isEmpty);
    expect(snapshot.orderedAvailableTeamIds, expected);
  });

  test('missing and unknown team names sort last with stable ID fallback', () {
    final snapshot = TeamAnalytics(
      filter: filter,
      entries: <AnalyticsEntry>[],
      teams: const {15: 'Özel Tim', 11: 'K.H', 14: 'Özel Tim'},
    );
    expect(snapshot.orderedAvailableTeamIds, [11, 14, 15]);
    expect(snapshot.sortTeamIds([100, 21]), [21, 100]);
  });

  testWidgets('monthly duty cards follow the same military order',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TeamMonthlyDutyView(data: data()),
        ),
      ),
    ));
    final positions = [
      for (final id in expected)
        tester.getTopLeft(
          id == 9 ? find.text('Özel Tim').at(1) : find.text(names[id]!).first,
        ).dy,
    ];
    for (var i = 1; i < positions.length; i++) {
      expect(positions[i], greaterThan(positions[i - 1]),
          reason: '${names[expected[i]]} must follow ${names[expected[i - 1]]}');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('personnel details use official squad order', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AnalyticsDetails(data: data()),
        ),
      ),
    ));
    final tiles = tester.widgetList<ExpansionTile>(
      find.byType(ExpansionTile),
    ).toList();
    expect(
      tiles.map((t) => (t.key! as ValueKey<String>).value).toList(),
      [for (final id in expected) 'analytics-team-$id'],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('team filter offers all squads in official order',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        teamAnalyticsProvider.overrideWith(
          (ref, requested) => Stream.value(data()),
        ),
      ],
      child: MaterialApp(
        home: TeamAnalyticsScreen(initialFilter: filter),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analytics-filters-toggle')));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButton<int>>(
      find.descendant(
        of: find.byKey(const ValueKey('team-null')),
        matching: find.byType(DropdownButton<int>),
      ),
    );
    expect(dropdown.items!.map((e) => e.value).toList(),
        <int?>[null, ...expected]);
    expect(tester.takeException(), isNull);
  });
}
