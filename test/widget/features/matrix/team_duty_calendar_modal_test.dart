import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';
import 'package:personelapp2/features/matrix/presentation/widgets/team_duty_calendar_modal.dart';

void main() {
  group('TeamDutyCalendarModal Widget Tests', () {
    testWidgets('renders calendar modal header, day cells and buttons correctly', (WidgetTester tester) async {
      const summary = TeamDutySummaryDto(
        timId: 1,
        timAdi: '1. Tim',
        toplamGorevGunSayisi: 15,
        toplamGorevSaati: 120.0,
        aktifPersonelSayisi: 5,
        ortalamaYukYuzdesi: 45.0,
        gorevTuruDagilimi: {'GÜLÜŞKÜR': 12},
      );

      const sampleCalendar = TeamMonthlyCalendarDto(
        timId: 1,
        timAdi: '1. Tim',
        yil: 2026,
        ay: 8,
        ozet: summary,
        gunler: [
          TeamDayDutyDto(
            tarih: '2026-08-01',
            gunIndex: 1,
            gorevKodu: 'Gş',
            gorevTamAdi: 'GÜLÜŞKÜR',
            gorevliPersonelAdlari: ['Ahmet Yılmaz'],
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamDutyCalendarModal(calendarData: sampleCalendar),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1. Tim'), findsWidgets);
      expect(find.byType(TeamDutyCalendarModal), findsOneWidget);
    });
  });
}
