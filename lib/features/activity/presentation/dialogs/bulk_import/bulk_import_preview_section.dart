import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_empty_state.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart';

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
    final problemPersonnelByBlock = <int, List<int>>{};
    for (final blockEntry in widget.blocks.asMap().entries) {
      final problemIndexes = <int>[];
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        if (_personHasProblem(blockEntry.key, personEntry.key)) {
          problemIndexes.add(personEntry.key);
        }
      }
      if (problemIndexes.isNotEmpty ||
          _blockHasProblem(blockEntry.key, blockEntry.value)) {
        problemPersonnelByBlock[blockEntry.key] = problemIndexes;
      }
    }

    final query = _searchController.text.trim().toLowerCase();
    final visibleBlocks = widget.blocks.asMap().entries.where((entry) {
      final hasProblems = problemPersonnelByBlock.containsKey(entry.key);
      final matchesFilter = widget.previewFilterIsProblems
          ? hasProblems
          : widget.previewFilterIsReady
              ? !hasProblems
              : true;
      return matchesFilter && _matchesQuery(entry.value, query);
    }).toList(growable: false);

    final personnelCount = widget.blocks.fold<int>(
      0,
      (count, block) => count + block.personnelList.length,
    );
    final totalDays = widget.blocks.map((b) => b.parsedDate).toSet().length;
    final criticalCount =
        widget.problemLocations.where((loc) => loc.isCritical).length;
    final reviewCount =
        widget.problemLocations.where((loc) => !loc.isCritical).length;
    final blockingParseIssueCount =
        widget.issues.where((issue) => issue.isBlocking).length;
    final totalActionCount = widget.problemLocations.isNotEmpty
        ? widget.problemLocations.length
        : widget.issues.length;
    final hasBlocking = criticalCount > 0 || blockingParseIssueCount > 0;
    final displayCriticalCount =
        criticalCount > 0 ? criticalCount : blockingParseIssueCount;

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
                          personnelCount: personnelCount,
                          dayCount: totalDays,
                          criticalCount: displayCriticalCount,
                          reviewCount: reviewCount,
                          actionCount: totalActionCount,
                          hasBlocking: hasBlocking,
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
                          problemCount: totalActionCount,
                          allCount: widget.blocks.length,
                          readyCount: widget.blocks.length -
                              problemPersonnelByBlock.length,
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
                        final isFocusedBlock = widget.focusedPersonKey
                                ?.startsWith('$originalBlockIndex:') ??
                            false;
                        final hasBlockProblems =
                            problemPersonnelByBlock.containsKey(
                          originalBlockIndex,
                        );
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
                          focusedPersonKey: widget.focusedPersonKey,
                          isExpanded: isFocusedBlock ||
                              visibleBlocks.length == 1 ||
                              (widget.isMobile &&
                                  blockIdx == 0 &&
                                  hasBlockProblems),
                          visiblePersonnelIndexes:
                              widget.previewFilterIsProblems
                                  ? problemPersonnelByBlock[originalBlockIndex]
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
            problemCount: totalActionCount,
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

  bool _blockHasProblem(int blockIndex, ParsedActivityBlock block) {
    return widget.problemLocations.any((loc) => loc.blockIndex == blockIndex) ||
        block.personnelList.isEmpty ||
        block.parsedDate.trim().isEmpty ||
        block.parsedActivityType.trim().isEmpty;
  }

  bool _personHasProblem(int blockIndex, int personIndex) {
    final person = widget.blocks[blockIndex].personnelList[personIndex];
    return !person.isMatched ||
        person.hasWarning ||
        widget.duplicates.containsKey('$blockIndex:$personIndex') ||
        widget.problemLocations.any(
          (loc) =>
              loc.blockIndex == blockIndex && loc.personIndex == personIndex,
        );
  }

  bool _matchesQuery(ParsedActivityBlock block, String query) {
    if (query.isEmpty) return true;
    final haystack = StringBuffer()
      ..write(' ${block.rawTitle}')
      ..write(' ${block.parsedTimName}')
      ..write(' ${block.parsedActivityType}')
      ..write(' ${block.parsedDate}')
      ..write(' ${block.parsedTimeRange ?? ''}');
    for (final person in block.personnelList) {
      haystack
        ..write(' ${person.rawRank}')
        ..write(' ${person.rawName}')
        ..write(' ${person.matchedRutbe ?? ''}')
        ..write(' ${person.matchedAdSoyad ?? ''}')
        ..write(' satır ${person.sourceLineNumber ?? ''}');
    }
    return haystack.toString().toLowerCase().contains(query);
  }
}

enum _PreviewFilter { problems, all, ready }

