import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_export_sheet.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';
import 'package:personelapp2/features/temgundrap/data/temgundrap_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/services/temgundrap_activity_converter.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

class RosterOutputPreviewScreen extends ConsumerStatefulWidget {
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
  ConsumerState<RosterOutputPreviewScreen> createState() =>
      _RosterOutputPreviewScreenState();
}

class _RosterOutputPreviewScreenState
    extends ConsumerState<RosterOutputPreviewScreen> {
  bool _busy = false;
  String? _error;
  Future<List<MilitaryRosterRow>> _validatedRows() async {
    final recordChangedMsg = context.l10n.rosterOutputRecordsChangedError;
    final refreshed = await widget.loadRows();
    String fingerprint(List<MilitaryRosterRow> rows) => rows
        .map(
          (r) =>
              '${r.personelId}|${r.rutbe}|${r.adSoyad}|${r.groupCode}|${r.birligi}|${r.diger}',
        )
        .join('\n');
    if (fingerprint(refreshed) != fingerprint(widget.rows)) {
      throw StateError(recordChangedMsg);
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
        subtitle: context.l10n.rosterOutputSignedOutput(
          widget.date,
          widget.rows.length,
        ),
      );
      if (!mounted || action == null) return;
      final title = context.l10n.rosterOutputSelectedCardsTitle;
      switch (action.type) {
        case ArchiveExportType.excel:
          final rows = await _validatedRows();
          await MilitaryRosterExporter.shareExcelRoster(
            faaliyetAdi: title,
            tarih: widget.date,
            rows: rows,
            mergeCells: false,
            includeSignatures: true,
            timeRange: action.timeRange,
          );
        case ArchiveExportType.pdf:
          await PdfRosterExporter.showStylePickerAndSharePdf(
            context,
            faaliyetAdi: title,
            tarih: widget.date,
            rows: widget.rows,
            loadRows: _validatedRows,
            includeSignatures: true,
            timeRange: action.timeRange,
          );
        case ArchiveExportType.print:
          await PdfRosterExporter.showStylePickerAndPrintPdf(
            context,
            faaliyetAdi: title,
            tarih: widget.date,
            rows: widget.rows,
            loadRows: _validatedRows,
            includeSignatures: true,
            timeRange: action.timeRange,
          );
        case ArchiveExportType.text:
          final rows = await _validatedRows();
          await MilitaryRosterExporter.shareTextRoster(
            faaliyetAdi: title,
            tarih: widget.date,
            rows: rows,
            timeRange: action.timeRange,
          );
        case ArchiveExportType.temgundrap:
          final db = ref.read(databaseProvider);
          final actIds = widget.sources.map((a) => a.id).toSet();
          final assignments = await (db.select(db.faaliyetPersonelAtamaTable)
                ..where((tbl) => tbl.faaliyetId.isIn(actIds)))
              .get();
          final personnel = await db.select(db.personelTable).get();
          final pMap = {for (final p in personnel) p.id: p};
          final operations = TemgundrapActivityConverter.convertAll(
            activities: widget.sources,
            allAssignments: assignments,
            personnelMap: pMap,
          );
          final repo = TemgundrapRepository();
          final defaults = await repo.getApproverDefaults();
          final docDate = DateTime.tryParse(widget.date) ?? DateTime.now();
          final draft = TemgundrapDocument(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            date: docDate,
            unitTitle: defaults.unitTitle.isNotEmpty
                ? defaults.unitTitle
                : defaultTemgundrapUnitTitle,
            approverName: defaults.name,
            approverRank: defaults.rank,
            approverDuty: defaults.duty,
            operations: operations,
            isDraft: true,
            updatedAt: DateTime.now(),
          );
          if (mounted) {
            await AppNavigator.toTemgundrapForm(
              context,
              document: draft,
              date: docDate,
            );
          }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
        AppNotifications.error(
          context.l10n.rosterOutputExportError(error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(context.l10n.rosterOutputPreviewTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                context.l10n.rosterOutputPreviewDeduplicationNote(
                  widget.rows.length,
                ),
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
            label: Text(
              _busy
                  ? context.l10n.rosterOutputPreparing
                  : context.l10n.rosterOutputGetOutput,
            ),
          ),
        ),
      ),
    ),
  );
}
