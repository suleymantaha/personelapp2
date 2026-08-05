import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:personelapp2/features/personnel/domain/personnel_import_draft.dart';

Future<PersonnelImportResult?> showBulkPersonnelImportDialog(
  BuildContext context,
) {
  return showDialog<PersonnelImportResult>(
    context: context,
    builder: (context) => const BulkPersonnelImportDialog(),
  );
}

class BulkPersonnelImportDialog extends ConsumerStatefulWidget {
  const BulkPersonnelImportDialog({super.key});

  @override
  ConsumerState<BulkPersonnelImportDialog> createState() =>
      _BulkPersonnelImportDialogState();
}

class _BulkPersonnelImportDialogState
    extends ConsumerState<BulkPersonnelImportDialog> {
  final _textController = TextEditingController();
  List<PersonnelImportDraft> _items = [];
  List<BulkParseIssue> _issues = [];
  int? _selectedSquadId;
  bool _previewReady = false;
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _parse() {
    final result = BulkTextParser.parsePersonnelList(_textController.text);
    final squads = ref.read(allSquadsProvider).valueOrNull ?? [];
    final selectedSquad =
        squads.where((squad) => squad.id == _selectedSquadId).firstOrNull;
    final initialUnit = selectedSquad == null
        ? ''
        : MilitaryStructureHelper.getBolukName(selectedSquad.timAdi);
    setState(() {
      _items = result.personnel
          .map(
            (item) => PersonnelImportDraft(
              name: item.rawName,
              rank: item.rawRank,
              unit: initialUnit,
              squadId: _selectedSquadId,
              sourceLineNumber: item.sourceLineNumber,
            ),
          )
          .toList(growable: false);
      _issues = result.issues;
      _previewReady = true;
    });
  }

  void _updateItem(int index, PersonnelImportDraft item) {
    setState(() {
      _items = List.of(_items)..[index] = item;
    });
  }

  Future<void> _save() async {
    if (_items.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final entries = _items
          .map(
            (item) => PersonnelImportEntry(
              adSoyad: item.name,
              rutbe: item.rank,
              birlik: item.unit,
              timId: item.squadId,
            ),
          )
          .toList(growable: false);
      final result =
          await ref.read(personnelRepositoryProvider).importPersonnelBatch(
                entries,
                kayitTarihi: DateFormat('yyyy-MM-dd').format(DateTime.now()),
              );
      ref.invalidate(allPersonnelProvider);
      if (mounted) Navigator.of(context).pop(result);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final squads = ref.watch(allSquadsProvider).valueOrNull ?? [];
    final existingPersonnel =
        ref.watch(allPersonnelProvider).valueOrNull ?? const [];
    final unknownRankCount =
        _items.where((item) => item.rank.trim().isEmpty).length;
    final invalidCount = _items.where((item) => !item.isValid).length;
    final seenKeys = existingPersonnel
        .map((person) => _draftKey(person.adSoyad, person.rutbe))
        .toSet();
    final duplicateIndexes = <int>{};
    for (final entry in _items.asMap().entries) {
      if (!seenKeys.add(_draftKey(entry.value.name, entry.value.rank))) {
        duplicateIndexes.add(entry.key);
      }
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.content_paste_go_rounded),
          SizedBox(width: AppSpacing.iconTextGap),
          Expanded(child: Text('Metinden Personel Ekle')),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('bulk-personnel-text-field'),
                controller: _textController,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Personel listesini yapıştırın',
                  hintText: '1. J.Asb.Çvş. Ahmet YILMAZ\n'
                      '2. J.Uzm.Çvş. Mehmet DEMİR',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) {
                  setState(() => _previewReady = false);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int?>(
                key: const Key('bulk-personnel-squad-field'),
                initialValue: _selectedSquadId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Hedef tim'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tim dışı'),
                  ),
                  ...squads.map(
                    (squad) => DropdownMenuItem<int?>(
                      value: squad.id,
                      child: Text(squad.timAdi),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _selectedSquadId = value;
                  final selectedSquad =
                      squads.where((squad) => squad.id == value).firstOrNull;
                  final unit = selectedSquad == null
                      ? ''
                      : MilitaryStructureHelper.getBolukName(
                          selectedSquad.timAdi,
                        );
                  _items = [
                    for (final item in _items)
                      item.copyWith(
                        squadId: value,
                        clearSquad: value == null,
                        unit: unit,
                      ),
                  ];
                }),
              ),
              if (_previewReady) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${_items.length} personel bulundu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (unknownRankCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      '$unknownRankCount satırda rütbe bulunamadı. Kaydetmeden önce seçin.',
                      style: TextStyle(color: context.pendingColor),
                    ),
                  ),
                if (_issues.any((issue) => issue.isBlocking))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      '${_issues.where((issue) => issue.isBlocking).length} satır okunamadı ve eklenmeyecek.',
                      style: TextStyle(color: context.rejectedColor),
                    ),
                  ),
                if (duplicateIndexes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      '${duplicateIndexes.length} mükerrer satır kayıtta atlanacak.',
                      style: TextStyle(color: context.pendingColor),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                ..._items.asMap().entries.map(
                      (entry) => Card(
                        key: Key('bulk-personnel-preview-${entry.key}'),
                        child: ExpansionTile(
                          initiallyExpanded: !entry.value.isValid,
                          title: Text(
                            entry.value.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            duplicateIndexes.contains(entry.key)
                                ? 'Mükerrer kayıt • Atlanacak'
                                : entry.value.rank.isEmpty
                                    ? 'Rütbe seçilmeli'
                                    : entry.value.rank,
                          ),
                          trailing: IconButton(
                            tooltip: 'Listeden çıkar',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() {
                              _items = List.of(_items)..removeAt(entry.key);
                            }),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            AppSpacing.cardPadding,
                            0,
                            AppSpacing.cardPadding,
                            AppSpacing.cardPadding,
                          ),
                          children: [
                            TextFormField(
                              key: Key('bulk-personnel-name-${entry.key}'),
                              initialValue: entry.value.name,
                              decoration:
                                  const InputDecoration(labelText: 'Ad Soyad'),
                              onChanged: (value) => _updateItem(
                                entry.key,
                                entry.value.copyWith(name: value),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<String>(
                              key: Key('bulk-personnel-rank-${entry.key}'),
                              initialValue: entry.value.rank.isEmpty
                                  ? null
                                  : entry.value.rank,
                              isExpanded: true,
                              decoration:
                                  const InputDecoration(labelText: 'Rütbe'),
                              items: kAskeriRutbeler
                                  .map(
                                    (rank) => DropdownMenuItem(
                                      value: rank,
                                      child: Text(rank),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _updateItem(
                                    entry.key,
                                    entry.value.copyWith(rank: value),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              key: Key('bulk-personnel-unit-${entry.key}'),
                              initialValue: entry.value.unit,
                              decoration:
                                  const InputDecoration(labelText: 'Birlik'),
                              onChanged: (value) => _updateItem(
                                entry.key,
                                entry.value.copyWith(unit: value),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<int?>(
                              key: Key('bulk-personnel-squad-${entry.key}'),
                              initialValue: entry.value.squadId,
                              isExpanded: true,
                              decoration:
                                  const InputDecoration(labelText: 'Tim'),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Tim dışı'),
                                ),
                                ...squads.map(
                                  (squad) => DropdownMenuItem<int?>(
                                    value: squad.id,
                                    child: Text(squad.timAdi),
                                  ),
                                ),
                              ],
                              onChanged: (value) => _updateItem(
                                entry.key,
                                entry.value.copyWith(
                                  squadId: value,
                                  clearSquad: value == null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
            key: const Key('bulk-personnel-preview-button'),
            onPressed: _textController.text.trim().isEmpty ? null : _parse,
            icon: const Icon(Icons.preview_outlined),
            label: const Text('ÖNİZLE'),
          )
        else
          FilledButton.icon(
            key: const Key('bulk-personnel-save-button'),
            onPressed:
                _items.isEmpty || invalidCount > 0 || _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_rounded),
            label: Text(_saving ? 'KAYDEDİLİYOR' : 'KAYDET'),
          ),
      ],
    );
  }

  static String _draftKey(String name, String rank) {
    String fold(String value) => value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ');
    return '${fold(normalizeRank(rank))}|${fold(name)}';
  }
}
