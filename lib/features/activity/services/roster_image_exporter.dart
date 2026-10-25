import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/utils/export_file_name_helper.dart';
import 'exporter/spreadsheet_image_renderer.dart';
import 'military_roster_exporter.dart';
import 'roster_image_file_gateway.dart';
import 'roster_signature.dart';

class RosterImageExporter {
  static Future<Uint8List> generate({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
    bool mergeCells = true,
    bool includeSignatures = false,
    List<RosterSigner> signers = heybetRosterSigners,
    String? timeRange,
  }) =>
      SpreadsheetImageRenderer.render(
          MilitaryRosterExporter.generateMilitaryExcelBytes(
              faaliyetAdi: faaliyetAdi,
              tarih: tarih,
              rows: rows,
              mergeCells: mergeCells,
              includeSignatures: includeSignatures,
              signers: signers,
              timeRange: timeRange));

  static int _sequence = 0;
  static Future<bool> save({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
    bool mergeCells = true,
    bool includeSignatures = false,
    List<RosterSigner> signers = heybetRosterSigners,
    String? timeRange,
    Rect? shareOrigin,
  }) async {
    final bytes = await generate(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
        mergeCells: mergeCells,
        includeSignatures: includeSignatures,
        signers: signers,
        timeRange: timeRange);
    final title =
        formatExportFileName(title: faaliyetAdi, date: tarih, extension: 'png');
    final name = '${title.substring(0, title.length - 4)}_'
        '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}.png';
    return saveRosterImageFile(name, bytes, shareOrigin: shareOrigin);
  }
}

bool _saving = false;

Future<void> saveRosterImage(
  BuildContext context, {
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
  bool mergeCells = true,
  bool includeSignatures = false,
  List<RosterSigner> signers = heybetRosterSigners,
  String? timeRange,
}) async {
  if (_saving) return;
  _saving = true;
  final l10n = context.l10n;
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  AppNotifications.info(l10n.rosterImageSaving);
  try {
    final saved = await RosterImageExporter.save(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
        mergeCells: mergeCells,
        includeSignatures: includeSignatures,
        signers: signers,
        timeRange: timeRange,
        shareOrigin: origin);
    if (context.mounted && saved) {
      AppNotifications.success(l10n.rosterImageSaved);
    }
  } on SpreadsheetImageTooLarge {
    if (context.mounted) AppNotifications.error(l10n.rosterImageTooLarge);
  } finally {
    _saving = false;
  }
}
