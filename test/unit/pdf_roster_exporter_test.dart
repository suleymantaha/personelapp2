import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';

MilitaryRosterRow _row(
  int number, {
  String birlik = '1 İNCİ TİM',
  String name = 'Personel Adı Soyadı',
  String detail = 'Ana Nizamiye',
}) {
  return MilitaryRosterRow(
    sNu: number,
    birligi: birlik,
    rutbe: 'J.UZM.ÇVŞ.',
    adSoyad: name,
    diger: detail,
    groupCode: 'NOBET_HEYETI',
  );
}

void main() {
  test('PDF table repeats its header and supports two-line cells', () {
    final table = PdfRosterExporter.buildPdfTable(
      [
        _row(
          1,
          name: 'Çok Uzun İsimli Personelin Eksiksiz Adı ve Soyadı',
          detail: 'Ana Nizamiye ve çevre emniyeti uzun görev açıklaması',
        ),
      ],
    ) as pw.Table;

    expect(table.children.first.repeat, isTrue);
    final dataRow = table.children[1];
    final nameCell = dataRow.children[3] as pw.Container;
    final detailCell = dataRow.children[4] as pw.Container;
    expect((nameCell.child as pw.Text).maxLines, 2);
    expect((detailCell.child as pw.Text).maxLines, 2);
    expect(nameCell.constraints?.minHeight, 18);
  });

  test('PDF styles produce distinct table treatments', () {
    final rows = [
      _row(1, birlik: '1 inci tim'),
      _row(2, birlik: '  1 İNCİ   TİM  '),
    ];
    final vertical = PdfRosterExporter.buildPdfTable(
      rows,
      style: PdfRosterStyle.verticalBlock,
    ) as pw.Table;
    final smart = PdfRosterExporter.buildPdfTable(
      rows,
      style: PdfRosterStyle.smartPageChunk,
    ) as pw.Table;
    final band = PdfRosterExporter.buildPdfTable(
      rows,
      style: PdfRosterStyle.headerBand,
    ) as pw.Table;

    final verticalUnitCell = vertical.children[1].children[1] as pw.Container;
    final smartUnitCell = smart.children[1].children[1] as pw.Container;
    expect(
      ((verticalUnitCell.child as pw.Text).text as pw.TextSpan)
          .style
          ?.fontWeight,
      isNot(
        ((smartUnitCell.child as pw.Text).text as pw.TextSpan)
            .style
            ?.fontWeight,
      ),
    );
    expect(band.children[1].decoration?.color, PdfColors.grey200);
    expect(vertical.children[1].decoration?.color, PdfColors.white);
  });

  test('PDF recreates merged unit cells inside each page table', () {
    final table = PdfRosterExporter.buildPdfTable(
      [
        _row(1, birlik: '1 İNCİ TİM'),
        _row(2, birlik: '1 inci tim'),
        _row(3, birlik: '  1 İNCİ   TİM '),
      ],
    ) as pw.Table;

    final unitCells = table.children
        .skip(1)
        .map((row) => row.children[1] as pw.Container)
        .toList();
    final labels = unitCells
        .map(
          (cell) => ((cell.child as pw.Text).text as pw.TextSpan).text ?? '',
        )
        .toList();

    expect(labels.where((label) => label.isNotEmpty), hasLength(1));
    expect(unitCells[0].decoration?.border?.bottom.width, 0);
    expect(unitCells[1].decoration?.border?.bottom.width, 0);
    expect(unitCells[2].decoration?.border?.bottom.width, greaterThan(0));
  });

  testWidgets('long PDF roster spans pages without generation errors',
      (tester) async {
    final rows = List.generate(
      90,
      (index) => _row(
        index + 1,
        birlik: index < 55 ? 'UZUN GRUP' : 'İKİNCİ GRUP',
        name: 'Personel ${index + 1} Uzun Adı Soyadı',
        detail: 'Uzun görev yeri ve açıklaması ${index + 1}',
      ),
    );
    final pdf = await PdfRosterExporter.generateRosterPdf(
      faaliyetAdi: 'Çok Sayfalı Faaliyet',
      tarih: '29.07.2026',
      rows: rows,
      style: PdfRosterStyle.headerBand,
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
    expect(pdf.document.pdfPageList.pages.length, greaterThan(1));
  });
}
