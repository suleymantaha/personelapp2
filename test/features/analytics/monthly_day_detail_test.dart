import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/features/analytics/domain/monthly_analytics_report.dart';
import 'package:personelapp2/features/analytics/presentation/monthly_day_detail_sheet.dart';

MonthlyAnalyticsDay sampleDay({bool empty = false}) => MonthlyAnalyticsDay(
    date: '2026-10-02',
    assignments: empty ? 0 : 3,
    uniquePersonnel: empty ? 0 : 1,
    isPlanned: true,
    duties: empty
        ? []
        : [
            const MonthlyDutyCount('HEYBET', 2),
            const MonthlyDutyCount(
                'ÇOK UZUN VE BİRDEN FAZLA SATIRDA GÖRÜNMESİ GEREKEN GÖREV ADI',
                1)
          ],
    teams: empty
        ? []
        : [
            MonthlyTeamRow(1, '1-B', {'HEYBET': 2}, uniquePersonnel: 1)
          ]);

Future<void> openSheet(WidgetTester tester, MonthlyAnalyticsDay day) async {
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                  onPressed: () => showMonthlyDayDetail(context, day),
                  child: const Text('Aç'))))));
  await tester.tap(find.text('Aç'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  testWidgets('day sheet separates unique people and assignments and can close',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await openSheet(tester, sampleDay());
    expect(find.byKey(const ValueKey('monthly-detail-sheet')), findsOneWidget);
    expect(find.text('Toplam görevlendirme'), findsOneWidget);
    expect(find.text('3 atama'), findsOneWidget);
    expect(find.text('Görev alan farklı kişi'), findsOneWidget);
    expect(find.text('1 kişi'), findsOneWidget);
    expect(find.bySemanticsLabel('Görev alan farklı kişi: 1 kişi'),
        findsOneWidget);
    expect(
        tester
            .getSemantics(
                find.bySemanticsLabel('Görev alan farklı kişi: 1 kişi'))
            .childrenCount,
        0);
    expect(find.text('Planlanan'), findsOneWidget);
    expect(
        find.textContaining('Tim bilgisi bulunmayan: 1 atama'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('monthly-detail-duty-HEYBET')), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('HEYBET: 2 atama'), findsOneWidget);
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('monthly-detail-sheet')), findsNothing);
    semantics.dispose();
  });

  testWidgets('sticky tabs switch between duty and team content',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await openSheet(tester, sampleDay());
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('monthly-detail-duty-HEYBET')), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('HEYBET: 2 atama'), findsOneWidget);
    expect(find.bySemanticsLabel('1-B: 1 farklı kişi · 2 görevlendirme'),
        findsNothing);
    await tester.tap(find.byKey(const ValueKey('monthly-detail-tab-teams')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('HEYBET: 2 atama'), findsNothing);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('monthly-detail-team-1')), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('1-B: 1 farklı kişi · 2 görevlendirme'),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('monthly-detail-tab-duties')).hitTestable(),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('monthly-detail-tab-duties')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('monthly-detail-duty-HEYBET')), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('HEYBET: 2 atama'), findsOneWidget);
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('empty future day says no records and never recorded',
      (tester) async {
    await openSheet(tester, sampleDay(empty: true));
    expect(find.text('Kayıt yok'), findsOneWidget);
    expect(find.text('Planlanan'), findsNothing);
    expect(find.text('Kayıtlı'), findsNothing);
    expect(find.text('0 atama'), findsOneWidget);
    expect(find.text('0 kişi'), findsOneWidget);
    expect(find.textContaining('Bu gün için görev kaydı bulunamadı'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320px large text long duties and many teams remain scrollable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day = MonthlyAnalyticsDay(
        date: '2026-10-02',
        assignments: 20,
        uniquePersonnel: 1,
        isPlanned: false,
        duties: sampleDay().duties,
        teams: [
          for (var id = 1; id <= 20; id++)
            MonthlyTeamRow(id, 'Uzun isimli sentetik tim $id', {'HEYBET': 1},
                uniquePersonnel: 1)
        ]);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showMonthlyDayDetail(context, day),
                    child: const Text('Aç'))))));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('monthly-detail-tab-teams')));
    await tester.pumpAndSettle();
    final fixedHeader =
        find.byKey(const ValueKey('monthly-detail-fixed-header'));
    final headerBefore = tester.getTopLeft(fixedHeader);
    final countBefore = tester.getTopLeft(
        find.byKey(const ValueKey('monthly-detail-assignment-count')));
    await tester.scrollUntilVisible(
        find.text('Uzun isimli sentetik tim 20'), 300,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('monthly-detail-sheet')),
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(
        find.text('Uzun isimli sentetik tim 20').hitTestable(), findsOneWidget);
    expect(
        find.byKey(const ValueKey('monthly-detail-tab-duties')).hitTestable(),
        findsOneWidget);
    expect(find.byTooltip('Kapat').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(fixedHeader), headerBefore);
    expect(
        tester.getTopLeft(
            find.byKey(const ValueKey('monthly-detail-assignment-count'))),
        countBefore);
    expect(
        find
            .byKey(const ValueKey('monthly-detail-assignment-count'))
            .hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
