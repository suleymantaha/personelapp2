import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';

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
  List<ParsedPersonnelItem> _items = [];
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
    setState(() {
      _items = result.personnel;
      _issues = result.issues;
      _previewReady = true;
    });
  }

  Future<void> _save() async {
    if (_items.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final squads = ref.read(allSquadsProvider).valueOrNull ?? [];
      final selectedSquad =
          squads.where((squad) => squad.id == _selectedSquadId).firstOrNull;
      final unit = selectedSquad == null
          ? 'Asayiş Timi'
          : MilitaryStructureHelper.getBolukName(selectedSquad.timAdi);
      final entries = _items
          .map(
            (item) => PersonnelImportEntry(
              adSoyad: item.rawName,
              rutbe: item.rawRank.isEmpty ? 'J.Er' : item.rawRank,
              birlik: unit,
              timId: _selectedSquadId,
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
    final unknownRankCount =
        _items.where((item) => item.rawRank.isEmpty).length;

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
                onChanged: (value) => setState(() => _selectedSquadId = value),
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
                      '$unknownRankCount satırda rütbe bulunamadı; J.Er olarak kaydedilecek.',
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
                const SizedBox(height: AppSpacing.sm),
                ..._items.asMap().entries.map(
                      (entry) => Card(
                        key: Key('bulk-personnel-preview-${entry.key}'),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            child: Text('${entry.key + 1}'),
                          ),
                          title: Text(
                            entry.value.rawName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            entry.value.rawRank.isEmpty
                                ? 'J.Er (varsayılan)'
                                : entry.value.rawRank,
                          ),
                          trailing: IconButton(
                            tooltip: 'Listeden çıkar',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() {
                              _items = List.of(_items)..removeAt(entry.key);
                            }),
                          ),
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
            onPressed: _items.isEmpty || _saving ? null : _save,
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
}
