import 'dart:async';
import 'package:drift/drift.dart' show Value;
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
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/learned_aliases_dialog.dart';
import 'package:personelapp2/features/activity/services/bulk_import_preferences.dart';

export 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart'
    show BulkImportSaveButton;

part 'bulk_import_dialog_actions.dart';

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
  final _personKeys = <String, GlobalKey>{};

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
    final target = locs[_activeIssueFocusIndex < 0
        ? 0
        : (_activeIssueFocusIndex + 1) % locs.length];
    setState(() {
      _previewFilter = _BulkPreviewFilter.problems;
      _parseIssuesExpanded = true;
      if (_activeIssueFocusIndex < 0 || _activeIssueFocusIndex >= locs.length) {
        _activeIssueFocusIndex = 0;
      } else {
        _activeIssueFocusIndex = (_activeIssueFocusIndex + 1) % locs.length;
      }
      _focusedPersonKey = target.personIndex != null
          ? '${target.blockIndex}:${target.personIndex}'
          : '${target.blockIndex}:empty';
    });
    _scrollToProblemLocation(target.blockIndex, target.personIndex);
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
    final target = locs[_activeIssueFocusIndex < 0
        ? locs.length - 1
        : (_activeIssueFocusIndex - 1 + locs.length) % locs.length];
    setState(() {
      _previewFilter = _BulkPreviewFilter.problems;
      _parseIssuesExpanded = true;
      if (_activeIssueFocusIndex < 0 || _activeIssueFocusIndex >= locs.length) {
        _activeIssueFocusIndex = locs.length - 1;
      } else {
        _activeIssueFocusIndex =
            (_activeIssueFocusIndex - 1 + locs.length) % locs.length;
      }
      _focusedPersonKey = target.personIndex != null
          ? '${target.blockIndex}:${target.personIndex}'
          : '${target.blockIndex}:empty';
    });
    _scrollToProblemLocation(target.blockIndex, target.personIndex);
  }

  void _scrollToProblemLocation(int blockIndex, [int? personIndex]) {
    BulkImportProblemWizard.scrollToProblemLocation(
      blockIndex: blockIndex,
      personIndex: personIndex,
      scrollController: _previewScrollController,
      cardKeys: _cardKeys,
      personKeys: _personKeys,
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

  void _updateState(VoidCallback callback) {
    setState(() {
      callback();
      _syncParseIssuesWithBlocks();
    });
  }

  void _syncParseIssuesWithBlocks() {
    if (_parsedBlocks.isEmpty) return;
    final mutableIssues = List<BulkParseIssue>.from(_parseIssues);
    final hasMissingDate =
        _parsedBlocks.any((b) => b.parsedDate.trim().isEmpty);
    final hasMissingTeam =
        _parsedBlocks.any((b) => b.parsedTimName.trim().isEmpty);
    final hasMissingActivity =
        _parsedBlocks.any((b) => b.parsedActivityType.trim().isEmpty);
    final hasUnmatchedPerson =
        _parsedBlocks.any((b) => b.personnelList.any((p) => !p.isMatched));
    final hasEmptyBlock =
        _parsedBlocks.any((b) => b.personnelList.isEmpty);

    mutableIssues.removeWhere((issue) {
      switch (issue.code) {
        case 'missing_date':
        case 'invalid_date':
          return !hasMissingDate;
        case 'unknown_team':
          return !hasMissingTeam;
        case 'unknown_activity':
          return !hasMissingActivity;
        case 'empty_input':
          return _parsedBlocks.isNotEmpty;
        case 'unmatched_personnel':
        case 'invalid_personnel':
          return !hasUnmatchedPerson;
        case 'invalid_time':
          return true;
        default:
          return !hasMissingDate &&
              !hasMissingTeam &&
              !hasMissingActivity &&
              !hasUnmatchedPerson &&
              !hasEmptyBlock;
      }
    });

    _parseIssues = mutableIssues;
  }

  void _setPreviewFilter(_BulkPreviewFilter filter) {
    setState(() {
      _cardKeys.clear();
      _personKeys.clear();
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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final borderRadius = isMobile ? 0.0 : 20.0;
        return Dialog(
          insetPadding: isMobile
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isKeyboardVisible ? 8 : 32,
                ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? mediaQuery.size.width : 1180,
                maxHeight: isMobile
                    ? mediaQuery.size.height
                    : mediaQuery.size.height * 0.9,
              ),
              child: SizedBox(
                width: isMobile
                    ? mediaQuery.size.width
                    : constraints.maxWidth * 0.85,
                height: isMobile ? mediaQuery.size.height : double.infinity,
                child: SafeArea(
                  top: isMobile,
                  bottom: isMobile,
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        BulkImportHeaderBanner(
                          isKeyboardVisible: isKeyboardVisible,
                          onOpenMemory: () => LearnedAliasesDialog.show(
                            context,
                            widget.database,
                          ),
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

  bool get _hasReviewableSuggestions => _parsedBlocks
      .expand((b) => b.personnelList)
      .any((p) => p.hasWarning && p.isMatched && p.matchedPersonnelId != null);

  Future<void> _confirmPersonnelSuggestion(
      int blockIndex, int personIndex) async {
    final currentBlock = _parsedBlocks[blockIndex];
    final item = currentBlock.personnelList[personIndex];
    if (!item.isMatched || item.matchedPersonnelId == null) return;

    setState(() {
      final updatedList =
          List<ParsedPersonnelItem>.from(currentBlock.personnelList);
      updatedList[personIndex] = updatedList[personIndex].copyWith(
        matchConfidence: 1.0,
        teamMismatch: false,
        reviewConfirmed: true,
      );
      _parsedBlocks[blockIndex] =
          currentBlock.copyWith(personnelList: updatedList);
    });

    await BulkImportLearningService(widget.database).rememberAlias(
      rawName: item.rawName,
      personnelId: item.matchedPersonnelId!,
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
      personKeys: _personKeys,
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
      onConfirmPersonnelSuggestion: _confirmPersonnelSuggestion,
      onAddNewPersonnel: _quickAddNewPersonnelToTim,
      onConfirmAllSuggestions:
          _hasReviewableSuggestions ? _confirmAllSuggestions : null,
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
}
