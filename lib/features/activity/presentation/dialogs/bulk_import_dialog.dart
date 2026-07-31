import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_activity_import_preparer.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_stat_cards.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_stepper.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/compact_error_summary.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/duplicate_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/conflict_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/widgets/personnel_picker_sheet.dart';
import 'package:personelapp2/features/activity/services/bulk_import_preferences.dart';

export 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart'
    show BulkImportSaveButton;

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

class _BulkImportDialogState extends ConsumerState<BulkImportDialog> {
  static const _preferences = BulkImportPreferences();
  final TextEditingController _textController = TextEditingController();
  List<ParsedActivityBlock> _parsedBlocks = [];
  List<BulkParseIssue> _parseIssues = [];
  List<PersonelTableData> _allPersonnel = [];
  List<TimTableData> _allSquads = [];
  bool _isParsing = false;
  bool _isSaving = false;
  int _deduplicatedPersonnelCount = 0;
  bool _keepAuditText = false;
  bool _keepAuditTextChanged = false;
  bool _parseIssuesExpanded = false;
  _BulkPreviewFilter _previewFilter = _BulkPreviewFilter.all;
  final ScrollController _previewScrollController = ScrollController();
  int _currentStep = 0; // 0: paste, 1: preview, 2: confirm (Faz 1)
  int _activeIssueFocusIndex = -1;
  String? _focusedPersonKey;
  final _cardKeys = <int, GlobalKey>{};

