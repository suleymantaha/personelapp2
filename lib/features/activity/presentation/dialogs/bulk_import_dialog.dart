import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_confirm_section.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_header_banner.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_input_section.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_preview_section.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_save_handler.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_stepper.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/edit_activity_block_dialog.dart';
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
  int _currentStep = 0; // 0: paste, 1: preview, 2: confirm
  int _activeIssueFocusIndex = -1;
  String? _focusedPersonKey;
  final _cardKeys = <int, GlobalKey>{};

  List<ProblemLocation> _getProblemLocations() {
    return BulkImportProblemWizard.getProblemLocations(
      blocks: _parsedBlocks,
      duplicates: _duplicateAssignments(),
    );
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
      _previewFilter = _BulkPreviewFilter.problems;
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
      _previewFilter = _BulkPreviewFilter.problems;
      _parseIssuesExpanded = true;
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
    BulkImportProblemWizard.scrollToProblemLocation(
      blockIndex: blockIndex,
      scrollController: _previewScrollController,
      cardKeys: _cardKeys,
      blocks: _parsedBlocks,
      duplicates: _duplicateAssignments(),
      filterIsProblems: _previewFilter == _BulkPreviewFilter.problems,
    );
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
      final deduplicated = BulkImportSaveHandler.deduplicateSameDuty(matchedBlocks);
      if (!mounted) return;

      setState(() {
        _cardKeys.clear();
        _parsedBlocks = deduplicated.blocks;
        _parseIssues = parseResult.issues;
        _deduplicatedPersonnelCount = deduplicated.removedCount;
        _previewFilter = _BulkPreviewFilter.all;
        _parseIssuesExpanded = _parseIssues.any((issue) => issue.isBlocking);
        if (_parsedBlocks.isNotEmpty || _parseIssues.isNotEmpty) {
          _currentStep = 1;
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

    setState(() {
      _isSaving = true;
    });

    try {
      final actor = ref.read(userSessionProvider);
      await BulkImportSaveHandler.saveAllToFaaliyet(
        context: context,
        database: widget.database,
        activityRepository: widget.activityRepository,
        actor: actor,
        blocks: _parsedBlocks,
        squads: _allSquads,
        keepAuditText: _keepAuditText,
        rawText: _textController.text,
        deduplicatedPersonnelCount: _deduplicatedPersonnelCount,
      );
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
    return BulkImportSaveHandler.findDuplicateAssignments(_parsedBlocks);
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
                      BulkImportHeaderBanner(
                        isKeyboardVisible: isKeyboardVisible,
                        onClose: () => Navigator.pop(context),
                      ),
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
