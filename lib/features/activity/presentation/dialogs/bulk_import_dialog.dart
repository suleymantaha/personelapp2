import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_activity_import_preparer.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/conflict_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/widgets/personnel_picker_sheet.dart';

enum _BulkPreviewFilter { all, problems }

class BulkImportDialog extends ConsumerStatefulWidget {
  const BulkImportDialog({
    required this.database,
    required this.activityRepository,
    super.key,
  });
  final AppDatabase database;
  final ActivityRepository activityRepository;

  @override
  ConsumerState<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends ConsumerState<BulkImportDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  List<ParsedActivityBlock> _parsedBlocks = [];
  List<BulkParseIssue> _parseIssues = [];
  List<PersonelTableData> _allPersonnel = [];
  List<TimTableData> _allSquads = [];
  bool _isParsing = false;
  bool _isSaving = false;
  int _ignoredLineCount = 0;
  int _deduplicatedPersonnelCount = 0;
  bool _parseIssuesExpanded = false;
  _BulkPreviewFilter _previewFilter = _BulkPreviewFilter.all;
  final ScrollController _previewScrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_loadPersonnel());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  void _setPreviewFilter(_BulkPreviewFilter filter) {
    setState(() {
      _previewFilter = filter;
      if (filter == _BulkPreviewFilter.problems &&
          _parseIssues.any((issue) => issue.isBlocking)) {
        _parseIssuesExpanded = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_previewScrollController.hasClients) return;
      _previewScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadPersonnel() async {
    final list =
        await widget.database.select(widget.database.personelTable).get();
    final squads = await widget.database.select(widget.database.timTable).get();
    if (!mounted) return;
    setState(() {
      _allPersonnel = list;
      _allSquads = squads;
    });
  }

  Future<void> _processText() async {
    final rawText = _textController.text;
    if (rawText.trim().isEmpty) return;

    setState(() {
      _isParsing = true;
    });

    try {
      final parseResult = BulkTextParser.parse(rawText);
      final fuzzyMatcher = PersonnelFuzzyMatcher(widget.database);
      final matchedBlocks = await fuzzyMatcher.matchBlocks(parseResult.blocks);
      final deduplicated = _deduplicateSameDuty(matchedBlocks);
      if (!mounted) return;

      setState(() {
        _parsedBlocks = deduplicated.blocks;
        _parseIssues = parseResult.issues;
        _ignoredLineCount = parseResult.ignoredLineCount;
        _deduplicatedPersonnelCount = deduplicated.removedCount;
        _previewFilter = _BulkPreviewFilter.all;
        _parseIssuesExpanded = _parseIssues.any((issue) => issue.isBlocking);
        if (_parsedBlocks.isNotEmpty || _parseIssues.isNotEmpty) {
          _tabController.animateTo(
            1,
          ); // Auto switch to Preview tab on mobile/desktop
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isParsing = false;
        });
      }
    }
  }

  Future<void> _saveAllToFaaliyet() async {
    if (_parsedBlocks.isEmpty ||
        _parseIssues.any((issue) => issue.isBlocking) ||
        _unresolvedPersonnelCount > 0 ||
        _parsedBlocks.any((block) => block.personnelList.isEmpty)) {
      return;
    }

    final preparation = BulkActivityImportPreparer.prepare(_parsedBlocks);
    if (preparation.duplicates.isNotEmpty) {
      await _showDuplicatePersonnelDialog(preparation.duplicates);
      if (!mounted) return;
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final actor = ref.read(userSessionProvider);
      if (actor == null) {
        throw StateError('Oturum doğrulanamadı.');
      }
      final result =
          await widget.activityRepository.createActivitiesWithAssignments(
        preparation.requests,
        actor: actor,
      );

      if (mounted) {
        if (result.skippedAssignmentCount > 0) {
          await showDialog<void>(
            context: context,
            builder: (_) => ConflictPersonnelDialog(
              descriptions: result.conflictDescriptions,
            ),
          );
          if (!mounted) return;
        }
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_parsedBlocks.length} blok → ${preparation.requests.length} '
              'günlük faaliyet, ${result.addedAssignmentCount} personel '
              'başarıyla eklendi.',
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showDuplicatePersonnelDialog(
    List<BulkImportDuplicate> duplicates,
  ) {
    final squadNames = {for (final squad in _allSquads) squad.id: squad.timAdi};
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tekrarlanan Personel Var'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aynı personel aynı tarihte birden fazla görevde bulunuyor. '
                  'Aktarmadan önce önizlemedeki tekrarları düzeltin.',
                ),
                const SizedBox(height: 12),
                for (final duplicate in duplicates)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: Text(duplicate.personnelName),
                    subtitle: Text(
                      '${duplicate.date} • '
                      '${squadNames[duplicate.teamId] ?? 'Timsiz'}\n'
                      '${duplicate.assignments.join(' / ')}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ÖNİZLEMEYE DÖN'),
          ),
        ],
      ),
    );
  }

  Map<String, List<String>> _duplicateAssignments() {
    final occurrences = <String, List<({int blockIndex, int personIndex})>>{};
    for (final blockEntry in _parsedBlocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final id = personEntry.value.matchedPersonnelId;
        if (id == null) continue;
        final key = '${blockEntry.value.parsedDate}:$id';
        occurrences.putIfAbsent(key, () => []).add(
          (blockIndex: blockEntry.key, personIndex: personEntry.key),
        );
      }
    }

    final result = <String, List<String>>{};
    for (final entries
        in occurrences.values.where((items) => items.length > 1)) {
      for (final entry in entries) {
        result['${entry.blockIndex}:${entry.personIndex}'] =
            entries.where((other) => other != entry).map((other) {
          final block = _parsedBlocks[other.blockIndex];
          final time = block.parsedTimeRange?.trim();
          return time == null || time.isEmpty
              ? block.parsedActivityType
              : '${block.parsedActivityType} ($time)';
        }).toList(growable: false);
      }
    }
    return result;
  }

  ({
    List<ParsedActivityBlock> blocks,
    int removedCount,
  }) _deduplicateSameDuty(List<ParsedActivityBlock> blocks) {
    final seen = <String>{};
    var removedCount = 0;
    final result = <ParsedActivityBlock>[];
    for (final block in blocks) {
      final personnel = <ParsedPersonnelItem>[];
      for (final person in block.personnelList) {
        final id = person.matchedPersonnelId;
        if (id == null) {
          personnel.add(person);
          continue;
        }
        final key = '${block.parsedDate}:'
            '${block.parsedActivityType.trim().toUpperCase()}:$id';
        if (seen.add(key)) {
          personnel.add(person);
        } else {
          removedCount++;
        }
      }
      result.add(block.copyWith(personnelList: personnel));
    }
    return (blocks: result, removedCount: removedCount);
  }

  int get _unresolvedPersonnelCount => _parsedBlocks
      .expand((block) => block.personnelList)
      .where((person) => person.needsReview)
      .length;

  Future<void> _removePerson(int blockIndex, int personIndex) async {
    final block = _parsedBlocks[blockIndex];
    final removed = block.personnelList[personIndex];
    final updated = List<ParsedPersonnelItem>.from(block.personnelList)
      ..removeAt(personIndex);
    setState(() {
      _parsedBlocks[blockIndex] = block.copyWith(personnelList: updated);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.rawRank} ${removed.rawName} kaldırıldı.'),
        action: SnackBarAction(
          label: 'GERİ AL',
          onPressed: () {
            if (!mounted || blockIndex >= _parsedBlocks.length) return;
            setState(() {
              final current = _parsedBlocks[blockIndex];
              final restored =
                  List<ParsedPersonnelItem>.from(current.personnelList);
              restored.insert(personIndex.clamp(0, restored.length), removed);
              _parsedBlocks[blockIndex] =
                  current.copyWith(personnelList: restored);
            });
          },
        ),
      ),
    );
  }

  void _removeBlock(int blockIndex) {
    final removed = _parsedBlocks[blockIndex];
    setState(() => _parsedBlocks.removeAt(blockIndex));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.parsedActivityType} kartı kaldırıldı.'),
        action: SnackBarAction(
          label: 'GERİ AL',
          onPressed: () {
            if (!mounted) return;
            setState(
              () => _parsedBlocks.insert(
                blockIndex.clamp(0, _parsedBlocks.length),
                removed,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Önizlemeyi temizle?'),
        content: const Text(
          'Oluşturulan tüm kartlar ve ayrıştırma uyarıları kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('TEMİZLE'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _parsedBlocks.clear();
        _parseIssues.clear();
        _previewFilter = _BulkPreviewFilter.all;
        _parseIssuesExpanded = false;
        _ignoredLineCount = 0;
        _deduplicatedPersonnelCount = 0;
      });
    }
  }

  Future<void> _editBlock(int blockIndex) async {
    final block = _parsedBlocks[blockIndex];
    final activityController =
        TextEditingController(text: block.parsedActivityType);
    final timeController = TextEditingController(text: block.parsedTimeRange);
    var selectedDate = DateTime.tryParse(block.parsedDate) ?? DateTime.now();
    final updated = await showModalBottomSheet<ParsedActivityBlock>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Faaliyet kartını düzenle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextField(
                key: const Key('bulk-edit-activity'),
                controller: activityController,
                decoration: const InputDecoration(
                  labelText: 'Görev / faaliyet adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('bulk-edit-time'),
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Saat aralığı (isteğe bağlı)',
                  hintText: '08:00 - 19:30',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setSheetState(() => selectedDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(
                  '${selectedDate.day.toString().padLeft(2, '0')}.'
                  '${selectedDate.month.toString().padLeft(2, '0')}.'
                  '${selectedDate.year}',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('bulk-edit-save'),
                onPressed: () {
                  final activity = activityController.text.trim();
                  if (activity.isEmpty) return;
                  final time = timeController.text.trim();
                  Navigator.pop(
                    sheetContext,
                    ParsedActivityBlock(
                      rawTitle: block.rawTitle,
                      parsedTimName: block.parsedTimName,
                      parsedActivityType: activity,
                      parsedDate:
                          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                      parsedTimeRange: time.isEmpty ? null : time,
                      personnelList: block.personnelList,
                    ),
                  );
                },
                child: const Text('DEĞİŞİKLİKLERİ UYGULA'),
              ),
            ],
          ),
        ),
      ),
    );
    activityController.dispose();
    timeController.dispose();
    if (updated != null && mounted && blockIndex < _parsedBlocks.length) {
      setState(() => _parsedBlocks[blockIndex] = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isKeyboardVisible ? 8 : (isMobile ? 24 : 32),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1180,
                maxHeight: mediaQuery.size.height * 0.9,
              ),
              child: SizedBox(
                width: isMobile
                    ? constraints.maxWidth
                    : constraints.maxWidth * 0.85,
                height: double.infinity,
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      // Dialog Header Banner
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: isKeyboardVisible ? 10 : 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.accentOrOlive,
                              context.accentOrOlive.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.paste_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Metinden Toplu Aktarım',
                                    style: TextStyle(
                                      fontSize: isKeyboardVisible ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (!isKeyboardVisible) ...[
                                    const SizedBox(height: 2),
                                    const Text(
                                      'WhatsApp / Telegram nöbet listelerini yapıştırıp akıllı ayrıştırın',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // TabBar for Mobile or Split Layout for Desktop/Tablet
                      if (isMobile)
                        TabBar(
                          controller: _tabController,
                          labelColor: context.accentOrOlive,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: context.accentOrOlive,
                          indicatorWeight: 3,
                          tabs: [
                            Tab(
                              icon: isKeyboardVisible
                                  ? null
                                  : const Icon(Icons.text_fields),
                              text: '1. Metin Yapıştır',
                            ),
                            Tab(
                              icon: isKeyboardVisible
                                  ? null
                                  : Badge(
                                      isLabelVisible: _parsedBlocks.isNotEmpty,
                                      label:
                                          Text(_parsedBlocks.length.toString()),
                                      child: const Icon(Icons.preview_rounded),
                                    ),
                              text: '2. Kart Önizleme',
                            ),
                          ],
                        ),

                      // Main Body Content
                      Expanded(
                        child: isMobile
                            ? TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildInputSection(
                                    isMobile: true,
                                    isKeyboardVisible: isKeyboardVisible,
                                  ),
                                  _buildPreviewSection(isMobile: true),
                                ],
                              )
                            : Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: _buildInputSection(
                                        isMobile: false,
                                        isKeyboardVisible: isKeyboardVisible,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    const VerticalDivider(width: 1),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 6,
                                      child:
                                          _buildPreviewSection(isMobile: false),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection({
    required bool isMobile,
    required bool isKeyboardVisible,
  }) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? (isKeyboardVisible ? 12 : 16) : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: context.accentOrOlive,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ham Metni Yapıştırın:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          if (!isKeyboardVisible) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: context.accentOrOlive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tarih, görev türü ve personel listesini içeren mesajı '
                'olduğu gibi yapıştırabilirsiniz.',
                style: TextStyle(
                  color: context.accentOrOlive,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
          SizedBox(height: isKeyboardVisible ? 8 : 10),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 13, height: 1.4),
              cursorColor: context.accentOrOlive,
              scrollPadding: const EdgeInsets.only(bottom: 80),
              decoration: InputDecoration(
                hintText: 'Mesaj metnini buraya yapıştırın…',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.cardBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.cardBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: context.accentOrOlive,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isParsing ? null : _processText,
              icon: _isParsing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                'Metni Ayrıştır ve Kartları Oluştur',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentOrOlive,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection({required bool isMobile}) {
    final duplicates = _duplicateAssignments();
    final problemPersonnelByBlock = <int, List<int>>{};
    for (final blockEntry in _parsedBlocks.asMap().entries) {
      final problemIndexes = <int>[];
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        if (personEntry.value.needsReview ||
            duplicates.containsKey('${blockEntry.key}:${personEntry.key}')) {
          problemIndexes.add(personEntry.key);
        }
      }
      if (problemIndexes.isNotEmpty || blockEntry.value.personnelList.isEmpty) {
        problemPersonnelByBlock[blockEntry.key] = problemIndexes;
      }
    }
    final visibleBlocks = _parsedBlocks.asMap().entries.where((entry) {
      return _previewFilter == _BulkPreviewFilter.all ||
          problemPersonnelByBlock.containsKey(entry.key);
    }).toList(growable: false);
    final personnelCount = _parsedBlocks.fold<int>(
      0,
      (count, block) => count + block.personnelList.length,
    );
    final problemCount = duplicates.length +
        _unresolvedPersonnelCount +
        _parsedBlocks.where((block) => block.personnelList.isEmpty).length +
        _parseIssues.where((issue) => issue.isBlocking).length;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.style_rounded,
                      color: context.accentOrOlive,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Faaliyet Kartları (${_parsedBlocks.length})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_parsedBlocks.isNotEmpty || _parseIssues.isNotEmpty)
                IconButton(
                  onPressed: _confirmClearAll,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  tooltip: 'Tümünü Temizle',
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_parsedBlocks.isNotEmpty) ...[
            _ImportSummary(
              cardCount: _parsedBlocks.length,
              personnelCount: personnelCount,
              warningCount: _parseIssues.length,
              problemCount: problemCount,
              ignoredLineCount: _ignoredLineCount,
              deduplicatedCount: _deduplicatedPersonnelCount,
              selectedFilter: _previewFilter,
              onShowAll: () => _setPreviewFilter(_BulkPreviewFilter.all),
              onShowProblems: problemCount == 0
                  ? null
                  : () => _setPreviewFilter(_BulkPreviewFilter.problems),
              onToggleWarnings: _parseIssues.isEmpty
                  ? null
                  : () => setState(
                        () => _parseIssuesExpanded = !_parseIssuesExpanded,
                      ),
            ),
            const SizedBox(height: 10),
          ],
          if (_parseIssues.isNotEmpty) ...[
            _buildParseIssues(),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: _parsedBlocks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  context.accentOrOlive.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.fact_check_outlined,
                              size: 48,
                              color: context.accentOrOlive,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz Kart Oluşturulmadı',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Soldaki kutuya mesajı yapıştırıp "Metni Ayrıştır" butonuna basın.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : visibleBlocks.isEmpty
                    ? _buildFilteredEmptyState()
                    : ListView.builder(
                        controller: _previewScrollController,
                        itemCount: visibleBlocks.length,
                        itemBuilder: (context, blockIdx) {
                          final entry = visibleBlocks[blockIdx];
                          final originalBlockIndex = entry.key;
                          final block = entry.value;
                          return _buildPreviewCard(
                            block,
                            originalBlockIndex,
                            duplicates,
                            visiblePersonnelIndexes: _previewFilter ==
                                    _BulkPreviewFilter.problems
                                ? problemPersonnelByBlock[originalBlockIndex]
                                : null,
                          );
                        },
                      ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (problemCount > 0) ...[
                    Semantics(
                      button: true,
                      label: '$problemCount sorunu göster',
                      child: InkWell(
                        key: const Key('bulk-import-problem-message'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            _setPreviewFilter(_BulkPreviewFilter.problems),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$problemCount sorun çözülmeden kayıt yapılamaz.',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.filter_alt_outlined,
                                size: 18,
                                color: Colors.red.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    height: 56,
                    child: BulkImportSaveButton(
                      blocks: _parsedBlocks,
                      issues: _parseIssues,
                      hasUnresolvedProblems: duplicates.isNotEmpty ||
                          _unresolvedPersonnelCount > 0 ||
                          _parsedBlocks
                              .any((block) => block.personnelList.isEmpty),
                      isSaving: _isSaving,
                      onPressed: _saveAllToFaaliyet,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    final hasBlockingParseIssue = _parseIssues.any((issue) => issue.isBlocking);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasBlockingParseIssue
                  ? Icons.rule_folder_outlined
                  : Icons.task_alt_rounded,
              size: 52,
              color: hasBlockingParseIssue
                  ? Colors.orange.shade800
                  : context.approvedColor,
            ),
            const SizedBox(height: 12),
            Text(
              hasBlockingParseIssue
                  ? 'Kartlara bağlı sorun kalmadı'
                  : 'Tüm kart sorunları çözüldü',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasBlockingParseIssue
                  ? 'Kalan kritik ayrıştırma sorunlarını yukarıdaki uyarı panelinden inceleyin.'
                  : 'İsterseniz tüm faaliyet kartlarına geri dönebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const Key('bulk-filter-show-all'),
              onPressed: () => _setPreviewFilter(_BulkPreviewFilter.all),
              icon: const Icon(Icons.view_list_outlined),
              label: const Text('TÜM KARTLARI GÖSTER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParseIssues() {
    final blockingCount =
        _parseIssues.where((issue) => issue.isBlocking).length;
    final color =
        blockingCount > 0 ? Colors.red.shade700 : Colors.orange.shade800;
    return Card(
      key: const Key('bulk-parse-issues'),
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        key: ValueKey('bulk-parse-expanded-$_parseIssuesExpanded'),
        initiallyExpanded: _parseIssuesExpanded,
        onExpansionChanged: (expanded) {
          if (_parseIssuesExpanded != expanded) {
            setState(() => _parseIssuesExpanded = expanded);
          }
        },
        leading: Icon(
          blockingCount > 0
              ? Icons.error_outline_rounded
              : Icons.warning_amber_rounded,
          color: color,
        ),
        title: Text(
          blockingCount > 0
              ? '$blockingCount kritik sorun'
              : '${_parseIssues.length} ayrıştırma uyarısı',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          blockingCount > 0
              ? 'Kayıt engellendi; ayrıntıları inceleyin.'
              : 'Kayıt yapılabilir; ayrıntıları kontrol edin.',
          style: TextStyle(color: color, fontSize: 12),
        ),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: _parseIssues.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final issue = _parseIssues[index];
                return Text(
                  '${issue.lineNumber > 0 ? 'Satır ${issue.lineNumber}: ' : ''}'
                  '${issue.message}'
                  '${issue.rawLine.trim().isEmpty ? '' : '\n${issue.rawLine.trim()}'}',
                  style: TextStyle(color: color, fontSize: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    ParsedActivityBlock block,
    int blockIdx,
    Map<String, List<String>> duplicates, {
    List<int>? visiblePersonnelIndexes,
  }) {
    final personnelIndexes = visiblePersonnelIndexes ??
        List<int>.generate(block.personnelList.length, (index) => index);
    final problemCount =
        block.personnelList.isEmpty ? 1 : visiblePersonnelIndexes?.length ?? 0;
    return Card(
      key: Key('bulk-preview-card-$blockIdx'),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.cardBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.accentOrOlive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    block.parsedTimName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.accentOrOlive,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.parsedActivityType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _MetadataLabel(
                            icon: Icons.calendar_today_rounded,
                            text: block.parsedDate,
                          ),
                          if (block.parsedTimeRange?.trim().isNotEmpty == true)
                            _MetadataLabel(
                              icon: Icons.schedule_rounded,
                              text: block.parsedTimeRange!,
                            ),
                          _MetadataLabel(
                            icon: Icons.people_outline_rounded,
                            text: visiblePersonnelIndexes == null
                                ? '${block.personnelList.length} personel'
                                : '$problemCount sorun / '
                                    '${block.personnelList.length} personel',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  key: Key('bulk-card-menu-$blockIdx'),
                  tooltip: 'Kart işlemleri',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editBlock(blockIdx);
                    } else if (value == 'delete') {
                      _removeBlock(blockIdx);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Kartı düzenle'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(Icons.delete_outline, color: Colors.redAccent),
                        title: Text('Kartı sil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            if (block.personnelList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Bu kartta personel kalmadı. Kartı silin veya metni yeniden ayrıştırın.',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: personnelIndexes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, visibleIndex) {
                  final pIdx = personnelIndexes[visibleIndex];
                  final item = block.personnelList[pIdx];
                  final duplicateWith = duplicates['$blockIdx:$pIdx'];
                  return _PersonnelMatchCard(
                    key: Key('bulk-person-$blockIdx-$pIdx'),
                    item: item,
                    teamName: _allSquads
                            .where((team) => team.id == item.matchedTimId)
                            .map((team) => team.timAdi)
                            .firstOrNull ??
                        'Tim bilgisi yok',
                    duplicateAssignments: duplicateWith,
                    onSelect: () => _selectPersonnel(blockIdx, pIdx),
                    onDelete: () => _removePerson(blockIdx, pIdx),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPersonnel(int blockIndex, int personIndex) async {
    final block = _parsedBlocks[blockIndex];
    final item = block.personnelList[personIndex];
    final normalizedTeam = block.parsedTimName
        .toLowerCase()
        .replaceAll('timi', '')
        .replaceAll(' ', '');
    final preferredTeamId = _allSquads
        .where(
          (team) => team.timAdi
              .toLowerCase()
              .replaceAll('timi', '')
              .replaceAll(' ', '')
              .contains(normalizedTeam),
        )
        .map((team) => team.id)
        .firstOrNull;
    final disabledReasons = <int, String>{};
    for (final otherBlock in _parsedBlocks) {
      if (otherBlock.parsedDate != block.parsedDate) continue;
      for (final person in otherBlock.personnelList) {
        final id = person.matchedPersonnelId;
        if (id == null || id == item.matchedPersonnelId) continue;
        disabledReasons[id] = otherBlock.parsedActivityType;
      }
    }
    final person = await showPersonnelPicker(
      context: context,
      personnel: _allPersonnel,
      squads: _allSquads,
      selectedPersonnelId: item.matchedPersonnelId,
      preferredTimId: item.matchedTimId ?? preferredTeamId,
      disabledReasons: disabledReasons,
    );
    if (person != null &&
        mounted &&
        blockIndex < _parsedBlocks.length &&
        personIndex < _parsedBlocks[blockIndex].personnelList.length) {
      setState(() {
        final currentBlock = _parsedBlocks[blockIndex];
        final updatedList =
            List<ParsedPersonnelItem>.from(currentBlock.personnelList);
        updatedList[personIndex] = updatedList[personIndex].copyWith(
          matchedPersonnelId: person.id,
          matchedAdSoyad: person.adSoyad,
          matchedRutbe: person.rutbe,
          matchedTimId: person.timId,
          matchConfidence: 1,
          teamMismatch: false,
          reviewConfirmed: true,
        );
        _parsedBlocks[blockIndex] =
            currentBlock.copyWith(personnelList: updatedList);
      });
    }
  }
}

class BulkImportSaveButton extends StatelessWidget {
  const BulkImportSaveButton({
    required this.blocks,
    required this.issues,
    required this.isSaving,
    required this.onPressed,
    this.hasUnresolvedProblems = false,
    super.key,
  });

  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final bool isSaving;
  final VoidCallback onPressed;
  final bool hasUnresolvedProblems;

  @override
  Widget build(BuildContext context) {
    final isBlocked = issues.any((issue) => issue.isBlocking);
    return ElevatedButton.icon(
      key: const Key('bulk-import-save-button'),
      onPressed:
          blocks.isEmpty || isSaving || isBlocked || hasUnresolvedProblems
              ? null
              : onPressed,
      icon: isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_rounded),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Faaliyetleri Kaydet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            '${blocks.length} blok → '
            '${blocks.map((block) => block.parsedDate).toSet().length} günlük faaliyet',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.approvedColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({
    required this.cardCount,
    required this.personnelCount,
    required this.warningCount,
    required this.problemCount,
    required this.ignoredLineCount,
    required this.deduplicatedCount,
    required this.selectedFilter,
    required this.onShowAll,
    required this.onShowProblems,
    required this.onToggleWarnings,
  });

  final int cardCount;
  final int personnelCount;
  final int warningCount;
  final int problemCount;
  final int ignoredLineCount;
  final int deduplicatedCount;
  final _BulkPreviewFilter selectedFilter;
  final VoidCallback onShowAll;
  final VoidCallback? onShowProblems;
  final VoidCallback? onToggleWarnings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('bulk-import-summary'),
      spacing: 6,
      runSpacing: 6,
      children: [
        _SummaryChip(
          key: const Key('bulk-filter-all'),
          icon: Icons.style_outlined,
          label: '$cardCount kart',
          color: context.accentOrOlive,
          selected: selectedFilter == _BulkPreviewFilter.all,
          onTap: onShowAll,
        ),
        _SummaryChip(
          icon: Icons.people_outline,
          label: '$personnelCount personel',
          color: Colors.blue.shade700,
        ),
        if (deduplicatedCount > 0)
          _SummaryChip(
            icon: Icons.content_copy_outlined,
            label: '$deduplicatedCount tekrar birleştirildi',
            color: Colors.teal.shade700,
          ),
        if (ignoredLineCount > 0)
          _SummaryChip(
            icon: Icons.do_not_disturb_alt_outlined,
            label: '$ignoredLineCount satır/not yok sayıldı',
            color: Colors.blueGrey.shade700,
          ),
        if (warningCount > 0)
          _SummaryChip(
            key: const Key('bulk-toggle-warnings'),
            icon: Icons.warning_amber_rounded,
            label: '$warningCount uyarı',
            color: Colors.orange.shade800,
            onTap: onToggleWarnings,
          ),
        _SummaryChip(
          key: const Key('bulk-filter-problems'),
          icon: problemCount == 0
              ? Icons.check_circle_outline
              : Icons.error_outline,
          label: problemCount == 0 ? 'Hazır' : '$problemCount sorun',
          color:
              problemCount == 0 ? context.approvedColor : Colors.red.shade700,
          selected: selectedFilter == _BulkPreviewFilter.problems,
          onTap: onShowProblems,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

class _MetadataLabel extends StatelessWidget {
  const _MetadataLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class _PersonnelMatchCard extends StatelessWidget {
  const _PersonnelMatchCard({
    required this.item,
    required this.teamName,
    required this.onSelect,
    required this.onDelete,
    this.duplicateAssignments,
    super.key,
  });

  final ParsedPersonnelItem item;
  final String teamName;
  final List<String>? duplicateAssignments;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final duplicate = duplicateAssignments?.isNotEmpty == true;
    final problem = duplicate || item.needsReview;
    final borderColor = problem ? Colors.red.shade300 : context.cardBorderColor;
    return Container(
      decoration: BoxDecoration(
        color: problem
            ? Colors.red.withValues(alpha: 0.045)
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor:
                      context.accentOrOlive.withValues(alpha: 0.12),
                  child: Text(
                    '${item.rawIndex}',
                    style: TextStyle(
                      color: context.accentOrOlive,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LabeledValue(
                    label: 'METİNDEKİ KAYIT',
                    value: '${item.rawRank} ${item.rawName}',
                  ),
                ),
                IconButton(
                  key: const Key('bulk-person-delete'),
                  tooltip: 'Personeli kaldır',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 21,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            key: const Key('bulk-person-select'),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(52, 2, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LabeledValue(
                          label: 'EŞLEŞEN PERSONEL',
                          value: item.isMatched
                              ? '${item.matchedRutbe ?? ''} ${item.matchedAdSoyad}'
                                  .trim()
                              : 'Personel seçilmedi',
                          valueColor:
                              item.isMatched ? null : Colors.red.shade700,
                        ),
                        if (item.isMatched) ...[
                          const SizedBox(height: 2),
                          Text(
                            teamName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                          if (item.teamMismatch && !item.reviewConfirmed)
                            Text(
                              'Metindeki tim ile kayıtlı tim uyuşmuyor; '
                              'personeli seçerek onaylayın.',
                              key: const Key('bulk-team-mismatch-warning'),
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                        const SizedBox(height: 6),
                        if (duplicate)
                          Text(
                            'Aynı tarihte ayrıca: '
                            '${duplicateAssignments!.join(', ')}',
                            key: const Key('bulk-duplicate-warning'),
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          _MatchStatusIndicator(item: item),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 0.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MatchStatusIndicator extends StatelessWidget {
  const _MatchStatusIndicator({required this.item});

  final ParsedPersonnelItem item;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (item) {
      ParsedPersonnelItem(reviewConfirmed: true, isMatched: true) => (
          'Kullanıcı onayladı',
          context.approvedColor,
          Icons.verified_rounded,
        ),
      ParsedPersonnelItem(teamMismatch: true) => (
          'Tim onayı gerekli',
          Colors.orange.shade800,
          Icons.account_tree_outlined,
        ),
      ParsedPersonnelItem(matchConfidence: < 0.9, isMatched: true) => (
          'Eşleşmeyi kontrol edin',
          Colors.orange.shade800,
          Icons.help_rounded,
        ),
      ParsedPersonnelItem(matchConfidence: >= 0.9, isMatched: true) => (
          'Eşleşti',
          context.approvedColor,
          Icons.check_circle_rounded,
        ),
      _ => (
          'Eşleşmedi',
          Colors.red.shade700,
          Icons.warning_amber_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
