import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';

List<MilitaryRosterRow> roster(int count) => List.generate(
  count,
  (i) => MilitaryRosterRow(
    sNu: i + 1,
    birligi: 'J.Komd.Öz.Hrk.Tb.Klığı',
    rutbe: 'J.Uzm.Çvş.',
    adSoyad: 'Personel ${i + 1}',
    diger: '',
  ),
);

void main() {
  test(
    'Excel prints personnel and signatures but keeps totals outside print area',
    () {
      final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
        faaliyetAdi: 'Heybet',
        tarih: '2026-10-06',
        rows: roster(95),
        mergeCells: false,
        includeSignatures: true,
      );
      final sheet = Excel.decodeBytes(bytes)['İsim Listesi'];
      final values = sheet.rows
          .map((r) => r.map((c) => c?.value?.toString() ?? '').join('|'))
          .toList();
      final tanzim = values.indexWhere((r) => r.contains('TANZİM EDEN'));
      final ihsan = values.indexWhere((r) => r.contains('İhsan DAĞLI'));
      final serdar = values.indexWhere((r) => r.contains('Serdar YILDIZ'));
      final total = values.indexWhere((r) => r.contains('Toplam'));
      expect(tanzim, greaterThan(95));
      expect(ihsan, greaterThan(tanzim));
      expect(serdar, ihsan);
      expect(values.join('\n'), contains('Eğt.Hrk. ve İsth.Ks.A'));
      expect(values.join('\n'), contains('J.Komd.Öz.Hrk.Tb.K.'));
      final zip = ZipDecoder().decodeBytes(bytes);
      final workbook = utf8.decode(
        zip.findFile('xl/workbook.xml')!.content as List<int>,
      );
      final area = RegExp(r'name="_xlnm.Print_Area"[^>]*>(.*?)<')
          .firstMatch(workbook)!
          .group(1)!;
      final lastRow = int.parse(
        RegExp(r'\$E\$(\d+)').firstMatch(area)!.group(1)!,
      );
      expect(lastRow, greaterThan(ihsan + 1));
      expect(lastRow, lessThan(total + 1));
      expect(values.take(lastRow).join('\n'), isNot(contains('Toplam')));
    },
  );

  test('ordinary Excel retains existing output without Heybet signers', () {
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Devriye',
      tarih: '2026-10-06',
      rows: roster(1),
    );
    final text = Excel.decodeBytes(bytes)['İsim Listesi'].rows
        .expand((r) => r)
        .map((c) => c?.value?.toString() ?? '')
        .join('\n');
    expect(text, isNot(contains('İhsan DAĞLI')));
  });

  for (final count in [0, 1, 32, 33, 95, 100, 120]) {
    testWidgets(
      'signed PDF paginates $count rows without an extra summary page',
      (tester) async {
        final pdf = await PdfRosterExporter.generateRosterPdf(
          faaliyetAdi: 'Heybet',
          tarih: '2026-10-06',
          rows: roster(count),
          includeSignatures: true,
        );
        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
        if (count == 95 || count == 100)
          expect(pdf.document.pdfPageList.pages.length, 2);
        if (count <= 33) expect(pdf.document.pdfPageList.pages.length, 1);
      },
    );
  }
}
