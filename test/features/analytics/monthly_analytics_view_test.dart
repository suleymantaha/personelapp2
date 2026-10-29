import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/domain/monthly_analytics_report.dart';
import 'package:personelapp2/features/analytics/presentation/monthly_analytics_view.dart';
import 'package:personelapp2/features/analytics/presentation/monthly_daily_chart.dart';

TeamAnalytics snapshot() => TeamAnalytics(
      filter: AnalyticsFilter(
          start: '2026-10-01',
          end: '2026-10-03',
          teamId: 1,
          duty: 'HEYBET',
          status: 'beklemede'),
      teams: {1: '1-B'},
      entries: [
        AnalyticsEntry(
            activityId: 1,
            activityName: 'Sentetik',
            sourceDate: '2026-10-02',
            personnelId: 1,
            personnelName: 'Örnek',
            teamId: 1,
            teamName: '1-B',
            duty: 'HEYBET',
            status: 'beklemede',
            coveredDates: ['2026-10-02'])
      ],
    );

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  testWidgets(
      'headcount is distinct from unique people and repeated assignments',
      (tester) async {
    final data = TeamAnalytics(
        filter: AnalyticsFilter(start: '2026-10-01', end: '2026-10-03'),
        teams: {1: '1-B'},
        currentHeadcount: 1234,
        headcountAsOf: DateTime(2026, 10, 29),
        entries: [
          for (var activity = 1; activity <= 3; activity++)
            AnalyticsEntry(
                activityId: activity,
                activityName: 'Sentetik',
                sourceDate: '2026-10-02',
                personnelId: 1,
                personnelName: 'Örnek',
                teamId: 1,
                teamName: '1-B',
                duty: activity == 3 ? 'HAZIR KITA' : 'HEYBET',
                status: 'onaylandi',
                coveredDates: ['2026-10-02'])
        ]);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MonthlyAnalyticsView(
                    data: data, asOf: DateTime(2026, 10, 29))))));
    expect(find.text('Personel mevcudu (güncel)'), findsOneWidget);
    expect(find.text('1.234 kişi'), findsOneWidget);
    expect(find.text('Görev alan farklı kişi'), findsOneWidget);
    expect(find.text('1 kişi'), findsOneWidget);
    expect(find.text('Toplam görevlendirme'), findsOneWidget);
    expect(find.text('3 atama'), findsOneWidget);
    expect(find.text('Bir kişinin atanması tam tim görevi anlamına gelmez.'),
        findsOneWidget);
    expect(find.text('1 kişi / 2 atama'), findsOneWidget);
    expect(find.text('1 kişi / 3 atama'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing current roster is unknown rather than zero',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MonthlyAnalyticsView(data: snapshot())))));
    expect(find.text('Bilinmiyor'), findsOneWidget);
    expect(find.textContaining('Güncel personel mevcudu bilinmiyor'),
        findsOneWidget);
  });

  testWidgets('whole month remains visible at mobile width', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final report = MonthlyAnalyticsReport(
        data: TeamAnalytics(
            filter: AnalyticsFilter(start: '2026-10-01', end: '2026-10-31'),
            entries: []),
        asOf: DateTime(2026, 10, 20));
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MonthlyDailyChart(report: report))));
    expect(find.byKey(const ValueKey('monthly-day-2026-10-31')).hitTestable(),
        findsOneWidget);
    expect(find.text('Gün seç'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('30'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('narrow large text dashboard and daily details do not overflow',
      (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: SingleChildScrollView(
                    child: MonthlyAnalyticsView(
                        data: snapshot(),
                        asOf: DateTime(2026, 10, 1),
                        onExport: (_) async {}))))));
    await tester.pumpAndSettle();
    expect(find.text('Personel mevcudu (güncel)'), findsOneWidget);
    expect(find.textContaining('Kayıt yok'), findsWidgets);
    await tester
        .ensureVisible(find.byKey(const ValueKey('monthly-day-2026-10-02')));
    await tester.tap(find.byKey(const ValueKey('monthly-day-2026-10-02')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('02.10.2026 · Planlanan'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('monthly-detail-duty-HEYBET')), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('HEYBET: 1 atama'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('monthly-detail-tab-teams')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('monthly-detail-team-1')), 150,
        scrollable: find.byType(Scrollable).last);
    expect(find.bySemanticsLabel('1-B: 1 farklı kişi · 1 görevlendirme'),
        findsOneWidget);
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'navigation preserves scope and export receives stable report with busy guard',
      (tester) async {
    AnalyticsFilter? selected;
    MonthlyAnalyticsReport? exported;
    final pending = Completer<void>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MonthlyAnalyticsView(
                    data: snapshot(),
                    asOf: DateTime(2026, 10, 1),
                    onFilterChanged: (value) => selected = value,
                    onExport: (report) {
                      exported = report;
                      return pending.future;
                    })))));
    await tester.tap(find.byTooltip('Sonraki ay'));
    expect(selected!.start, '2026-11-01');
    expect(selected!.teamId, 1);
    expect(selected!.duty, 'HEYBET');
    expect(selected!.status, 'beklemede');
    await tester.tap(find.byKey(const ValueKey('monthly-export')));
    await tester.pump();
    expect(exported!.assignmentCount, 1);
    expect(exported!.asOf, DateTime(2026, 10, 1));
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('monthly-export')))
            .onPressed,
        isNull);
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty multi-month range stays an honest selected period',
      (tester) async {
    final data = TeamAnalytics(
        filter: AnalyticsFilter(start: '2026-09-28', end: '2026-10-03'),
        entries: [],
        teams: {1: '1-B'});
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MonthlyAnalyticsView(
                    data: data, asOf: DateTime(2026, 10, 1))))));
    expect(find.text('Seçili dönem'), findsOneWidget);
    expect(find.text('Seçili dönem: 2026-09-28 — 2026-10-03 (6 gün)'),
        findsOneWidget);
    expect(
        find.text('Seçilen dönemde görev kaydı bulunamadı.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('export failure is visible and button recovers', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MonthlyAnalyticsView(
                    data: snapshot(),
                    onExport: (_) async => throw StateError('synthetic'))))));
    await tester.tap(find.byKey(const ValueKey('monthly-export')));
    await tester.pumpAndSettle();
    expect(
        find.text('Excel dışa aktarılamadı. Tekrar deneyin.'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('monthly-export')))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });
}
