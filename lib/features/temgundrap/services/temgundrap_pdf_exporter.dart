import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personelapp2/core/utils/export_file_name_helper.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class TemgundrapPdfExporter {
  const TemgundrapPdfExporter._();

  static const _turkishMonths = <String>[
    'OCAK',
    'ŞUBAT',
    'MART',
    'NİSAN',
    'MAYIS',
    'HAZİRAN',
    'TEMMUZ',
    'AĞUSTOS',
    'EYLÜL',
    'EKİM',
    'KASIM',
    'ARALIK',
  ];

  static String documentTitle(TemgundrapDocument document) {
    final date = document.date;
    final day = date.day.toString().padLeft(2, '0');
    final month = _turkishMonths[date.month - 1];
    return '${document.unitTitle} $day $month ${date.year} TARİHİNDE '
        'PLANLANAN OPERASYON TAKİP ÇİZELGESİ';
  }

  static Future<pw.Document> build(TemgundrapDocument document) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    pw.Widget cell(String text, {bool bold = false}) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(
            text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 6.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );
    pw.Widget forceSubtable(List<String> values, {bool bold = false}) =>
        pw.Table(
          border: pw.TableBorder.all(width: .6),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.25),
            1: pw.FlexColumnWidth(2.1),
            2: pw.FlexColumnWidth(1.15),
            3: pw.FlexColumnWidth(.35),
          },
          children: [
            pw.TableRow(
              children: values.map((value) => cell(value, bold: bold)).toList(),
            ),
          ],
        );
    pw.Widget forceGroup(List<String> values, {bool header = false}) => header
        ? pw.Column(children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(3),
              alignment: pw.Alignment.center,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: .6)),
              ),
              child: pw.Text('OPERASYON KUVVETİ',
                  style: pw.TextStyle(
                      fontSize: 7, fontWeight: pw.FontWeight.bold)),
            ),
            forceSubtable(values, bold: true),
          ])
        : forceSubtable(values);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        build: (_) => [
          pw.Container(
            width: double.infinity,
            alignment: pw.Alignment.center,
            child: pw.Text(
              documentTitle(document),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Table(
            border: pw.TableBorder.all(width: .6),
            columnWidths: const {
              0: pw.FlexColumnWidth(.55),
              1: pw.FlexColumnWidth(1.7),
              2: pw.FlexColumnWidth(2.0),
              3: pw.FlexColumnWidth(4.5),
              4: pw.FlexColumnWidth(1.65),
              5: pw.FlexColumnWidth(1.65),
              6: pw.FlexColumnWidth(2.15),
              7: pw.FlexColumnWidth(1.7),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  cell('S.NU', bold: true),
                  cell('ÇIKARAN BİRLİK', bold: true),
                  cell('OPERASYON BÖLGESİ', bold: true),
                  forceGroup(
                    ['KUVVETİ', 'OPERASYON KOMUTANI', 'MEVCUT', ''],
                    header: true,
                  ),
                  cell('BAŞLAMA ZAMANI', bold: true),
                  cell('BİTİŞ ZAMANI', bold: true),
                  cell('OPERASYON MAKSADI', bold: true),
                  cell('AÇIKLAMA', bold: true),
                ],
              ),
              ...document.operations.asMap().entries.map((entry) {
                final item = entry.value;
                final labels =
                    [...item.strength.byLabel.keys, 'TOPLAM'].join('\n');
                final counts = [
                  ...item.strength.byLabel.values,
                  item.totalStrength,
                ].join('\n');
                return pw.TableRow(children: [
                  cell('${entry.key + 1}'),
                  cell(item.issuingUnit),
                  cell(item.operationArea),
                  forceGroup([
                    item.forceDescription,
                    item.commander.displayText,
                    labels,
                    counts,
                  ]),
                  cell(TemgundrapFormatters.militaryDateTime(item.startAt)),
                  cell(TemgundrapFormatters.militaryDateTime(item.endAt)),
                  cell(item.purpose),
                  cell(item.description),
                ]);
              }),
            ],
          ),
          if (document.approverName.isNotEmpty ||
              document.approverRank.isNotEmpty ||
              document.approverDuty.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                width: 180,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      '(İMZALI)',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    if (document.approverName.isNotEmpty)
                      pw.Text(
                        document.approverName,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    if (document.approverRank.isNotEmpty)
                      pw.Text(
                        document.approverRank,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    if (document.approverDuty.isNotEmpty)
                      pw.Text(
                        document.approverDuty,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return pdf;
  }

  static Future<void> printDocument(TemgundrapDocument document) async {
    final bytes = await (await build(document)).save();
    await Printing.layoutPdf(name: 'TEMGÜNDRAP', onLayout: (_) async => bytes);
  }

  static Future<void> shareDocument(TemgundrapDocument document) async {
    final bytes = await (await build(document)).save();
    final directory = await getTemporaryDirectory();
    final dateStr =
        '${document.date.year}-${document.date.month.toString().padLeft(2, '0')}-${document.date.day.toString().padLeft(2, '0')}';
    final fileName = formatExportFileName(
      title: 'TEMGÜNDRAP_${document.unitTitle}',
      date: dateStr,
      extension: 'pdf',
    );
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'TEMGÜNDRAP operasyon takip çizelgesi',
      ),
    );
  }
}
