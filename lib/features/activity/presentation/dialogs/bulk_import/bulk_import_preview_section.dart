import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_empty_state.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_stat_cards.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/compact_error_summary.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart';

class BulkImportPreviewSection extends StatelessWidget {
  const BulkImportPreviewSection({
    required this.blocks,
    required this.issues,
    required this.duplicates,
    required this.allSquads,
    required this.cardKeys,
    required this.scrollController,
    required this.isMobile,
    required this.previewFilterIsProblems,
    required this.parseIssuesExpanded,
    required this.activeIssueFocusIndex,
    required this.focusedPersonKey,
    required this.unresolvedPersonnelCount,
    required this.isSaving,
    required this.problemLocations,
    required this.onClearAll,
    required this.onToggleParseIssues,
    required this.onStartWizard,
    required this.onFocusPrevious,
    required this.onFocusNext,
    required this.onShowAll,
    required this.onEditBlock,
    required this.onRemoveBlock,
    required this.onSelectPersonnel,
    required this.onRemovePerson,
    this.onConfirmPersonnelSuggestion,
    this.onConfirmAllSuggestions,
    required this.onSave,
    super.key,
  });

  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final Map<String, List<String>> duplicates;
  final List<TimTableData> allSquads;
  final Map<int, GlobalKey> cardKeys;
  final ScrollController scrollController;
  final bool isMobile;
  final bool previewFilterIsProblems;
  final bool parseIssuesExpanded;
  final int activeIssueFocusIndex;
  final String? focusedPersonKey;
  final int unresolvedPersonnelCount;
  final bool isSaving;
  final List<ProblemLocation> problemLocations;
  final VoidCallback onClearAll;
  final VoidCallback onToggleParseIssues;
  final VoidCallback? onStartWizard;
  final VoidCallback onFocusPrevious;
  final VoidCallback onFocusNext;
  final VoidCallback onShowAll;
  final void Function(int blockIndex) onEditBlock;
  final void Function(int blockIndex) onRemoveBlock;
  final void Function(int blockIndex, int personIndex) onSelectPersonnel;
  final void Function(int blockIndex, int personIndex) onRemovePerson;
  final void Function(int blockIndex, int personIndex)? onConfirmPersonnelSuggestion;
  final VoidCallback? onConfirmAllSuggestions;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final problemPersonnelByBlock = <int, List<int>>{};
    for (final blockEntry in blocks.asMap().entries) {
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
    final visibleBlocks = blocks.asMap().entries.where((entry) {
      return !previewFilterIsProblems ||
          problemPersonnelByBlock.containsKey(entry.key);
    }).toList(growable: false);
    final personnelCount = blocks.fold<int>(
      0,
      (count, block) => count + block.personnelList.length,
    );
    final problemCount = duplicates.length +
        unresolvedPersonnelCount +
        blocks.where((block) => block.personnelList.isEmpty).length +
        issues.where((issue) => issue.isBlocking).length;
    final totalDays = blocks.map((b) => b.parsedDate).toSet().length;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
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
                                const Icon(
                                  Icons.assignment_rounded,
                                  color: Color(0xFF556B3F),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Faaliyet Kartları (${blocks.length})',
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
                          if (blocks.isNotEmpty || issues.isNotEmpty)
                            IconButton(
                              onPressed: onClearAll,
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
                      if (blocks.isNotEmpty) ...[
                        BulkImportCompactStatBar(
                          cardCount: blocks.length,
                          personnelCount: personnelCount,
                          dayCount: totalDays,
                        ),
                        const SizedBox(height: 10),
                        CompactErrorSummary(
                          problemCount: problemCount,
                          warningCount: issues.length,
                          parseIssues: issues,
                          problemLocations: problemLocations,
                          isExpanded: parseIssuesExpanded,
                          onToggle: onToggleParseIssues,
                          onStartWizard: onStartWizard,
                          onConfirmAllSuggestions: onConfirmAllSuggestions,
                          totalIssues: problemLocations.length,
                          currentIndex: activeIssueFocusIndex,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                if (blocks.isEmpty)
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
                    child: BulkImportEmptyState(
                      issues: issues,
                      onShowAll: onShowAll,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, blockIdx) {
                        final entry = visibleBlocks[blockIdx];
                        final originalBlockIndex = entry.key;
                        final block = entry.value;
                        return ActivityBlockCard(
                          cardKey: cardKeys.putIfAbsent(
                            originalBlockIndex,
                            () => GlobalKey(),
                          ),
                          block: block,
                          blockIdx: originalBlockIndex,
                          duplicates: duplicates,
                          allSquads: allSquads,
                          focusedPersonKey: focusedPersonKey,
                          visiblePersonnelIndexes: previewFilterIsProblems
                              ? problemPersonnelByBlock[originalBlockIndex]
                              : null,
                          onEditBlock: onEditBlock,
                          onRemoveBlock: onRemoveBlock,
                          onSelectPersonnel: onSelectPersonnel,
                          onRemovePerson: onRemovePerson,
                          onConfirmPersonnelSuggestion: onConfirmPersonnelSuggestion,
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
            problemCount: problemCount,
            problemLocs: problemLocations,
            activeIssueFocusIndex: activeIssueFocusIndex,
            onGotoProblem: onFocusNext,
            onGotoPrevious: onFocusPrevious,
            onSave: onSave,
            isSaving: isSaving,
            blocks: blocks,
            issues: issues,
            hasUnresolvedProblems: duplicates.isNotEmpty ||
                unresolvedPersonnelCount > 0 ||
                blocks.any((block) => block.personnelList.isEmpty),
          ),
        ],
      ),
    );
  }
}
