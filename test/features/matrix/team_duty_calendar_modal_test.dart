import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';
import 'package:personelapp2/features/matrix/presentation/widgets/team_duty_calendar_modal.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  const personnelNames = ['Ali CENGİZ', 'Mehmet BİLEK'];
  const summary = TeamDutySummaryDto(
    timId: 1,
    timAdi: '1-B Timi',
    toplamGorevGunSayisi: 1,
    toplamGorevSaati: 24,
    aktifPersonelSayisi: 14,
    ortalamaYukYuzdesi: 0,
    gorevTuruDagilimi: {'HEYBET': 1},
    yukHesabiTam: false,
    bilinmeyenTimAtamaSayisi: 125,
  );

  const day = TeamDayDutyDto(
    tarih: '2026-10-08',
    gunIndex: 8,
    gorevKodu: 'HEY',
    gorevTamAdi: 'HEYBET',
    gorevliPersonelAdlari: personnelNames,
    gorevGruplari: [
      TeamDutyGroupDto(
        gorev: 'HEYBET',
        durum: 'onaylandi',
        personelIds: [11, 12],
        personelAdlari: personnelNames,
      ),
    ],
  );

  const calendar = TeamMonthlyCalendarDto(
    timId: 1,
    timAdi: '1-B Timi',
    yil: 2026,
    ay: 10,
    gunler: [day],
    ozet: summary,
  );

  Future<void> showCalendar(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => TeamDutyCalendarModal.show(
                  context,
                  calendarData: calendar,
                ),
                child: const Text('Takvimi aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Takvimi aç'));
    await tester.pumpAndSettle();
  }

  testWidgets('October calendar aligns day 1 to Thursday', (tester) async {
    await showCalendar(tester, const Size(390, 850));

    final grid = find.byKey(const ValueKey('team-monthly-calendar-grid'));
    expect(grid, findsOneWidget);
    final day1 = find.byKey(const ValueKey('team-calendar-day-1'));
    final day8 = find.byKey(const ValueKey('team-calendar-day-8'));
    expect(day1, findsOneWidget);
    expect(day8, findsOneWidget);
    final thursday = find.text('Per').first;
    final distance =
        (tester.getCenter(day1).dx - tester.getCenter(thursday).dx).abs();
    expect(distance, lessThan(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('day details open separately with names and close', (tester) async {
    await showCalendar(tester, const Size(390, 850));
    await tester.tap(find.byKey(const ValueKey('team-calendar-day-8')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('team-day-detail-sheet')), findsOneWidget);
    expect(find.text('Ali CENGİZ'), findsOneWidget);
    expect(find.text('Mehmet BİLEK'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('team-day-detail-sheet')), findsNothing);
    expect(find.byKey(const ValueKey('team-calendar-day-8')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('days keep a visible painted surface in the dark or light theme', (tester) async {
    await showCalendar(tester, const Size(390, 850));
    final tile = find.byKey(const ValueKey('team-calendar-tile-8'));
    expect(tile, findsOneWidget);
    final material = tester.widget<Material>(tile);
    expect(material.color, isNotNull);
    expect(material.color, isNot(Colors.transparent));
    expect(material.shape, isA<RoundedRectangleBorder>());
  });

  testWidgets('multiple groups show a truthful count rather than the first duty', (tester) async {
    const mixedDay = TeamDayDutyDto(
      tarih: '2026-10-08',
      gunIndex: 8,
      gorevKodu: '2 grup',
      gorevTamAdi: '2 görev / durum',
      gorevliPersonelAdlari: ['Ali CENGİZ', 'Mehmet BİLEK'],
      gorevGruplari: [
        TeamDutyGroupDto(
          gorev: 'HEYBET',
          durum: 'onaylandi',
          personelIds: [11],
          personelAdlari: ['Ali CENGİZ'],
        ),
        TeamDutyGroupDto(
          gorev: 'GARAJ NÖB.',
          durum: 'beklemede',
          personelIds: [12],
          personelAdlari: ['Mehmet BİLEK'],
        ),
      ],
    );
    const mixedCalendar = TeamMonthlyCalendarDto(
      timId: 1,
      timAdi: '1-B Timi',
      yil: 2026,
      ay: 10,
      gunler: [mixedDay],
      ozet: summary,
    );
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TeamDutyCalendarModal(calendarData: mixedCalendar),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('2 grup'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('team-calendar-day-8')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('team-day-group-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-day-group-1')), findsOneWidget);
    expect(find.text('Bekleyen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow viewport does not overflow', (tester) async {
    await showCalendar(tester, const Size(320, 640));
    expect(tester.takeException(), isNull);
  });
}
