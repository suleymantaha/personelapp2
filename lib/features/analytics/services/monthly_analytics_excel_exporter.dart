import 'package:excel/excel.dart';
import '../domain/monthly_analytics_report.dart';
import 'monthly_excel_chart_package.dart';
import 'monthly_excel_cell_style.dart';

/// Exports the same immutable, authorized snapshot displayed by the dashboard.
class MonthlyAnalyticsExcelExporter {
  const MonthlyAnalyticsExcelExporter._();

  static List<int> generate(MonthlyAnalyticsReport report) {
    final excel = Excel.createExcel();
    _summary(excel, report);
    _daily(excel, report);
    _duties(excel, report);
    _teams(excel, report);
    _quality(excel, report);
    excel.setDefaultSheet('Özet');
    excel.delete('Sheet1');
    return addMonthlyExcelCharts(excel.encode()!, report);
  }

  static void _summary(Excel excel, MonthlyAnalyticsReport r) {
    _sheet(excel, 'Özet', [
      ['Aylık görev özeti', 'Değer'],
      ['Başlangıç (dahil)', r.start],
      ['Bitiş (dahil)', r.end],
      ['Referans tarihi', r.asOf.toIso8601String().substring(0, 10)],
      ['Tim kapsamı', r.teamLabel],
      ['Görev kapsamı', r.dutyLabel],
      [
        'Durum kapsamı',
        switch (r.status) {
          'onaylandi' => 'Onaylanan',
          'beklemede' => 'Bekleyen',
          'reddedildi' => 'Reddedilen',
          _ => r.status,
        }
      ],
      ['Toplam görevlendirme (kişi sayısı değil)', r.assignmentCount],
      ['Görev alan farklı kişi', r.uniquePersonnel],
      ['Kayıt bulunan gün', r.recordedDays],
      ['Seçili gün', r.totalDays],
      ['Timi bilinen görevlendirme', r.knownTeamAssignments],
      ['Timi bilinmeyen görevlendirme', r.unknownTeamAssignments],
      ['Tim bilgisi kapsamı (%)', r.teamCoverage * 100],
      ['Kayıt bulunmayan gün', r.totalDays - r.recordedDays],
      [
        'Planlanan görevlendirme',
        r.days
            .where((d) => d.isPlanned)
            .fold<int>(0, (sum, day) => sum + day.assignments)
      ],
      ['Personel mevcudu (güncel)', r.currentHeadcount ?? 'Bilinmiyor'],
      [
        'Mevcut bilgisi tarihi',
        r.headcountAsOf?.toIso8601String().substring(0, 10) ?? 'Bilinmiyor'
      ],
    ]);
  }

  static void _daily(Excel excel, MonthlyAnalyticsReport r) {
    _sheet(excel, 'Günlük', [
      [
        'Tarih',
        'Görevlendirme',
        'Tarih niteliği',
        'Kayıtlı atama',
        'Planlanan atama'
      ],
      for (final day in r.days)
        [
          day.date,
          day.assignments,
          day.assignments == 0
              ? 'Kayıt yok'
              : day.isPlanned
                  ? 'Planlanan'
                  : 'Geçmiş / bugün',
          day.isPlanned ? 0 : day.assignments,
          day.isPlanned ? day.assignments : 0,
        ],
    ]);
  }

  static void _duties(Excel excel, MonthlyAnalyticsReport r) {
    _sheet(excel, 'Görevler', [
      ['Görev', 'Görevlendirme', 'Pay (%)'],
      for (final duty in r.duties)
        [
          duty.duty,
          duty.count,
          r.assignmentCount == 0 ? 0.0 : duty.count / r.assignmentCount * 100
        ],
      if (r.duties.isEmpty) ['Kayıt yok', 0, 0.0],
    ]);
  }

  static void _teams(Excel excel, MonthlyAnalyticsReport r) {
    _sheet(excel, 'Tim Matrisi', [
      [
        'Tim',
        for (final duty in r.duties) ...[
          '${duty.duty} · farklı kişi',
          '${duty.duty} · görevlendirme'
        ],
        'Toplam farklı kişi',
        'Toplam görevlendirme'
      ],
      for (final team in r.teams)
        [
          team.name,
          for (final duty in r.duties) ...[
            team.uniquePersonnelByDuty[duty.duty] ?? 0,
            team.duties[duty.duty] ?? 0
          ],
          team.uniquePersonnel,
          team.total
        ],
    ]);
    excel['Tim Matrisi'].setRowHeight(0, 64);
  }

  static void _quality(Excel excel, MonthlyAnalyticsReport r) {
    _sheet(
        excel,
        'Kalite',
        [
          ['Kontrol / tanım', 'Değer / açıklama'],
          ['Timi bilinmeyen görevlendirme', r.unknownTeamAssignments],
          ['Sınıflandırılmamış görev', r.unclassifiedAssignments],
          [
            'Sayım birimi',
            'Faaliyet / personel / tarihsel tim / normalize görev başına tek görevlendirme.'
          ],
          [
            'Tarih',
            'Kaynak faaliyet tarihi sayılır; iki günlük kapsama ayrıca eklenmez.'
          ],
          [
            'Tim matrisi',
            'Yalnız bilinen tarihsel timler. Bilinmeyen timler genel toplamda yer alır.'
          ],
          [
            'Planlanan',
            'Referans tarihinden sonraki kaynak tarihler planlanandır.'
          ],
          ['Tamamlanma', 'Geçmiş tarih tamamlanmış görev kanıtı değildir.'],
          [
            'Boş gün',
            'Kayıt yok anlamına gelir; görev yapılmadığını kanıtlamaz.'
          ],
          [
            'Görev adları',
            'Yalnız açık HAZIRKITA alias eşlemesi uygulanır; diğer etiketleri gözden geçirin.'
          ],
          [
            'Kapsam',
            'Seçili başlangıç ve bitiş dahil edilir; kısmi dönem tam ay sayılmaz.'
          ],
          [
            'Tim bilgisi kapsamı',
            'Timi bilinen görevlendirme / tüm görevlendirmeler; veri yoksa 0.'
          ],
          [
            'Personel mevcudu (güncel)',
            'Yetkili, aktif, demo olmayan personelin güncel mevcudu; tarih/görev/durum filtrelerinden bağımsızdır. Geçmiş ay mevcudu değildir.'
          ],
          [
            'Görev alan farklı kişi',
            'Seçili dönemdeki farklı personel sayısıdır. Aynı kişi birden çok görevlendirmede yer alabilir.'
          ],
          [
            'Tim matrisi kişi sayıları',
            'Görev başına farklı kişi sayıları toplanmaz. Bir görevli bütün timin görev aldığı anlamına gelmez.'
          ],
        ],
        wide: true);
  }

  static void _sheet(Excel excel, String name, List<List<Object>> rows,
      {bool wide = false}) {
    final sheet = excel[name];
    for (var row = 0; row < rows.length; row++) {
      sheet.setRowHeight(row, row == 0 ? 30 : (wide ? 48 : 28));
      for (var col = 0; col < rows[row].length; col++) {
        final value = rows[row][col];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          ..value = switch (value) {
            int n => IntCellValue(n),
            double n => DoubleCellValue(n),
            _ => TextCellValue(value.toString()),
          }
          ..cellStyle = monthlyExcelCellStyle(row, value);
        sheet.setColumnWidth(col, col == 0 ? 36 : (wide ? 92 : 24));
      }
    }
  }
}
