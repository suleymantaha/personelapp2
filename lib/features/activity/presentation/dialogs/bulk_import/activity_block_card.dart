import 'package:flutter/material.dart';
import 'activity_block_header.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';

class ActivityBlockCard extends StatefulWidget {
  const ActivityBlockCard({
    required this.block,
    required this.blockIdx,
    required this.duplicates,
    required this.allSquads,
    required this.focusedIssue,
    required this.onEditBlock,
    required this.onRemoveBlock,
    required this.onSelectPersonnel,
    required this.onRemovePerson,
    this.onConfirmPersonnelSuggestion,
    this.onAddNewPersonnel,
    this.cardKey,
    this.personKeys,
    this.visiblePersonnelIndexes,
    this.isExpanded,
    this.onToggleExpand,
    super.key,
  });

  final ParsedActivityBlock block;
  final int blockIdx;
  final Map<String, List<String>> duplicates;
  final List<TimTableData> allSquads;
  final BulkIssueFocus? focusedIssue;
  final void Function(int blockIdx) onEditBlock;
  final void Function(int blockIdx) onRemoveBlock;
  final void Function(int blockIdx, int personIdx) onSelectPersonnel;
  final void Function(int blockIdx, int personIdx) onRemovePerson;
  final void Function(int blockIdx, int personIdx)?
      onConfirmPersonnelSuggestion;
  final void Function(int blockIdx, int personIdx)? onAddNewPersonnel;
  final Key? cardKey;
  final Map<String, GlobalKey>? personKeys;
  final List<int>? visiblePersonnelIndexes;
  final bool? isExpanded;
  final VoidCallback? onToggleExpand;

  @override
  State<ActivityBlockCard> createState() => _ActivityBlockCardState();
}

class _ActivityBlockCardState extends State<ActivityBlockCard> {
  bool? _userManualExpanded;

  bool get _hasBlockProblems {
    if (widget.block.personnelList.isEmpty) return true;
    if (widget.block.parsedDate.trim().isEmpty) return true;
    if (widget.block.parsedActivityType.trim().isEmpty) return true;
    for (var i = 0; i < widget.block.personnelList.length; i++) {
      final p = widget.block.personnelList[i];
      final isDup = widget.duplicates.containsKey('${widget.blockIdx}:$i');
      if (!p.isMatched || p.hasWarning || isDup) return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant ActivityBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedIssue != oldWidget.focusedIssue) {
      _userManualExpanded = null;
    }
    if (widget.isExpanded != oldWidget.isExpanded &&
        widget.isExpanded != null) {
      _userManualExpanded = widget.isExpanded;
    }
  }

  void _toggleExpand() {
    if (widget.onToggleExpand != null) {
      widget.onToggleExpand!();
    } else {
      setState(() {
        _userManualExpanded = !_effectiveIsExpanded;
      });
    }
  }

  bool get _effectiveIsExpanded {
    if (widget.focusedIssue != null) {
      return widget.focusedIssue!.matchesBlock(widget.blockIdx);
    }
    if (_userManualExpanded != null) {
      return _userManualExpanded!;
    }
    if (widget.isExpanded != null) {
      return widget.isExpanded!;
    }
    return _hasBlockProblems;
  }

  @override
  Widget build(BuildContext context) {
    final isBlockFocused =
        widget.focusedIssue?.matchesBlock(widget.blockIdx) ?? false;
    final effectiveIsExpanded = _effectiveIsExpanded;

    final personnelIndexes = widget.visiblePersonnelIndexes ??
        List<int>.generate(widget.block.personnelList.length, (index) => index);
    final problemCount = widget.block.personnelList.isEmpty
        ? 1
        : widget.visiblePersonnelIndexes?.length ?? 0;

    int unmatchedCount = 0;
    int warningCount = 0;
    for (var i = 0; i < widget.block.personnelList.length; i++) {
      final p = widget.block.personnelList[i];
      final isDup = widget.duplicates.containsKey('${widget.blockIdx}:$i');
      if (!p.isMatched) {
        unmatchedCount++;
      } else if (p.hasWarning || isDup) {
        warningCount++;
      }
    }

    final hasProblems = unmatchedCount > 0 ||
        warningCount > 0 ||
        widget.block.personnelList.isEmpty;
    final borderColor = isBlockFocused
        ? (unmatchedCount > 0 ? context.rejectedColor : context.warningColor)
        : (hasProblems
            ? (unmatchedCount > 0
                ? context.rejectedColor
                : context.warningColor)
            : context.cardBorderColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isBlockFocused ? 2.5 : (hasProblems ? 1.2 : 1.0),
        ),
        boxShadow: isBlockFocused
            ? [
                BoxShadow(
                  color: (unmatchedCount > 0
                          ? context.rejectedColor
                          : context.warningColor)
                      .withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        key: widget.cardKey,
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ActivityBlockHeader(
              block: widget.block,
              blockIdx: widget.blockIdx,
              visiblePersonnelIndexes: widget.visiblePersonnelIndexes,
              problemCount: problemCount,
              unmatchedCount: unmatchedCount,
              warningCount: warningCount,
              isBlockFocused: isBlockFocused,
              effectiveIsExpanded: effectiveIsExpanded,
              onToggleExpand: _toggleExpand,
              onEditBlock: widget.onEditBlock,
              onRemoveBlock: widget.onRemoveBlock,
            ),

            // Body (Only rendered if expanded)
            if (effectiveIsExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: widget.block.personnelList.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.rejectedColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Bu kartta personel kalmadı. Kartı silin veya metni yeniden ayrıştırın.',
                          style: TextStyle(color: context.rejectedColor),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: personnelIndexes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, visibleIndex) {
                          final pIdx = personnelIndexes[visibleIndex];
                          final item = widget.block.personnelList[pIdx];
                          final duplicateWith =
                              widget.duplicates['${widget.blockIdx}:$pIdx'];
                          final personKey = '${widget.blockIdx}:$pIdx';
                          final isFocused = widget.focusedIssue?.matchesPerson(
                                widget.blockIdx,
                                pIdx,
                              ) ??
                              false;
                          final registeredTeamName = widget.allSquads
                              .where((team) => team.id == item.matchedTimId)
                              .map((team) => team.timAdi)
                              .firstOrNull;
                          final listTeamName =
                              widget.block.parsedTimName.trim().isNotEmpty
                                  ? widget.block.parsedTimName
                                  : registeredTeamName ?? '';
                          final itemKey = widget.personKeys?.putIfAbsent(
                                personKey,
                                () => GlobalKey(),
                              ) ??
                              Key('bulk-person-${widget.blockIdx}-$pIdx');
                          return PersonnelMatchCard(
                            key: itemKey,
                            item: item,
                            teamName: listTeamName,
                            registeredTeamName: registeredTeamName,
                            duplicateAssignments: duplicateWith,
                            isFocused: isFocused,
                            onSelect: () =>
                                widget.onSelectPersonnel(widget.blockIdx, pIdx),
                            onDelete: () =>
                                widget.onRemovePerson(widget.blockIdx, pIdx),
                            onConfirmSuggestion:
                                widget.onConfirmPersonnelSuggestion != null
                                    ? () =>
                                        widget.onConfirmPersonnelSuggestion!(
                                            widget.blockIdx, pIdx)
                                    : null,
                            onAddNewPerson: widget.onAddNewPersonnel != null
                                ? () => widget.onAddNewPersonnel!(
                                    widget.blockIdx, pIdx)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
