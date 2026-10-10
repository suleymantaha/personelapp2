import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/presentation/widgets/collapsible_squad_card.dart';

class ActivityAssignmentGroups extends StatefulWidget {
  const ActivityAssignmentGroups({
    required this.assignments,
    required this.personnelById,
    required this.squadNames,
    required this.assignmentBuilder,
    this.selectedSquadId,
    this.onExportSelected,
    this.onDeleteSelected,
    this.onTransferSquad,
    super.key,
  });

  final List<FaaliyetPersonelAtamaTableData> assignments;
  final Map<int, PersonelTableData> personnelById;
  final Map<int, String> squadNames;
  final int? selectedSquadId;
  final Future<void> Function(List<FaaliyetPersonelAtamaTableData> assignments)?
  onExportSelected;
  final Future<void> Function(List<FaaliyetPersonelAtamaTableData> assignments)?
  onDeleteSelected;

  /// Called when the user taps "Taşı" on a squad header.
  /// Receives [squadId] (nullable = "Tim Dışı") and [squadName].
  final Future<void> Function(int? squadId, String squadName)? onTransferSquad;
  final Widget Function(FaaliyetPersonelAtamaTableData assignment)
  assignmentBuilder;

  @override
  State<ActivityAssignmentGroups> createState() =>
      _ActivityAssignmentGroupsState();
}

class _ActivityAssignmentGroupsState extends State<ActivityAssignmentGroups> {
  int? _expandedSquadId;
  bool _hasExpandedTimDisi = false;
  final Set<int?> _selectedSquadIds = {};

  void _toggleSquadSelection(int? squadId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedSquadIds.contains(squadId)) {
        _selectedSquadIds.remove(squadId);
      } else {
        _selectedSquadIds.add(squadId);
      }
    });
  }

  void _onSquadLongPress(int? squadId) {
    HapticFeedback.mediumImpact();
    _toggleSquadSelection(squadId);
  }

  @override
  void initState() {
    super.initState();
    _expandedSquadId = widget.selectedSquadId;
  }

  @override
  void didUpdateWidget(covariant ActivityAssignmentGroups oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSquadId != widget.selectedSquadId) {
      _expandedSquadId = widget.selectedSquadId;
      _hasExpandedTimDisi = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <int?, List<FaaliyetPersonelAtamaTableData>>{};
    for (final assignment in widget.assignments) {
      final squadId = assignment.gorevTimId;
      grouped.putIfAbsent(squadId, () => []).add(assignment);
    }
    for (final assignments in grouped.values) {
      assignments.sort((a, b) {
        final personA = widget.personnelById[a.personelId];
        final personB = widget.personnelById[b.personelId];
        final rankComparison = getRankWeight(
          personA?.rutbe ?? '',
        ).compareTo(getRankWeight(personB?.rutbe ?? ''));
        if (rankComparison != 0) return rankComparison;
        return (personA?.adSoyad ?? '').compareTo(personB?.adSoyad ?? '');
      });
    }

    final squadIds =
        grouped.keys.toList()..sort((a, b) {
          if (a == null) return 1;
          if (b == null) return -1;
          final nameA = widget.squadNames[a] ?? context.l10n.activityDetailUnknownSquad;
          final nameB = widget.squadNames[b] ?? context.l10n.activityDetailUnknownSquad;
          final weightA = MilitaryStructureHelper.getSquadOrderWeight(nameA);
          final weightB = MilitaryStructureHelper.getSquadOrderWeight(nameB);
          if (weightA != weightB) return weightA.compareTo(weightB);
          return nameA.compareTo(nameB);
        });

    final isSelectionMode = _selectedSquadIds.isNotEmpty;

    return Column(
      children: [
        if (isSelectionMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: context.l10n.cancelSelectionTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => setState(_selectedSquadIds.clear),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    context.l10n.activitySelectedSquadCount(_selectedSquadIds.length),
                    style: TextStyle(
                      color: context.accentOrOlive,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.onExportSelected != null)
                  FilledButton.tonalIcon(
                    key: const Key('export-selected-teams'),
                    onPressed:
                        () => widget.onExportSelected!([
                          for (final id in _selectedSquadIds) ...?grouped[id],
                        ]),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: Text(context.l10n.commonPrint),
                  ),
                if (widget.onDeleteSelected != null) ...[
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    key: const Key('delete-selected-teams'),
                    tooltip: context.l10n.activityDeleteSelectedSquadsTooltip,
                    onPressed: () async {
                      final selectedAssignments = [
                        for (final id in _selectedSquadIds) ...?grouped[id],
                      ];
                      await widget.onDeleteSelected!(selectedAssignments);
                      if (mounted) {
                        setState(_selectedSquadIds.clear);
                      }
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: context.rejectedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ...squadIds.map((squadId) {
          final assignments = grouped[squadId]!;
          final teamName =
              squadId == null
                  ? grouped[squadId]!.first.gorevTimAdi ??
                      context.l10n.activityDetailUnknownSquadHistory
                  : (widget.squadNames[squadId] ??
                      context.l10n.activityDetailUnknownSquad);
          final expanded =
              squadId == null
                  ? _hasExpandedTimDisi
                  : _expandedSquadId == squadId;
          final isSelected = _selectedSquadIds.contains(squadId);

          return CollapsibleSquadCard(
            cardKey: Key('activity-team-card-$squadId'),
            headerKey: Key('activity-team-header-$squadId'),
            title: context.l10n.activitySquadCardTitle(
              teamName,
              assignments.length,
            ),
            expanded: expanded,
            isSelected: isSelected,
            selectionMode: isSelectionMode,
            onLongPress: () => _onSquadLongPress(squadId),
            onTap: isSelectionMode ? () => _toggleSquadSelection(squadId) : null,
            actions: [
              if (widget.onTransferSquad != null && squadId != null && !isSelectionMode)
                IconButton(
                  key: Key('activity-team-transfer-$squadId'),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  tooltip: context.l10n.activityTransferSquadTooltip(teamName),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.onTransferSquad!(squadId, teamName),
                ),
            ],
            onToggle:
                () => setState(() {
                  if (squadId == null) {
                    _hasExpandedTimDisi = !_hasExpandedTimDisi;
                    _expandedSquadId = null;
                  } else {
                    _expandedSquadId = expanded ? null : squadId;
                    _hasExpandedTimDisi = false;
                  }
                }),
            children: assignments
                .map(widget.assignmentBuilder)
                .toList(growable: false),
          );
        }),
      ],
    );
  }
}
