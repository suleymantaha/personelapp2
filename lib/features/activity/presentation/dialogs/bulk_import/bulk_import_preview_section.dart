import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_empty_state.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart';

part 'bulk_import_preview_correctness_panel.dart';
part 'bulk_import_preview_state.dart';
part 'bulk_import_preview_filter_search.dart';
part 'bulk_import_preview_active_issue_card.dart';

class BulkImportPreviewSection extends StatefulWidget {
  const BulkImportPreviewSection({
    required this.blocks,
    required this.issues,
    required this.duplicates,
    required this.allSquads,
    required this.cardKeys,
    required this.personKeys,
    required this.scrollController,
    required this.isMobile,
    required this.previewFilterIsProblems,
    required this.previewFilterIsReady,
    required this.parseIssuesExpanded,
    required this.activeIssueFocusIndex,
    required this.focusedIssue,
    required this.unresolvedPersonnelCount,
    required this.isSaving,
    required this.problemLocations,
    required this.onClearAll,
    required this.onToggleParseIssues,
    required this.onStartWizard,
    required this.onFocusPrevious,
    required this.onFocusNext,
    required this.onShowAll,
    required this.onShowProblems,
    required this.onShowReady,
    required this.onEditBlock,
    required this.onRemoveBlock,
    required this.onSelectPersonnel,
    required this.onRemovePerson,
    this.onConfirmPersonnelSuggestion,
    this.onAddNewPersonnel,
    this.onConfirmAllSuggestions,
    required this.onSave,
    super.key,
  });

  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final Map<String, List<String>> duplicates;
  final List<TimTableData> allSquads;
  final Map<int, GlobalKey> cardKeys;
  final Map<String, GlobalKey> personKeys;
  final ScrollController scrollController;
  final bool isMobile;
  final bool previewFilterIsProblems;
  final bool previewFilterIsReady;
  final bool parseIssuesExpanded;
  final int activeIssueFocusIndex;
  final BulkIssueFocus? focusedIssue;
  final int unresolvedPersonnelCount;
  final bool isSaving;
  final List<ProblemLocation> problemLocations;
  final VoidCallback onClearAll;
  final VoidCallback onToggleParseIssues;
  final VoidCallback? onStartWizard;
  final VoidCallback onFocusPrevious;
  final VoidCallback onFocusNext;
  final VoidCallback onShowAll;
  final VoidCallback onShowProblems;
  final VoidCallback onShowReady;
  final void Function(int blockIndex) onEditBlock;
  final void Function(int blockIndex) onRemoveBlock;
  final void Function(int blockIndex, int personIndex) onSelectPersonnel;
  final void Function(int blockIndex, int personIndex) onRemovePerson;
  final void Function(int blockIndex, int personIndex)?
      onConfirmPersonnelSuggestion;
  final void Function(int blockIndex, int personIndex)? onAddNewPersonnel;
  final VoidCallback? onConfirmAllSuggestions;
  final VoidCallback onSave;

  @override
  State<BulkImportPreviewSection> createState() =>
      _BulkImportPreviewSectionState();
}

