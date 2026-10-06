import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_export_sheet.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';

class RosterOutputPreviewScreen extends StatefulWidget {
  const RosterOutputPreviewScreen({
    super.key,
    required this.date,
    required this.sources,
    required this.rows,
    required this.loadRows,
  });
  final String date;
  final List<GunlukFaaliyetTableData> sources;
  final List<MilitaryRosterRow> rows;
  final Future<List<MilitaryRosterRow>> Function() loadRows;
  @override
  State<RosterOutputPreviewScreen> createState() =>
      _RosterOutputPreviewScreenState();
}

class _RosterOutputPreviewScreenState extends State<RosterOutputPreviewScreen> {
  bool _busy = false;
  String? _error;
  Future<List<MilitaryRosterRow>> _validatedRows() async {
    final refreshed = await widget.loadRows();
    String fingerprint(List<MilitaryRosterRow> rows) => rows
        .map(
          (r) =>
              '${r.personelId}|${r.rutbe}|${r.adSoyad}|${r.groupCode}|${r.birligi}|${r.diger}',
        )
        .join('\n');
    if (fingerprint(refreshed) != fingerprint(widget.rows)) {
      throw StateError('Kayıtlar değişti. Önizlemeyi yeniden açın.');
    }
    return refreshed;
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final action = await showArchiveExportSheet(
        context,
        subtitle:
            '${widget.date} • ${widget.rows.length} personel • İmzalı çıktı',
      );
      if (!mounted || action == null) return;
      const title = 'Seçilen Kartlar';
      switch (action) {
        case ArchiveExportType.excel:
          final rows = await _validatedRows();
          await MilitaryRosterExporter.shareExcelRoster(
            faaliyetAdi: title,
            tarih: widget.date,
            rows: rows,
            mergeCells: false,
            includeSignatures: true,
          );
        case ArchiveExportType.pdf:
          await PdfRosterExporter.showStylePickerAndSharePdf(
            context,
            faaliyetAdi: title,
            tarih: widget.date,
            rows: widget.rows,
            loadRows: _validatedRows,
            includeSignatures: true,
          );
        case ArchiveExportType.print:
          await PdfRosterExporter.showStylePickerAndPrintPdf(
            context,
            faaliyetAdi: title,
            tarih: widget.date,
            rows: widget.rows,
            loadRows: _validatedRows,
            includeSignatures: true,
          );
        case ArchiveExportType.text:
          final rows = await _validatedRows();
          await MilitaryRosterExporter.shareTextRoster(
            faaliyetAdi: title,
            tarih: widget.date,
            rows: rows,
          );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
        AppNotifications.error('Dışa aktarılamadı: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Birleşik Çıktı Önizlemesi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${widget.rows.length} personel • Her kişi bir kez • Toplam baskıda gösterilmez',
              ),
              for (var i = 0; i < widget.sources.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${i + 1}. ${widget.sources[i].tarih} • ${widget.sources[i].faaliyetAdi}',
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const Divider(),
              for (final row in widget.rows)
                ListTile(
                  title: Text('${row.sNu}. ${row.adSoyad}'),
                  subtitle: Text(row.rutbe),
                ),
              const Divider(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final signer in heybetRosterSigners)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            Text(signer.title, textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            Text(signer.name, textAlign: TextAlign.center),
                            Text(signer.rank, textAlign: TextAlign.center),
                            Text(signer.role, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            key: const Key('roster-export'),
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(_busy ? 'Çıktı hazırlanıyor…' : 'Çıktı Al'),
          ),
        ),
      ),
    ),
  );
}
