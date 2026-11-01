import 'package:flutter/material.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_image_exporter.dart';
import 'archive_export_sheet.dart';

/// All entry points retain their own fresh scope loader; only format dispatch is shared.
Future<void> showRosterFormatActions(
  BuildContext context, {
  required String name,
  required String date,
  required String subtitle,
  required Future<List<MilitaryRosterRow>> Function() loadRows,
}) async {
  final action = await showArchiveExportSheet(context,
      subtitle: subtitle, showTemgundrap: false);
  if (action == null || !context.mounted) return;
  final rows = await loadRows();
  if (!context.mounted || rows.isEmpty) return;
  switch (action.type) {
    case ArchiveExportType.excel:
      await MilitaryRosterExporter.shareExcelRoster(
          faaliyetAdi: name,
          tarih: date,
          rows: rows,
          timeRange: action.timeRange);
    case ArchiveExportType.image:
      await saveRosterImage(context,
          faaliyetAdi: name,
          tarih: date,
          rows: rows,
          timeRange: action.timeRange);
    case ArchiveExportType.pdf:
      await PdfRosterExporter.showStylePickerAndSharePdf(context,
          faaliyetAdi: name,
          tarih: date,
          rows: rows,
          loadRows: loadRows,
          timeRange: action.timeRange);
    case ArchiveExportType.print:
      await PdfRosterExporter.showStylePickerAndPrintPdf(context,
          faaliyetAdi: name,
          tarih: date,
          rows: rows,
          loadRows: loadRows,
          timeRange: action.timeRange);
    case ArchiveExportType.text:
      await MilitaryRosterExporter.shareTextRoster(
          faaliyetAdi: name,
          tarih: date,
          rows: rows,
          timeRange: action.timeRange);
    case ArchiveExportType.temgundrap:
      throw StateError('Rapor için ayrı TEMGÜNDRAP işlemini kullanın.');
  }
}