class _BulkImportPreviewSectionState extends State<BulkImportPreviewSection> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final problemState = _buildPreviewProblemState(
      blocks: widget.blocks,
      problemLocations: widget.problemLocations,
      duplicates: widget.duplicates,
    );
    final query = _searchController.text.trim().toLowerCase();
    final visibleBlocks = _filterVisiblePreviewBlocks(
      blocks: widget.blocks,
      problemPersonnelByBlock: problemState.personnelByBlock,
      previewFilterIsProblems: widget.previewFilterIsProblems,
      previewFilterIsReady: widget.previewFilterIsReady,
      query: query,
    );
    final metrics = _buildPreviewMetrics(
      blocks: widget.blocks,
      issues: widget.issues,
      problemLocations: widget.problemLocations,
    );

    return Padding(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomScrollView(
              controller: widget.scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.blocks.isNotEmpty) ...[
                        _CorrectnessPanel(
                          cardCount: widget.blocks.length,
                          personnelCount: metrics.personnelCount,
                          dayCount: metrics.dayCount,
                          criticalCount: metrics.displayCriticalCount,
                          reviewCount: metrics.reviewCount,
                          actionCount: metrics.actionCount,
                          hasBlocking: metrics.hasBlocking,
                          compact: !widget.isMobile,
                          onClearAll: widget.onClearAll,
                          onStartWizard: widget.onStartWizard,
                          onConfirmAllSuggestions:
                              widget.onConfirmAllSuggestions,
                        ),
                        const SizedBox(height: 12),
                        _FilterSearchStrip(
                          selected: widget.previewFilterIsProblems
                              ? _PreviewFilter.problems
                              : widget.previewFilterIsReady
                                  ? _PreviewFilter.ready
                                  : _PreviewFilter.all,
                          problemCount: metrics.actionCount,
                          allCount: widget.blocks.length,
                          readyCount: problemState.readyBlockCount,
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          onProblems: widget.onShowProblems,
                          onAll: widget.onShowAll,
                          onReady: widget.onShowReady,
                        ),
                        const SizedBox(height: 10),
                        if (!widget.previewFilterIsReady &&
                            (widget.isMobile ||
                                widget.activeIssueFocusIndex >= 0)) ...[
                          _ActiveIssueCard(
                            problemLocations: widget.problemLocations,
                            parseIssues: widget.issues,
                            activeIssueFocusIndex: widget.activeIssueFocusIndex,
                            onFix: widget.onStartWizard ?? widget.onFocusNext,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
                ),
                if (widget.blocks.isEmpty)
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
                                color: context.accentOrOlive
                                    .withValues(alpha: 0.08),
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
                              'Yapıştır adımına dönüp mesajı yapıştırın.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.textSecondary,
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
                    child: BulkImportEmptyState(
                      issues: widget.issues,
                      onShowAll: widget.onShowAll,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, blockIdx) {
                        final entry = visibleBlocks[blockIdx];
                        final originalBlockIndex = entry.key;
                        final block = entry.value;
                        final isFocusedBlock =
                            widget.focusedIssue?.matchesBlock(
                                  originalBlockIndex,
                                ) ??
                                false;
                        final hasBlockProblems =
                            problemState.personnelByBlock.containsKey(
                          originalBlockIndex,
                        );
                        final problemPersonnelIndexes =
                            problemState.personnelByBlock[originalBlockIndex];
                        return ActivityBlockCard(
                          cardKey: widget.cardKeys.putIfAbsent(
                            originalBlockIndex,
                            () => GlobalKey(),
                          ),
                          personKeys: widget.personKeys,
                          block: block,
                          blockIdx: originalBlockIndex,
                          duplicates: widget.duplicates,
                          allSquads: widget.allSquads,
                          focusedIssue: widget.focusedIssue,
                          isExpanded: isFocusedBlock ||
                              visibleBlocks.length == 1 ||
                              (widget.isMobile &&
                                  blockIdx == 0 &&
                                  hasBlockProblems),
                          visiblePersonnelIndexes: widget
                                      .previewFilterIsProblems &&
                                  problemPersonnelIndexes?.isNotEmpty == true
                              ? problemPersonnelIndexes
                              : null,
                          onEditBlock: widget.onEditBlock,
                          onRemoveBlock: widget.onRemoveBlock,
                          onSelectPersonnel: widget.onSelectPersonnel,
                          onRemovePerson: widget.onRemovePerson,
                          onConfirmPersonnelSuggestion:
                              widget.onConfirmPersonnelSuggestion,
                          onAddNewPersonnel: widget.onAddNewPersonnel,
                        );
                      },
                      childCount: visibleBlocks.length,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SmartSaveBar(
            problemCount: metrics.actionCount,
            problemLocs: widget.problemLocations,
            activeIssueFocusIndex: widget.activeIssueFocusIndex,
            onGotoProblem: widget.onFocusNext,
            onGotoPrevious: widget.onFocusPrevious,
            onSave: widget.onSave,
            isSaving: widget.isSaving,
            blocks: widget.blocks,
            issues: widget.issues,
            hasUnresolvedProblems: widget.duplicates.isNotEmpty ||
                widget.unresolvedPersonnelCount > 0 ||
                widget.blocks.any((block) => block.personnelList.isEmpty),
          ),
        ],
      ),
    );
  }
}
