import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';
import 'package:personelapp2/features/matrix/presentation/widgets/team_duty_calendar_modal.dart';

void main() {
  group('TeamDutyCalendarModal Widget Tests', () {
    for (final dark in [false, true]) {
      testWidgets(
        'switches day details without keeping the previous personnel (dark: $dark)',
        (tester) async {
          const calendar = TeamMonthlyCalendarDto(
            timId: 1,
            timAdi: '1/B',
            yil: 2026,
            ay: 8,
            ozet: TeamDutySummaryDto(
              timId: 1,
              timAdi: '1/B',
              toplamGorevGunSayisi: 1,
              toplamGorevSaati: 8,
              aktifPersonelSayisi: 1,
              ortalamaYukYuzdesi: 10,
              gorevTuruDagilimi: {'NÖBET': 1},
            ),
            gunler: [
              TeamDayDutyDto(
                tarih: '2026-08-01',
                gunIndex: 1,
                gorevKodu: 'Nbt',
                gorevTamAdi: 'NÖBET',
                gorevliPersonelAdlari: ['Ahmet Yılmaz'],
              ),
              TeamDayDutyDto(
                tarih: '2026-08-02',
                gunIndex: 2,
                gorevKodu: '',
                gorevTamAdi: '',
                gorevliPersonelAdlari: [],
              ),
            ],
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkMilitaryTheme : AppTheme.militaryTheme,
              home: const Scaffold(
                body: TeamDutyCalendarModal(calendarData: calendar),
              ),
            ),
          );
          await tester.tap(find.text('1'));
          await tester.pumpAndSettle();
          expect(find.text('Ahmet Yılmaz'), findsOneWidget);
          await tester.tap(find.text('2'));
          await tester.pumpAndSettle();
          expect(find.text('Ahmet Yılmaz'), findsNothing);
          expect(
            find.text('Bu tarihte görevli personel kaydı bulunmuyor.'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'renders calendar modal header, day cells and buttons correctly',
      (WidgetTester tester) async {
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
      },
    );
  });
}
