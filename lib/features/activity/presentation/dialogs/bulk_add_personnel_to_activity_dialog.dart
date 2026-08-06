import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/add_personnel_dialog.dart';

part 'bulk_add_personnel_to_activity_actions.dart';

Future<ActivityAssignmentBatchResult?> showBulkAddPersonnelToActivityDialog(
  BuildContext context, {
  required GunlukFaaliyetTableData activity,
  required Set<int> existingPersonnelIds,
}) {
  return showDialog<ActivityAssignmentBatchResult>(
    context: context,
    builder: (context) => BulkAddPersonnelToActivityDialog(
      activity: activity,
      existingPersonnelIds: existingPersonnelIds,
    ),
  );
}

class BulkAddPersonnelToActivityDialog extends ConsumerStatefulWidget {
  const BulkAddPersonnelToActivityDialog({
    required this.activity,
    required this.existingPersonnelIds,
    super.key,
  });

  final GunlukFaaliyetTableData activity;
  final Set<int> existingPersonnelIds;

  @override
  ConsumerState<BulkAddPersonnelToActivityDialog> createState() =>
      _BulkAddPersonnelToActivityDialogState();
}

class _BulkAddPersonnelToActivityDialogState
    extends ConsumerState<BulkAddPersonnelToActivityDialog> {
  final _textController = TextEditingController();
  List<_ActivityImportRow> _rows = [];
  bool _previewReady = false;
  bool _parsing = false;
  bool _saving = false;
  String _defaultDuty = DutyOrLeaveType.gorevli;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateState(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) {
    final allPersonnel = ref.watch(allPersonnelProvider).valueOrNull ?? [];
    final session = ref.watch(userSessionProvider);
    final candidates = session?.isAdmin == true
        ? allPersonnel
        : allPersonnel
            .where((person) => person.timId == session?.timId)
            .toList(growable: false);
    final unresolvedCount =
        _rows.where((row) => !row.alreadyAssigned && !row.canSave).length;
    final saveableCount =
        _rows.where((row) => row.canSave && !row.alreadyAssigned).length;

    return AlertDialog(
      title: Text('${widget.activity.faaliyetAdi} – Metinden Personel Ekle'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('activity-bulk-personnel-text'),
                controller: _textController,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText:
                      'İsim listesini veya görev başlıklarını yapıştırın',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() => _previewReady = false),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                menuMaxHeight: modernDropdownMenuMaxHeight(context),
                borderRadius: modernDropdownBorderRadius,
                dropdownColor: modernDropdownColor(context),
                key: const Key('activity-bulk-default-duty'),
                initialValue: _defaultDuty,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Varsayılan görev'),
                items: kActivityAssignmentDuties
                    .map(
                      (duty) => DropdownMenuItem(
                        value: duty,
                        child: Text(duty),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _defaultDuty = value;
                    _rows = [
                      for (final row in _rows) row.copyWith(duty: value),
                    ];
                  });
                },
              ),
              if (_previewReady) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${_rows.length} satır • $saveableCount eklenebilir',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (unresolvedCount > 0)
                  Text(
                    '$unresolvedCount satır eşleştirme/onay bekliyor.',
                    style: TextStyle(color: context.pendingColor),
                  ),
                const SizedBox(height: AppSpacing.sm),
                ..._rows.asMap().entries.map((entry) {
                  final row = entry.value;
                  final person = row.personnel;
                  return Card(
                    key: Key('activity-bulk-row-${entry.key}'),
                    child: ExpansionTile(
                      initiallyExpanded: !row.canSave,
                      title: Text(person.rawName),
                      subtitle: Text(
                        row.alreadyAssigned
                            ? 'Bu faaliyette zaten ekli'
                            : person.isMatched
                                ? '${person.matchedRutbe ?? ''} ${person.matchedAdSoyad}'
                                : 'Personel bulunamadı',
                      ),
                      childrenPadding: const EdgeInsets.all(
                        AppSpacing.cardPadding,
                      ),
                      children: [
                        DropdownButtonFormField<int>(
                          menuMaxHeight: modernDropdownMenuMaxHeight(context),
                          borderRadius: modernDropdownBorderRadius,
                          dropdownColor: modernDropdownColor(context),
                          key: Key('activity-bulk-match-${entry.key}'),
                          initialValue: person.matchedPersonnelId,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Personel'),
                          items: candidates
                              .where(
                                (candidate) =>
                                    candidate.id == person.matchedPersonnelId ||
                                    !widget.existingPersonnelIds
                                        .contains(candidate.id),
                              )
                              .map(
                                (candidate) => DropdownMenuItem(
                                  value: candidate.id,
                                  child: Text(
                                    '${candidate.rutbe} ${candidate.adSoyad}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: row.alreadyAssigned
                              ? null
                              : (id) {
                                  final selected = candidates
                                      .where((candidate) => candidate.id == id)
                                      .firstOrNull;
                                  if (selected == null) return;
                                  _updateRow(
                                    entry.key,
                                    row.copyWith(
                                      personnel: ParsedPersonnelItem(
                                        rawIndex: person.rawIndex,
                                        rawRank: person.rawRank,
                                        rawName: person.rawName,
                                        matchedPersonnelId: selected.id,
                                        matchedAdSoyad: selected.adSoyad,
                                        matchedRutbe: selected.rutbe,
                                        matchedTimId: selected.timId,
                                        matchConfidence: 1,
                                        reviewConfirmed: true,
                                        sourceLineNumber:
                                            person.sourceLineNumber,
                                      ),
                                    ),
                                  );
                                },
                        ),
                        if (!person.isMatched) ...[
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () => _quickCreate(entry.key),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Yeni Personel Oluştur'),
                          ),
                        ],
                        if (person.isMatched && person.needsReview) ...[
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton.tonalIcon(
                            onPressed: () => _updateRow(
                              entry.key,
                              row.copyWith(
                                personnel: person.copyWith(
                                  matchConfidence: 1,
                                  reviewConfirmed: true,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Eşleşmeyi Onayla'),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          menuMaxHeight: modernDropdownMenuMaxHeight(context),
                          borderRadius: modernDropdownBorderRadius,
                          dropdownColor: modernDropdownColor(context),
                          key: Key('activity-bulk-duty-${entry.key}'),
                          initialValue: row.duty,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Görev / İzin'),
                          items: kActivityAssignmentDuties
                              .map(
                                (duty) => DropdownMenuItem(
                                  value: duty,
                                  child: Text(duty),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _updateRow(
                                entry.key,
                                row.copyWith(duty: value),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          key: Key('activity-bulk-note-${entry.key}'),
                          initialValue: row.note,
                          decoration: const InputDecoration(labelText: 'Not'),
                          onChanged: (value) => _updateRow(
                            entry.key,
                            row.copyWith(note: value),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('İPTAL'),
        ),
        if (!_previewReady)
          FilledButton.icon(
            key: const Key('activity-bulk-preview-button'),
            onPressed:
                _parsing || _textController.text.trim().isEmpty ? null : _parse,
            icon: _parsing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.preview_outlined),
            label: const Text('ÖNİZLE'),
          )
        else
          FilledButton.icon(
            key: const Key('activity-bulk-save-button'),
            onPressed: unresolvedCount > 0 || saveableCount == 0 || _saving
                ? null
                : _save,
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: const Text('FAALİYETE EKLE'),
          ),
      ],
    );
  }
}

class _ActivityImportRow {
  const _ActivityImportRow({
    required this.personnel,
    required this.duty,
    this.note = '',
    this.alreadyAssigned = false,
  });

  final ParsedPersonnelItem personnel;
  final String duty;
  final String note;
  final bool alreadyAssigned;

  bool get canSave =>
      personnel.matchedPersonnelId != null && !personnel.needsReview;

  _ActivityImportRow copyWith({
    ParsedPersonnelItem? personnel,
    String? duty,
    String? note,
  }) {
    return _ActivityImportRow(
      personnel: personnel ?? this.personnel,
      duty: duty ?? this.duty,
      note: note ?? this.note,
      alreadyAssigned: alreadyAssigned,
    );
  }
}
