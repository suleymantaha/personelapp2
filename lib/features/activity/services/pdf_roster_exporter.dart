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
    pw.Font? font;
    pw.Font? boldFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } on Exception catch (_) {
      // Fallback if offline
    }

    final pdf = pw.Document(
      theme: font != null && boldFont != null
          ? pw.ThemeData.withFont(
              base: font,
              bold: boldFont,
            )
          : null,
    );

    // Filter out non-operational duties (İzinli, İstirahatli, Raporlu, Sevk)
    final filteredRows = rows
        .where((r) => DutyOrLeaveType.isOperationalDuty(r.diger))
        .toList();

    final titleText = '$faaliyetAdi İSİM LİSTESİ - $tarih'.toUpperCase();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(),
                ),
                child: pw.Center(
                  child: pw.Text(
                    titleText,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // Roster Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(width: 0.8),
                headerStyle: const pw.TextStyle(
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
                  final showBirlik =
                      i == 0 || filteredRows[i - 1].birligi != r.birligi;
                  return [
                    (i + 1).toString(),
                    if (showBirlik) r.birligi else '',
                    r.rutbe,
                    r.adSoyad,
                    r.diger,
                  ];
                }),
              ),
              pw.SizedBox(height: 12),

              // Summary Box (GÖREV VE MEVCUT ÖZETİ) matching modTekTimSecim.bas
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.8),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GÖREV VE MEVCUT ÖZETİ',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Astsubay: ${filteredRows.where((r) => r.rutbe.contains('ASB') || r.rutbe.contains('ASTSB')).length}  •  '
                      'Uzman Jandarma: ${filteredRows.where((r) => r.rutbe.contains('UZM.J')).length}  •  '
                      'Uzman Erbaş: ${filteredRows.where((r) => r.rutbe.contains('UZM') && !r.rutbe.contains('UZM.J')).length}  •  '
                      'Er/Söz.Er: ${filteredRows.where((r) => r.rutbe.contains('ER')).length}  •  '
                      'TOPLAM MEVCUT: ${filteredRows.length} Personel',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
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
      onLayout: (format) async => pdf.save(),
      name: '${faaliyetAdi}_$tarih.pdf',
    );
  }
}