  List<({int blockIndex, int? personIndex})> _getProblemLocations() {
    final duplicates = _duplicateAssignments();
    final locs = <({int blockIndex, int? personIndex})>[];
    for (final blockEntry in _parsedBlocks.asMap().entries) {
      if (blockEntry.value.personnelList.isEmpty) {
        locs.add((blockIndex: blockEntry.key, personIndex: null));
        continue;
      }
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        if (personEntry.value.needsReview ||
            duplicates.containsKey('${blockEntry.key}:${personEntry.key}')) {
          locs.add((blockIndex: blockEntry.key, personIndex: personEntry.key));
        }
      }
    }
    return locs;
  }

  void _focusNextProblem() {
    final locs = _getProblemLocations();
    if (locs.isEmpty) {
      setState(() {
        _activeIssueFocusIndex = -1;
        _focusedPersonKey = null;
        _parseIssuesExpanded = true;
      });
      return;
    }
    setState(() {
      if (_activeIssueFocusIndex < 0 || _activeIssueFocusIndex >= locs.length) {
        _activeIssueFocusIndex = 0;
      } else {
        _activeIssueFocusIndex = (_activeIssueFocusIndex + 1) % locs.length;
      }
      final target = locs[_activeIssueFocusIndex];
      _focusedPersonKey = target.personIndex != null
          ? '${target.blockIndex}:${target.personIndex}'
          : null;
    });
    _scrollToProblemLocation(locs[_activeIssueFocusIndex].blockIndex);
  }

  void _focusPreviousProblem() {
    final locs = _getProblemLocations();
    if (locs.isEmpty) {
      setState(() {
        _activeIssueFocusIndex = -1;
        _focusedPersonKey = null;
        _parseIssuesExpanded = true;
      });
      return;
    }
    setState(() {
      if (_activeIssueFocusIndex < 0 || _activeIssueFocusIndex >= locs.length) {
        _activeIssueFocusIndex = locs.length - 1;
      } else {
        _activeIssueFocusIndex =
            (_activeIssueFocusIndex - 1 + locs.length) % locs.length;
      }
      final target = locs[_activeIssueFocusIndex];
      _focusedPersonKey = target.personIndex != null
          ? '${target.blockIndex}:${target.personIndex}'
          : null;
    });
    _scrollToProblemLocation(locs[_activeIssueFocusIndex].blockIndex);
  }

  void _scrollToProblemLocation(int blockIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_previewScrollController.hasClients) return;

      final cardKey = _cardKeys[blockIndex];
      if (cardKey?.currentContext != null) {
        Scrollable.ensureVisible(
          cardKey!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
        return;
      }

      // Compute position based on currently visible blocks filter
      final duplicates = _duplicateAssignments();
      final visibleBlockEntries = _parsedBlocks.asMap().entries.where((entry) {
        if (_previewFilter == _BulkPreviewFilter.all) return true;
        final hasReview = entry.value.personnelList.any((p) => p.needsReview);
        final hasDup = entry.value.personnelList.asMap().keys.any(
            (pIdx) => duplicates.containsKey('${entry.key}:$pIdx'));
        return entry.value.personnelList.isEmpty || hasReview || hasDup;
      }).toList();

      final visibleIndex = visibleBlockEntries.indexWhere((e) => e.key == blockIndex);
      final targetIndex = visibleIndex >= 0 ? visibleIndex : blockIndex;

      final maxExtent = _previewScrollController.position.maxScrollExtent;
      // Header area in SliverToBoxAdapter takes ~180px before SliverList starts
      const headerOffset = 180.0;
      final estimatedOffset = (headerOffset + targetIndex * 220.0).clamp(0.0, maxExtent);

      _previewScrollController
          .animateTo(
        estimatedOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      )
          .then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final targetKey = _cardKeys[blockIndex];
          if (targetKey?.currentContext != null) {
            Scrollable.ensureVisible(
              targetKey!.currentContext!,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: 0.15,
            );
          }
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadPersonnel());
    unawaited(_loadPreferences());
  }

  @override
  void dispose() {
    _textController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  void _setPreviewFilter(_BulkPreviewFilter filter) {
    setState(() {
      _cardKeys.clear();
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

  Future<void> _loadPreferences() async {
    final keepAuditText = await _preferences.loadKeepAuditText();
    if (!mounted) return;
    if (!_keepAuditTextChanged) {
      setState(() => _keepAuditText = keepAuditText);
    }
  }

  void _setKeepAuditText(bool value) {
    setState(() {
      _keepAuditText = value;
      _keepAuditTextChanged = true;
    });
    unawaited(_preferences.saveKeepAuditText(value));
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
        _cardKeys.clear();
        _parsedBlocks = deduplicated.blocks;
        _parseIssues = parseResult.issues;
        _deduplicatedPersonnelCount = deduplicated.removedCount;
        _previewFilter = _BulkPreviewFilter.all;
        _parseIssuesExpanded = _parseIssues.any((issue) => issue.isBlocking);
        if (_parsedBlocks.isNotEmpty || _parseIssues.isNotEmpty) {
          _currentStep = 1; // Auto switch to Preview step
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
      await showDuplicatePersonnelDialog(
        context: context,
        duplicates: preparation.duplicates,
        squads: _allSquads,
      );
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
      final learningService = BulkImportLearningService(widget.database);
      final fingerprint = BulkImportLearningService.fingerprint(_parsedBlocks);
      final existingImport = await learningService.findImport(fingerprint);
      if (existingImport != null) {
        final activeCount =
            await learningService.countActiveAssignments(_parsedBlocks);
        if (activeCount == 0) {
          // Stale import record because activities were deleted, clean up stale record
          await learningService.deleteImportRecord(fingerprint);
        } else {
          if (!mounted) return;
          final userChoice = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Bu Liste Daha Önce Aktarıldı'),
              content: Text(
                '${existingImport.tarihler} tarihli bu içerik '
                '${existingImport.kayitTarihi} tarihinde '
                '${existingImport.aktaranKullanici} tarafından kaydedilmiş.\n\n'
                'Veritabanında bu listeye ait $activeCount personel kaydı aktif duruyor. '
                'Eksik olanları tamamlamak veya yeniden aktarmak istiyor musunuz?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('İPTAL'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('EKSİKLERİ TAMAMLA / YENİDEN AKTAR'),
                ),
              ],
            ),
          );
          if (userChoice != true) return;
        }
      }
      final result =
          await widget.activityRepository.createActivitiesWithAssignments(
        preparation.requests,
        actor: actor,
      );
      await learningService.recordImport(
        fingerprint: fingerprint,
        blocks: _parsedBlocks,
        actor: actor.username,
        rawText: _keepAuditText ? _textController.text : null,
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

        final summaryLines = <String>[
          '${preparation.requests.length} günlük faaliyet işlendi.',
          '${result.addedAssignmentCount} yeni personel eklendi.',
          if (result.alreadyAssignedCount > 0)
            '${result.alreadyAssignedCount} personel zaten o görevde ekliydi.',
          if (_deduplicatedPersonnelCount > 0)
            '$_deduplicatedPersonnelCount tekrar tekilleştirildi.',
          if (result.skippedAssignmentCount > 0)
            '${result.skippedAssignmentCount} çakışan kayıt atlandı.',
        ];

        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Aktarım Tamamlandı'),
            content: Text(summaryLines.join('\n')),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('TAMAM'),
              ),
            ],
          ),
        );
        if (!mounted) return;
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

  Map<String, List<String>> _duplicateAssignments() {
    final occurrences = <String, List<({int blockIndex, int personIndex})>>{};
    for (final blockEntry in _parsedBlocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final id = personEntry.value.matchedPersonnelId;
        if (id == null) continue;
        final key =
            '${blockEntry.value.parsedDate}:${blockEntry.value.parsedActivityType.trim().toUpperCase()}:$id';
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
        _deduplicatedPersonnelCount = 0;
        _cardKeys.clear();
        _currentStep = 0;
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

                      // Stepper (Faz 1)
                      BulkImportStepper(
                        currentStep: _currentStep,
                        hasBlocks: _parsedBlocks.isNotEmpty,
                        onStepTapped: (int step) {
                          if (step <= _currentStep ||
                              (step == 1 && _parsedBlocks.isNotEmpty)) {
                            setState(() => _currentStep = step);
                          }
                        },
                      ),

                      // Main Body Content
                      Expanded(
                        child: isMobile
                            ? _buildMobileBody(isKeyboardVisible)
                            : _buildDesktopBody(isKeyboardVisible),
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

  Widget _buildMobileBody(bool isKeyboardVisible) {
    return switch (_currentStep) {
      0 => _buildInputSection(isMobile: true, isKeyboardVisible: isKeyboardVisible),
      1 => _buildPreviewSection(isMobile: true),
      _ => _buildConfirmStep(isMobile: true),
    };
  }

  Widget _buildDesktopBody(bool isKeyboardVisible) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentStep == 0)
            Expanded(
              flex: 4,
              child: _buildInputSection(
                isMobile: false,
                isKeyboardVisible: isKeyboardVisible,
              ),
            ),
          if (_currentStep == 0) ...[
            const SizedBox(width: 20),
            const VerticalDivider(width: 1),
            const SizedBox(width: 20),
          ],
          Expanded(
            flex: _currentStep == 0 ? 6 : 10,
            child: _currentStep == 2
                ? _buildConfirmStep(isMobile: false)
                : _buildPreviewSection(isMobile: false),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep({required bool isMobile}) {
    final hasBlocking =
        _parseIssues.any((issue) => issue.isBlocking) || _unresolvedPersonnelCount > 0;
    final totalDays = _parsedBlocks.map((b) => b.parsedDate).toSet().length;
    final totalPersonnel = _parsedBlocks.fold<int>(0, (c, b) => c + b.personnelList.length);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 24 : 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasBlocking ? Icons.error_rounded : Icons.task_alt_rounded,
            size: 64,
            color: hasBlocking ? const Color(0xFFD32F2F) : const Color(0xFF16A34A),
          ),
          const SizedBox(height: 20),
          Text(
            hasBlocking ? 'Kaydedilemiyor' : 'Kayda Hazır',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: hasBlocking ? const Color(0xFFD32F2F) : const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasBlocking
                ? 'Lütfen önizleme adımına dönüp sorunları çözün.'
                : '${_parsedBlocks.length} kart, $totalPersonnel personel, $totalDays gün',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          if (!hasBlocking)
            AnimatedScale(
              scale: _isSaving ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: FilledButton.icon(
                key: const Key('bulk-import-save-button'),
                onPressed: _isSaving ? null : _saveAllToFaaliyet,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: const Text(
                  'Faaliyetleri Kaydet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              key: const Key('bulk-goto-problem'),
              onPressed: () => setState(() => _currentStep = 1),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Önizlemeye Dön'),
            ),
        ],
      ),
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
              const Flexible(
                child: Text(
                  'Ham Metni Yapıştırın:',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ham metni yerel denetim kaydında sakla',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Varsayılan kapalıdır; veri yalnızca bu cihazda tutulur.',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _keepAuditText,
                onChanged: _setKeepAuditText,
              ),
            ],
          ),
          SizedBox(height: isKeyboardVisible ? 4 : 6),
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
    final problemLocs = _getProblemLocations();
    final totalDays = _parsedBlocks.map((b) => b.parsedDate).toSet().length;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _previewScrollController,
              slivers: [
                SliverToBoxAdapter(
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
                                  Icons.assignment_rounded,
                                  color: const Color(0xFF556B3F),
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
                      const SizedBox(height: 8),
                      if (_parsedBlocks.isNotEmpty) ...[
                        // Faz 2: Kompakt Stat Bar
                        BulkImportCompactStatBar(
                          cardCount: _parsedBlocks.length,
                          personnelCount: personnelCount,
                          dayCount: totalDays,
                        ),
                        const SizedBox(height: 10),
                        // Faz 3: Kompakt Hata Özeti
                        CompactErrorSummary(
                          problemCount: problemCount,
                          warningCount: _parseIssues.length,
                          parseIssues: _parseIssues,
                          isExpanded: _parseIssuesExpanded,
                          onToggle: () => setState(
                            () => _parseIssuesExpanded = !_parseIssuesExpanded,
                          ),
                          onStartWizard: problemCount == 0 ? null : _focusNextProblem,
                          totalIssues: problemLocs.length,
                          currentIndex: _activeIssueFocusIndex,
                          onPrevious: _focusPreviousProblem,
                          onNext: _focusNextProblem,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                if (_parsedBlocks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF556B3F)
                                    .withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fact_check_outlined,
                                size: 48,
                                color: Color(0xFF556B3F),
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
                              'Yapıştır adımına dönüp mesajı yapıştırın.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (visibleBlocks.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildFilteredEmptyState(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, blockIdx) {
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
                      childCount: visibleBlocks.length,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Faz 5: Akıllı Alt Buton
          SmartSaveBar(
            problemCount: problemCount,
            problemLocs: problemLocs,
            activeIssueFocusIndex: _activeIssueFocusIndex,
            onGotoProblem: _focusNextProblem,
            onSave: _saveAllToFaaliyet,
            isSaving: _isSaving,
            blocks: _parsedBlocks,
            issues: _parseIssues,
            hasUnresolvedProblems: duplicates.isNotEmpty ||
                _unresolvedPersonnelCount > 0 ||
                _parsedBlocks.any((block) => block.personnelList.isEmpty),
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
      key: _cardKeys.putIfAbsent(blockIdx, () => GlobalKey()),
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.cardBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, visibleIndex) {
                  final pIdx = personnelIndexes[visibleIndex];
                  final item = block.personnelList[pIdx];
                  final duplicateWith = duplicates['$blockIdx:$pIdx'];
                  final personKey = '$blockIdx:$pIdx';
                  final isFocused = _focusedPersonKey == personKey;
                  return PersonnelMatchCard(
                    key: Key('bulk-person-$blockIdx-$pIdx'),
                    item: item,
                    teamName: _allSquads
                            .where((team) => team.id == item.matchedTimId)
                            .map((team) => team.timAdi)
                            .firstOrNull ??
                        'Tim bilgisi yok',
                    duplicateAssignments: duplicateWith,
                    isFocused: isFocused,
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
      await BulkImportLearningService(widget.database).rememberAlias(
        rawName: item.rawName,
        personnelId: person.id,
      );
    }
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