class _CorrectnessPanel extends StatelessWidget {
  const _CorrectnessPanel({
    required this.cardCount,
    required this.personnelCount,
    required this.dayCount,
    required this.criticalCount,
    required this.reviewCount,
    required this.actionCount,
    required this.hasBlocking,
    required this.compact,
    required this.onClearAll,
    required this.onStartWizard,
    this.onConfirmAllSuggestions,
  });

  final int cardCount;
  final int personnelCount;
  final int dayCount;
  final int criticalCount;
  final int reviewCount;
  final int actionCount;
  final bool hasBlocking;
  final bool compact;
  final VoidCallback onClearAll;
  final VoidCallback? onStartWizard;
  final VoidCallback? onConfirmAllSuggestions;

  @override
  Widget build(BuildContext context) {
    final actionText = actionCount == 0
        ? 'Tüm kontroller tamam'
        : 'Kaydetmeden önce $actionCount işlem tamamlanmalı';
    if (compact) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Row(
          children: [
            const Text(
              'Doğruluk Paneli',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            if (hasBlocking) ...[
              InkWell(
                onTap: onStartWizard,
                borderRadius: BorderRadius.circular(999),
                child: _StatusPill(
                  text: 'Kaydedilemiyor',
                  color: context.rejectedColor,
                  background: context.rejectedBgColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (criticalCount > 0 || reviewCount > 0) ...[
              Text(
                [
                  if (criticalCount > 0) '$criticalCount kritik hata',
                  if (reviewCount > 0) '$reviewCount inceleme',
                ].join(' • '),
                style: TextStyle(
                  color: hasBlocking
                      ? context.rejectedColor
                      : context.pendingColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.assignment_rounded,
                      value: '$cardCount',
                      label: 'kart',
                      color: context.accentOrOlive,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.groups_rounded,
                      value: '$personnelCount',
                      label: 'personel',
                      color: context.accentOrOlive,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.calendar_month_rounded,
                      value: '$dayCount',
                      label: 'gün',
                      color: context.accentOrOlive,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.error_rounded,
                      value: '$criticalCount',
                      label: 'kritik',
                      color: context.rejectedColor,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.info_rounded,
                      value: '$reviewCount',
                      label: 'inceleme',
                      color: context.pendingColor,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                actionText,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: hasBlocking
                      ? context.rejectedColor
                      : context.approvedColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onConfirmAllSuggestions != null) ...[
              const SizedBox(width: 6),
              FilledButton.icon(
                key: const Key('bulk-confirm-all-suggestions'),
                onPressed: onConfirmAllSuggestions,
                icon: const Icon(Icons.done_all_rounded, size: 14),
                label: const Text(
                  'Tümünü Onayla',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.approvedColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            IconButton(
              onPressed: onClearAll,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              tooltip: 'Tümünü Temizle',
            ),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.fromLTRB(14, compact ? 8 : 12, 8, compact ? 8 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Doğruluk Paneli',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hasBlocking)
                      InkWell(
                        onTap: onStartWizard,
                        borderRadius: BorderRadius.circular(999),
                        child: _StatusPill(
                          text: 'Kaydedilemiyor',
                          color: context.rejectedColor,
                          background: context.rejectedBgColor,
                        ),
                      ),
                    if (onConfirmAllSuggestions != null)
                      FilledButton.icon(
                        key: const Key('bulk-confirm-all-suggestions'),
                        onPressed: onConfirmAllSuggestions,
                        icon: const Icon(Icons.done_all_rounded, size: 14),
                        label: const Text(
                          'Tümünü Onayla',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.approvedColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClearAll,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                tooltip: 'Tümünü Temizle',
              ),
            ],
          ),
          Text(
            actionText,
            style: TextStyle(
              color:
                  hasBlocking ? context.rejectedColor : context.approvedColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (criticalCount > 0 || reviewCount > 0) ...[
            const SizedBox(height: 3),
            Text(
              [
                if (criticalCount > 0) '$criticalCount kritik hata',
                if (reviewCount > 0) '$reviewCount inceleme',
              ].join(' • '),
              style: TextStyle(
                color:
                    hasBlocking ? context.rejectedColor : context.pendingColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.assignment_rounded,
                  value: '$cardCount',
                  label: 'kart',
                  color: context.accentOrOlive,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.groups_rounded,
                  value: '$personnelCount',
                  label: 'personel',
                  color: context.accentOrOlive,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.calendar_month_rounded,
                  value: '$dayCount',
                  label: 'gün',
                  color: context.accentOrOlive,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.error_rounded,
                  value: '$criticalCount',
                  label: 'kritik',
                  color: context.rejectedColor,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.info_rounded,
                  value: '$reviewCount',
                  label: 'inceleme',
                  color: context.pendingColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FilterSearchStrip extends StatelessWidget {
  const _FilterSearchStrip({
    required this.selected,
    required this.problemCount,
    required this.allCount,
    required this.readyCount,
    required this.controller,
    required this.onChanged,
    required this.onProblems,
    required this.onAll,
    required this.onReady,
  });

  final _PreviewFilter selected;
  final int problemCount;
  final int allCount;
  final int readyCount;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onProblems;
  final VoidCallback onAll;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final filters = _SegmentedFilters(
      selected: selected,
      problemCount: problemCount,
      allCount: allCount,
      readyCount: readyCount,
      onProblems: onProblems,
      onAll: onAll,
      onReady: onReady,
    );
    final search = TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Personel, tim veya satır ara',
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.cardBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.cardBorderColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            children: [
              Expanded(child: filters),
              const SizedBox(width: 10),
              Expanded(child: search),
            ],
          );
        }
        return Column(
          children: [
            filters,
            const SizedBox(height: 8),
            search,
          ],
        );
      },
    );
  }
}

class _SegmentedFilters extends StatelessWidget {
  const _SegmentedFilters({
    required this.selected,
    required this.problemCount,
    required this.allCount,
    required this.readyCount,
    required this.onProblems,
    required this.onAll,
    required this.onReady,
  });

  final _PreviewFilter selected;
  final int problemCount;
  final int allCount;
  final int readyCount;
  final VoidCallback onProblems;
  final VoidCallback onAll;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              label: 'Sorunlar',
              count: problemCount,
              selected: selected == _PreviewFilter.problems,
              onTap: onProblems,
            ),
          ),
          Expanded(
            child: _FilterButton(
              label: 'Tümü',
              count: allCount,
              selected: selected == _PreviewFilter.all,
              onTap: onAll,
            ),
          ),
          Expanded(
            child: _FilterButton(
              label: 'Hazır',
              count: readyCount,
              selected: selected == _PreviewFilter.ready,
              onTap: onReady,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.accentOrOlive : context.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? context.accentOrOlive.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 5),
              _CountBadge(count: count, selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? context.accentOrOlive : context.cardBorderColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: selected
              ? context.customColors.onAccentOrOlive
              : context.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActiveIssueCard extends StatelessWidget {
  const _ActiveIssueCard({
    required this.problemLocations,
    required this.parseIssues,
    required this.activeIssueFocusIndex,
    required this.onFix,
  });

  final List<ProblemLocation> problemLocations;
  final List<BulkParseIssue> parseIssues;
  final int activeIssueFocusIndex;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    if (problemLocations.isEmpty && parseIssues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.approvedColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.approvedColor.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.task_alt_rounded, color: context.approvedColor),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tüm kontroller tamam',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    final showingParseIssue = problemLocations.isEmpty;
    final total =
        showingParseIssue ? parseIssues.length : problemLocations.length;
    final safeIndex =
        activeIssueFocusIndex < 0 ? 0 : activeIssueFocusIndex % total;
    final parseIssue = showingParseIssue ? parseIssues[safeIndex] : null;
    final issue = showingParseIssue ? null : problemLocations[safeIndex];
    final isCritical = parseIssue?.isBlocking ?? issue!.isCritical;
    final color = isCritical ? context.rejectedColor : context.pendingColor;
    final title = parseIssue?.message ?? _issueTitle(issue!);
    final reason = parseIssue == null
        ? _issueReason(issue!)
        : [
            if (parseIssue.rawLine.trim().isNotEmpty) parseIssue.rawLine.trim(),
            if (parseIssue.lineNumber > 0) 'Satır ${parseIssue.lineNumber}',
          ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isCritical ? Icons.error_rounded : Icons.info_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${safeIndex + 1} / $total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isCritical ? 'Kritik' : 'İnceleme',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  softWrap: true,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  softWrap: true,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onFix,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: const Text(
              'Düzelt',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _issueTitle(ProblemLocation issue) {
    final text = issue.description;
    final dashIndex = text.indexOf(' - ');
    final withoutLine = text.replaceFirst(RegExp(r'^Satır \d+:\s*'), '');
    if (dashIndex >= 0) {
      return withoutLine.split(' - ').first.trim();
    }
    return withoutLine.trim();
  }

  static String _issueReason(ProblemLocation issue) {
    final parts = <String>[];
    final text = issue.description;
    final dashIndex = text.indexOf(' - ');
    if (dashIndex >= 0) {
      parts.add(text.substring(dashIndex + 3).trim());
    } else {
      parts.add(text);
    }
    if (issue.sourceLineNumber != null) {
      parts.add('Satır ${issue.sourceLineNumber}');
    }
    return parts.join(' • ');
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
