import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class TemgundrapPdfExporter {
  const TemgundrapPdfExporter._();

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
    const headers = [
      'S.NU',
      'ÇIKARAN BİRLİK',
      'OPERASYON BÖLGESİ',
      'KUVVETİ',
      'OPERASYON KOMUTANI',
      'MEVCUT',
      'BAŞLAMA',
      'BİTİŞ',
      'MAKSAT',
      'AÇIKLAMA',
    ];
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        build: (_) => [
          pw.Text(
            document.unitTitle,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: document.operations.asMap().entries.map((entry) {
              final item = entry.value;
              final strength = [
                ...item.strength.byLabel.entries.map(
                  (e) => '${e.key} ${e.value}',
                ),
                'TOPLAM ${item.totalStrength}',
              ].join('\n');
              return [
                '${entry.key + 1}',
                item.issuingUnit,
                item.operationArea,
                item.forceDescription,
                item.commander.displayText,
                strength,
                TemgundrapFormatters.militaryDateTime(item.startAt),
                TemgundrapFormatters.militaryDateTime(item.endAt),
                item.purpose,
                item.description,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 6.5,
            ),
            cellStyle: const pw.TextStyle(fontSize: 6.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(width: .6),
          ),
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
    final file = File('${directory.path}/TEMGUNDRAP_${document.id}.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'TEMGÜNDRAP operasyon takip çizelgesi',
      ),
    );
  }
}
