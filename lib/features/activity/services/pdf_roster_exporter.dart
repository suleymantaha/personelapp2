import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfRosterExporter {
  /// Generates a PDF document for official Jandarma daily activity roster
  static Future<pw.Document> generateRosterPdf({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final pdf = pw.Document();

    // Filter out non-operational duties (İzinli, İstirahatli, Raporlu, Sevk)
    final filteredRows = rows
        .where((r) => DutyOrLeaveType.isOperationalDuty(r.diger))
        .toList();

    final titleText = '$faaliyetAdi İSİM LİSTESİ - $tarih'.toUpperCase();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Center(
                  child: pw.Text(
                    titleText,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // Roster Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellHeight: 22,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                },
                headers: <String>[
                  'S. NU',
                  'BİRLİĞİ',
                  'RÜTBE',
                  'ADI SOYADI',
                  'DİĞER',
                ],
                data: List<List<String>>.generate(filteredRows.length, (i) {
                  final r = filteredRows[i];
                  return [
                    (i + 1).toString(),
                    r.birligi,
                    r.rutbe,
                    r.adSoyad,
                    r.diger,
                  ];
                }),
              ),
              pw.SizedBox(height: 16),

              // Footer Stamp / Signature Space
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Düzenleyen: Jandarma Görev Takip',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Tarih: $tarih',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Exports PDF file and triggers OS share dialog
  static Future<void> sharePdfRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final pdf = await generateRosterPdf(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final sanitizedTitle = faaliyetAdi.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final file = File('${dir.path}/${sanitizedTitle}_$tarih.pdf');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$faaliyetAdi - Resmi İsim Listesi PDF Çıktısı',
      ),
    );
  }

  /// Directly sends PDF to native print dialog
  static Future<void> printPdfRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final pdf = await generateRosterPdf(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${faaliyetAdi}_$tarih.pdf',
    );
  }
}
