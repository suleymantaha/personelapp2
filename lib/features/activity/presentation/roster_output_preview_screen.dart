import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_export_sheet.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_preview_overview.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_preview_people_sheet.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_preview_rule_and_people.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_preview_actions.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_preview_signers.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_image_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_rank_order.dart';
import 'package:personelapp2/features/activity/services/roster_matrix_x_rule.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';
import 'package:personelapp2/features/activity/services/roster_signature_store.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_signer_dialog.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';

class RosterOutputPreviewScreen extends ConsumerStatefulWidget {
  const RosterOutputPreviewScreen({
    super.key,
    required this.date,
    required this.sources,
    required this.rows,
    required this.loadRows,
    this.loadMatrix,
    this.loadSigners,
  });
  final String date;
  final List<GunlukFaaliyetTableData> sources;
  final List<MilitaryRosterRow> rows;
  final Future<List<MilitaryRosterRow>> Function() loadRows;
  final Future<Map<int, Map<int, MatrixDayCell>>> Function()? loadMatrix;
  final Future<List<RosterSigner>> Function()? loadSigners;
  @override
  ConsumerState<RosterOutputPreviewScreen> createState() =>
      _RosterOutputPreviewScreenState();
}

class _RosterOutputPreviewScreenState
    extends ConsumerState<RosterOutputPreviewScreen> {
  bool _busy = false;
  String? _error;
  final _signatureStore = RosterSignatureStore();
  List<RosterSigner> _signers = List.of(heybetRosterSigners);
  bool _signaturesReady = false;
  bool _signerLoadFailed = false;
  RosterMatrixXResult? _ruleResult;
  bool _showAllPeople = false;
  bool _showAllCards = false;
  bool _showSigners = false;

  @override
  void initState() {
    super.initState();
    _loadSigners();
  }

  Future<void> _loadSigners() async {
    try {
      final signers =
          await (widget.loadSigners?.call() ?? _signatureStore.load());
      if (mounted) {
        setState(() {
          _signers = signers;
          _signaturesReady = true;
          _signerLoadFailed = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _signerLoadFailed = true;
          _error = context.l10n.rosterSignaturesLoadError;
        });
      }
    }
  }

  Future<void> _editSigner(int index) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RosterSignerDialog(
          signer: _signers[index],
          onSave: (signer) async {
            final updated = List<RosterSigner>.of(_signers)..[index] = signer;
            await _signatureStore.save(updated);
            if (mounted) setState(() => _signers = updated);
          },
        ),
      );
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

  String get _month => widget.date.substring(0, 7);
  int get _outputDay => DateTime.parse(widget.date).day;

  Future<Map<int, Map<int, MatrixDayCell>>> _matrixForMonth() async {
    if (widget.loadMatrix != null) return widget.loadMatrix!();
    final session = ref.read(userSessionProvider);
    if (session == null) {
      throw StateError(context.l10n.commonSessionNotVerified);
    }
    await ref.read(activityRepositoryProvider).requireOutputAuthority(session);
    return ref
        .read(matrixRepositoryProvider)
        .watchMonthlyMatrix(
          _month,
          commanderUsername: session.isAdmin ? null : session.username,
        )
        .first;
  }

  Future<void> _previewRule() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await _validatedRows();
      final matrix = await _matrixForMonth();
      if (!mounted) return;
      setState(() {
        _ruleResult = applyRosterMatrixXRule(
          rows,
          matrix,
          throughDay: _outputDay,
        );
        _showAllPeople = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _ruleResult = null;
          _showAllPeople = false;
          _error = '$error';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showRulePeople({required bool excluded}) {
    final result = _ruleResult;
    if (result == null || _busy) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RosterPreviewPeopleSheet(
        result: result,
        excluded: excluded,
      ),
    );
  }

  Future<List<MilitaryRosterRow>> _exportRows(
    bool rankOrdered, {
    bool rule = false,
  }) async {
    final recordChangedMsg = context.l10n.rosterOutputRecordsChangedError;
    final rows = await _validatedRows();
    if (rule) {
      final preview = _ruleResult;
      if (preview == null) {
        throw StateError(recordChangedMsg);
      }
      final current = applyRosterMatrixXRule(
        rows,
        await _matrixForMonth(),
        throughDay: _outputDay,
      );
      String fingerprint(List<MilitaryRosterRow> list) => list
          .map((row) => '${row.personelId}|${row.rutbe}|${row.adSoyad}')
          .join('\n');
      if (current.excludedCount != preview.excludedCount ||
          fingerprint(current.rows) != fingerprint(preview.rows) ||
          current.excludedPeople
                  .map((person) => '${person.row.personelId}|${person.xDays}')
                  .join('\n') !=
              preview.excludedPeople
                  .map((person) => '${person.row.personelId}|${person.xDays}')
                  .join('\n')) {
        throw StateError(recordChangedMsg);
      }
      return current.rows;
    }
    return rankOrdered ? rankOrderedRosterRows(rows) : rows;
  }

  Future<void> _export({bool rankOrdered = false, bool rule = false}) async {
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
          rule ? _ruleResult?.rows.length ?? 0 : widget.rows.length,
        ),
        showTemgundrap: false,
      );
      if (!mounted || action == null) return;
      final title = context.l10n.rosterOutputSelectedCardsTitle;
      switch (action.type) {
        case ArchiveExportType.excel:
          final rows = await _exportRows(rankOrdered, rule: rule);
          await MilitaryRosterExporter.shareExcelRoster(
            faaliyetAdi: title,
            tarih: widget.date,
            rows: rows,
            mergeCells: false,
            includeSignatures: true,
            signers: _signers,
            timeRange: action.timeRange,
          );
        case ArchiveExportType.image:
          final rows = await _exportRows(rankOrdered, rule: rule);
          if (!mounted) return;
          await saveRosterImage(context,
              faaliyetAdi: title,
              tarih: widget.date,
              rows: rows,
              mergeCells: false,
              includeSignatures: true,
              signers: _signers,
              timeRange: action.timeRange);
        case ArchiveExportType.pdf:
          await PdfRosterExporter.showStylePickerAndSharePdf(
            context,
            faaliyetAdi: title,
            tarih: widget.date,
            rows: rule
                ? _ruleResult?.rows ?? const []
                : rankOrdered
                    ? rankOrderedRosterRows(widget.rows)
                    : widget.rows,
            loadRows: () => _exportRows(rankOrdered, rule: rule),
            includeSignatures: true,
            signers: _signers,
            timeRange: action.timeRange,
          );
        case ArchiveExportType.print:
          await PdfRosterExporter.showStylePickerAndPrintPdf(
            context,
            faaliyetAdi: title,
            tarih: widget.date,
            rows: rule
                ? _ruleResult?.rows ?? const []
                : rankOrdered
                    ? rankOrderedRosterRows(widget.rows)
                    : widget.rows,
            loadRows: () => _exportRows(rankOrdered, rule: rule),
            includeSignatures: true,
            signers: _signers,
            timeRange: action.timeRange,
          );
        case ArchiveExportType.text:
          final rows = await _exportRows(rankOrdered, rule: rule);
          await MilitaryRosterExporter.shareTextRoster(
            faaliyetAdi: title,
            tarih: widget.date,
            rows: rows,
            timeRange: action.timeRange,
          );
        case ArchiveExportType.temgundrap:
          throw StateError('TEMGÜNDRAP ayrı rapor akışından açılmalıdır.');
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
  Widget build(BuildContext context) {
    final displayRows = _ruleResult?.rows ?? widget.rows;
    final hasRulePreview = _ruleResult != null;
    final throughDateLabel =
        '1–${DateFormat('d MMMM yyyy', 'tr').format(DateTime.parse(widget.date))}';
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Çıktı Hazırlığı'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RosterPreviewOverview(
                  peopleCount: widget.rows.length,
                  sources: widget.sources,
                  expanded: _showAllCards,
                  onToggleCards: () =>
                      setState(() => _showAllCards = !_showAllCards),
                ),
                const SizedBox(height: 12),
                RosterPreviewRuleCard(
                  month: throughDateLabel,
                  result: _ruleResult,
                  busy: _busy,
                  onPreview: _previewRule,
                  onShowIncluded: () => _showRulePeople(excluded: false),
                  onShowExcluded: () => _showRulePeople(excluded: true),
                  onReset: () => setState(() {
                    _ruleResult = null;
                    _showAllPeople = false;
                  }),
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
                if (_signerLoadFailed && !_signaturesReady)
                  TextButton(
                    key: const Key('roster-signatures-retry'),
                    onPressed: _loadSigners,
                    child: Text(context.l10n.commonRetry),
                  ),
                const SizedBox(height: 12),
                RosterPreviewPeople(
                  rows: displayRows,
                  showAll: _showAllPeople,
                  onToggleAll: () =>
                      setState(() => _showAllPeople = !_showAllPeople),
                ),
                const SizedBox(height: 18),
                RosterPreviewSigners(
                  signers: _signers,
                  busy: _busy,
                  ready: _signaturesReady,
                  expanded: _showSigners,
                  onToggle: () => setState(() => _showSigners = !_showSigners),
                  onEdit: _editSigner,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: RosterPreviewActions(
          hasRulePreview: hasRulePreview,
          ruleRowsEmpty: _ruleResult?.rows.isEmpty ?? false,
          busy: _busy,
          signaturesReady: _signaturesReady,
          onRulePreview: _previewRule,
          onRuleExport: () => _export(rule: true),
          onRankExport: () => _export(rankOrdered: true),
        ),
      ),
    );
  }
}
