import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personelapp2/core/utils/export_file_name_helper.dart';
import 'package:personelapp2/core/utils/official_roster_title.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

part 'pdf_roster_styles.dart';
part 'pdf_roster_document.dart';
part 'pdf_roster_actions.dart';

enum PdfRosterStyle {
  /// Stil 1: Birlik ve özel görev hücrelerini kesintisiz blok olarak gösterir.
  verticalBlock,

  /// Stil 2: Her satırı tam çizgili klasik tablo biçiminde gösterir.
  smartPageChunk,

  /// Stil 3: Her tim/grubun ilk satırını gri bantla vurgular.
  headerBand,
}

class PdfRosterExporter {
  static String formatOfficialTitle(String faaliyetAdi, String rawDate) =>
      pdfFormatOfficialTitle(faaliyetAdi, rawDate);

  static pw.Widget builderSummaryBox(List<MilitaryRosterRow> rows) =>
      pdfBuilderSummaryBox(rows);

  static pw.Widget buildPdfTable(
    List<MilitaryRosterRow> rows, {
    PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  }) =>
      pdfBuildTable(rows, style: style);

  static Future<pw.Document> generateRosterPdf({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
    PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  }) =>
      pdfGenerateRoster(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
        style: style,
      );

  static Future<void> sharePdfRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
    PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  }) =>
      pdfShareRoster(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
        style: style,
      );

  static Future<void> printPdfRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
    PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  }) =>
      pdfPrintRoster(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
        style: style,
      );

  static Future<void> showStylePickerAndSharePdf(
    BuildContext context, {
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
    bool printDirectly = false,
  }) =>
      pdfShowStylePickerAndShare(
        context,
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
        printDirectly: printDirectly,
      );

  static Future<void> showStylePickerAndPrintPdf(
    BuildContext context, {
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) =>
      pdfShowStylePickerAndPrint(
        context,
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
      );
}
