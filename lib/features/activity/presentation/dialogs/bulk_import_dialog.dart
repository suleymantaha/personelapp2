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
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_confirm_section.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_empty_state.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_input_section.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_preview_section.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_stat_cards.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_stepper.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/compact_error_summary.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/duplicate_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/edit_activity_block_dialog.dart';
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
    final addedKeys = <String>{};

    // Priority 1: Critical empty blocks (0 personnel)
    for (final blockEntry in _parsedBlocks.asMap().entries) {
      if (blockEntry.value.personnelList.isEmpty) {
        locs.add((blockIndex: blockEntry.key, personIndex: null));
        addedKeys.add('${blockEntry.key}:null');
      }
    }

    // Priority 2: Personnel needing match review
    for (final blockEntry in _parsedBlocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final key = '${blockEntry.key}:${personEntry.key}';
        if (personEntry.value.needsReview && !addedKeys.contains(key)) {
          locs.add((blockIndex: blockEntry.key, personIndex: personEntry.key));
          addedKeys.add(key);
        }
      }
    }

    // Priority 3: Secondary duplicate assignments
    for (final blockEntry in _parsedBlocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final key = '${blockEntry.key}:${personEntry.key}';
        if (duplicates.containsKey(key) && !addedKeys.contains(key)) {
          locs.add((blockIndex: blockEntry.key, personIndex: personEntry.key));
          addedKeys.add(key);
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
      _parseIssuesExpanded = true;
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
        final hasDup = entry.value.personnelList
            .asMap()
            .keys
            .any((pIdx) => duplicates.containsKey('${entry.key}:$pIdx'));
        return entry.value.personnelList.isEmpty || hasReview || hasDup;
      }).toList();

      final visibleIndex =
          visibleBlockEntries.indexWhere((e) => e.key == blockIndex);
      final targetIndex = visibleIndex >= 0 ? visibleIndex : blockIndex;

      final maxExtent = _previewScrollController.position.maxScrollExtent;
      // Header area in SliverToBoxAdapter takes ~180px before SliverList starts
      const headerOffset = 180.0;
      final estimatedOffset =
          (headerOffset + targetIndex * 220.0).clamp(0.0, maxExtent);

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
          _activeIssueFocusIndex = -1;
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
    final updated = await EditActivityBlockDialog.show(context, block);
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
      0 => _buildInputSection(
          isMobile: true, isKeyboardVisible: isKeyboardVisible),
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

  Widget _buildPreviewSection({required bool isMobile}) {
    final duplicates = _duplicateAssignments();
    final problemLocs = _getProblemLocations();
    return BulkImportPreviewSection(
      blocks: _parsedBlocks,
      issues: _parseIssues,
      duplicates: duplicates,
      allSquads: _allSquads,
      cardKeys: _cardKeys,
      scrollController: _previewScrollController,
      isMobile: isMobile,
      previewFilterIsProblems: _previewFilter == _BulkPreviewFilter.problems,
      parseIssuesExpanded: _parseIssuesExpanded,
      activeIssueFocusIndex: _activeIssueFocusIndex,
      focusedPersonKey: _focusedPersonKey,
      unresolvedPersonnelCount: _unresolvedPersonnelCount,
      isSaving: _isSaving,
      problemLocations: problemLocs,
      onClearAll: _confirmClearAll,
      onToggleParseIssues: () => setState(
        () => _parseIssuesExpanded = !_parseIssuesExpanded,
      ),
      onStartWizard: problemLocs.isEmpty ? null : _focusNextProblem,
      onFocusPrevious: _focusPreviousProblem,
      onFocusNext: _focusNextProblem,
      onShowAll: () => _setPreviewFilter(_BulkPreviewFilter.all),
      onEditBlock: _editBlock,
      onRemoveBlock: _removeBlock,
      onSelectPersonnel: _selectPersonnel,
      onRemovePerson: _removePerson,
      onSave: _saveAllToFaaliyet,
    );
  }

  Widget _buildConfirmStep({required bool isMobile}) {
    return BulkImportConfirmSection(
      blocks: _parsedBlocks,
      issues: _parseIssues,
      unresolvedPersonnelCount: _unresolvedPersonnelCount,
      isSaving: _isSaving,
      isMobile: isMobile,
      onSave: _saveAllToFaaliyet,
      onReturnToPreview: () {
        setState(() => _currentStep = 1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _focusNextProblem();
        });
      },
    );
  }

  Widget _buildInputSection({
    required bool isMobile,
    required bool isKeyboardVisible,
  }) {
    return BulkImportInputSection(
      textController: _textController,
      keepAuditText: _keepAuditText,
      onKeepAuditTextChanged: _setKeepAuditText,
      isMobile: isMobile,
      isKeyboardVisible: isKeyboardVisible,
      isParsing: _isParsing,
      onProcessText: _processText,
    );
  }

  Widget _buildFilteredEmptyState() {
    return BulkImportEmptyState(
      issues: _parseIssues,
      onShowAll: () => _setPreviewFilter(_BulkPreviewFilter.all),
    );
  }

  Widget _buildPreviewCard(
    ParsedActivityBlock block,
    int blockIdx,
    Map<String, List<String>> duplicates, {
    List<int>? visiblePersonnelIndexes,
  }) {
    return ActivityBlockCard(
      cardKey: _cardKeys.putIfAbsent(blockIdx, () => GlobalKey()),
      block: block,
      blockIdx: blockIdx,
      duplicates: duplicates,
      allSquads: _allSquads,
      focusedPersonKey: _focusedPersonKey,
      visiblePersonnelIndexes: visiblePersonnelIndexes,
      onEditBlock: _editBlock,
      onRemoveBlock: _removeBlock,
      onSelectPersonnel: _selectPersonnel,
      onRemovePerson: _removePerson,
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
