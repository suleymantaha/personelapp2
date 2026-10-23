import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_duty_report_view.dart';

void main() {
  final period = AnalyticsFilter(start: '2026-10-01', end: '2026-10-31');

  AnalyticsEntry entry({
    required int activity,
    required int person,
    required String name,
    required int team,
    required String teamName,
    required String duty,
    String date = '2026-10-02',
    String activityName = 'Faaliyet Kartı',
    List<String> dates = const ['2026-10-02'],
  }) =>
      AnalyticsEntry(
        activityId: activity,
        activityName: activityName,
        sourceDate: date,
        personnelId: person,
        personnelName: name,
        teamId: team,
        teamName: teamName,
        duty: duty,
        status: 'onaylandi',
        coveredDates: dates,
      );

  TeamAnalytics report(Iterable<AnalyticsEntry> records) => TeamAnalytics(
        filter: period,
        entries: records,
        teams: const {3: '2-B Timi', 5: '1-B Timi', 8: '3-B Timi'},
      );

  testWidgets('team-first report shows distinct people and duty participation',
      (tester) async {
    final data = report([
      entry(
          activity: 10,
          person: 1,
          name: 'Ali',
          team: 5,
          teamName: '1-B Timi',
          duty: 'HAZIR KITA'),
      entry(
          activity: 10,
          person: 2,
          name: 'Veli',
          team: 5,
          teamName: '1-B Timi',
          duty: 'HAZIR KITA'),
      entry(
          activity: 10,
          person: 1,
          name: 'Ali',
          team: 5,
          teamName: '1-B Timi',
          duty: 'HAZIR KITA'),
      entry(
          activity: 11,
          person: 1,
          name: 'Ali',
          team: 5,
          teamName: '1-B Timi',
          duty: 'GÜLÜŞKÜR'),
      entry(
          activity: 12,
          person: 3,
          name: 'Ayşe',
          team: 3,
          teamName: '2-B Timi',
          duty: 'NÖBETÇİ HEYETİ'),
    ]);
    expect(data.metrics.participations, 3);
    expect(data.metrics.personnelTasks, 4);

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: TeamDutyReportView(data: data)),
      ),
    ));
    expect(find.text('Tim Görev Raporu'), findsOneWidget);
    final headerDetails = find.byKey(const ValueKey('report-team-details-5'));
    expect(headerDetails, findsOneWidget);
    expect(tester.getCenter(headerDetails).dx,
        greaterThan(tester.getCenter(find.text('1-B Timi')).dx));
    final expandIcon = find.descendant(
        of: find.byKey(const ValueKey('report-team-toggle-5')),
        matching: find.byIcon(Icons.expand_more));
    expect(tester.getCenter(expandIcon).dx,
        greaterThan(tester.getCenter(headerDetails).dx));
    await tester.tap(headerDetails);
    await tester.pumpAndSettle();
    expect(find.text('Ali'), findsWidgets);
    Navigator.of(tester.element(find.text('Ali').first)).pop();
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('report-duty-5-HAZIR KITA')), findsNothing);
    await tester.tap(find.text('1-B Timi'));
    await tester.pumpAndSettle();
    expect(find.textContaining(' gün'), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('report-duty-5-HAZIR KITA')),
            matching: find.text('1 görev')),
        findsOneWidget);
    final inactive = find.byKey(const ValueKey('report-inactive-teams'));
    expect(inactive, findsOneWidget);
    await tester.ensureVisible(inactive);
    await tester.tap(inactive);
    await tester.pumpAndSettle();
    expect(find.text('3-B Timi'), findsOneWidget);
    final one = tester.getTopLeft(find.byKey(const ValueKey('report-team-5')));
    final two = tester.getTopLeft(find.byKey(const ValueKey('report-team-3')));
    expect(one.dy, lessThan(two.dy));

    final duty = find.byKey(const ValueKey('report-duty-5-HAZIR KITA'));
    await tester.ensureVisible(duty);
    await tester.tap(duty);
    await tester.pumpAndSettle();
    expect(find.text('1-B Timi · HAZIR KITA'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('Veli'), findsOneWidget);
    expect(find.byKey(const ValueKey('report-activity-5-10-HAZIR KITA')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.text('1-B Timi · HAZIR KITA'))).pop();
    await tester.pumpAndSettle();
    final details = find.byKey(const ValueKey('report-team-details-5'));
    await tester.ensureVisible(details);
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('report-activity-5-11-GÜLÜŞKÜR')),
        findsOneWidget);
    Navigator.of(tester.element(find.text('Ali').first)).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1-B Timi'));
    await tester.tap(find.text('1-B Timi'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('report-duty-5-HAZIR KITA')), findsNothing);
  });

  testWidgets('identically named activities do not merge across source ids',
      (tester) async {
    final data = report([
      entry(
          activity: 10,
          person: 1,
          name: 'Ali',
          team: 5,
          teamName: '1-B Timi',
          duty: 'HEYBET'),
      entry(
          activity: 11,
          person: 2,
          name: 'Veli',
          team: 5,
          teamName: '1-B Timi',
          duty: 'HEYBET'),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: TeamDutyReportView(data: data)),
      ),
    ));
    await tester.tap(find.text('1-B Timi'));
    await tester.pumpAndSettle();
    final duty = find.byKey(const ValueKey('report-duty-5-HEYBET'));
    expect(find.descendant(of: duty, matching: find.text('2 görev')),
        findsOneWidget);
    await tester.ensureVisible(duty);
    await tester.tap(duty);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('report-activity-5-10-HEYBET')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('report-activity-5-11-HEYBET')),
        findsOneWidget);
    expect(data.forTeam(5).forDuty('HEYBET').metrics.participations, 2);
  });

  testWidgets('continued activity is shown without inventing new participation',
      (tester) async {
    final data = report([
      entry(
          activity: 14,
          person: 4,
          name: 'Deniz',
          team: 5,
          teamName: '1-B Timi',
          duty: 'HAZIR KITA',
          date: '2026-09-30',
          dates: const ['2026-10-01', '2026-10-02']),
    ]);
    final metrics = data.forTeam(5).metrics;
    expect(metrics.participations, 0);
    expect(metrics.personnelTasks, 0);
    expect(metrics.uniquePersonnel, 1);
    expect(metrics.dutyDays, 2);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: TeamDutyReportView(data: data)),
      ),
    ));
    await tester.tap(find.text('1-B Timi'));
    await tester.pumpAndSettle();
    final duty = find.byKey(const ValueKey('report-duty-5-HAZIR KITA'));
    expect(find.descendant(of: duty, matching: find.text('1 görev')),
        findsOneWidget);
    await tester.ensureVisible(duty);
    await tester.tap(duty);
    await tester.pumpAndSettle();
    expect(find.textContaining('Önceki günden devam'), findsOneWidget);
    expect(find.text('Deniz'), findsOneWidget);
    expect(find.textContaining('2 gün'), findsNothing);
    expect(find.textContaining('1 görev kaydı'), findsWidgets);
    expect(find.textContaining('2026-09-30'), findsOneWidget);
  });

  testWidgets('compact report has no overflow at narrow width and larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final data = report([
      entry(
          activity: 1,
          person: 1,
          name: 'Uzun Uzun Personel Adı',
          team: 5,
          teamName: '1-B Timi',
          duty: 'NÖBETÇİ HEYETİ'),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: SingleChildScrollView(
        child: TeamDutyReportView(data: data),
      )),
    ));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('1-B Timi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('report-duty-5-NÖBETÇİ HEYETİ')),
        findsOneWidget);
  });
}
