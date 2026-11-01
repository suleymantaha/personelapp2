import 'team_selection_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personelapp2/core/database/database.dart';

import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/personnel/domain/personnel_display_order.dart';
import 'package:personelapp2/features/activity/presentation/widgets/collapsible_squad_card.dart';

class ActivityAssignmentGroups extends StatefulWidget {
  const ActivityAssignmentGroups({
    required this.assignments,
    required this.personnelById,
    required this.squadNames,
    required this.assignmentBuilder,
    this.squadOrders = const {},
    this.selectedSquadId,
    this.onExportSelected,
    this.onDeleteSelected,
    this.onReassignSelected,
    this.onTransferSquad,
    this.onCreateReportSelected,
    this.usePersistentToolbar = false,
    this.leadingAction,
    super.key,
  });

  final bool usePersistentToolbar;
  final Widget? leadingAction;
  final Future<void> Function(List<FaaliyetPersonelAtamaTableData>)?
      onCreateReportSelected;
  final List<FaaliyetPersonelAtamaTableData> assignments;
  final Map<int, PersonelTableData> personnelById;
  final Map<int, String> squadNames;
  final Map<int, int?> squadOrders;
  final int? selectedSquadId;
  final Future<void> Function(List<FaaliyetPersonelAtamaTableData> assignments)?
      onExportSelected;
  final Future<void> Function(List<FaaliyetPersonelAtamaTableData> assignments)?
      onDeleteSelected;

  final Future<void> Function(List<FaaliyetPersonelAtamaTableData> assignments)?
      onReassignSelected;

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
  bool _selectionMode = false;
  String _toolbarFingerprint = '';
  int? _expandedSquadId;
  bool _hasExpandedTimDisi = false;
  final Set<int?> _selectedSquadIds = {};

  void _toggleSquadSelection(int? squadId) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectionMode = true;
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
    final hadSelection = _selectedSquadIds.isNotEmpty;
    _selectedSquadIds.retainAll(widget.assignments.map((a) => a.gorevTimId));
    if (hadSelection && _selectedSquadIds.isEmpty) _selectionMode = false;
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
        // A position in a new team must not reorder historical assignments.
        final saved = compareSavedOrder(
          personA?.timId == a.gorevTimId ? personA?.sortOrder : null,
          personB?.timId == b.gorevTimId ? personB?.sortOrder : null,
        );
        if (saved != 0) return saved;
        final name = (personA?.adSoyad ?? '').compareTo(personB?.adSoyad ?? '');
        return name != 0 ? name : a.id.compareTo(b.id);
      });
    }

    final squadIds = grouped.keys.toList()
      ..sort((a, b) {
        if (a == b) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        final saved =
            compareSavedOrder(widget.squadOrders[a], widget.squadOrders[b]);
        if (saved != 0) return saved;
        final nameA =
            widget.squadNames[a] ?? context.l10n.activityDetailUnknownSquad;
        final nameB =
            widget.squadNames[b] ?? context.l10n.activityDetailUnknownSquad;
        final weightA = MilitaryStructureHelper.getSquadOrderWeight(nameA);
        final weightB = MilitaryStructureHelper.getSquadOrderWeight(nameB);
        if (weightA != weightB) return weightA.compareTo(weightB);
        final name = nameA.compareTo(nameB);
        return name != 0 ? name : a.compareTo(b);
      });

    final isSelectionMode = _selectionMode || _selectedSquadIds.isNotEmpty;
    final selectedRows = [for (final id in _selectedSquadIds) ...?grouped[id]];
    void cancel() => setState(() {
          _selectedSquadIds.clear();
          _selectionMode = false;
        });
    final toolbar = isSelectionMode
        ? TeamSelectionToolbar(
            teamCount: _selectedSquadIds.length,
            personCount: selectedRows.map((r) => r.personelId).toSet().length,
            onCancel: cancel,
            onSelectAll: () =>
                setState(() => _selectedSquadIds.addAll(grouped.keys)),
            onReassign: widget.onReassignSelected == null
                ? null
                : () => widget.onReassignSelected!(selectedRows),
            onExport: widget.onExportSelected == null
                ? null
                : () => widget.onExportSelected!(selectedRows),
            onDelete: widget.onDeleteSelected == null
                ? null
                : () => widget.onDeleteSelected!(selectedRows),
            onReport: widget.onCreateReportSelected == null
                ? null
                : () => widget.onCreateReportSelected!(selectedRows),
          )
        : null;
    final fingerprint =
        '$isSelectionMode|${widget.onDeleteSelected != null}|${widget.onReassignSelected != null}|${_selectedSquadIds.join(',')}|${widget.assignments.map((a) => '${a.id}:${a.gorevTimId}:${a.durum}:${a.gorevVeyaIzin}').join(',')}';
    if (widget.usePersistentToolbar && fingerprint != _toolbarFingerprint) {
      _toolbarFingerprint = fingerprint;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) TeamSelectionNotification(toolbar).dispatch(context);
      });
    }

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) cancel();
      },
      child: Column(children: [
        if (!isSelectionMode &&
            (widget.leadingAction != null || squadIds.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  if (widget.leadingAction != null)
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: widget.leadingAction!))
                  else
                    const Spacer(),
                  if (squadIds.isNotEmpty)
                    TextButton.icon(
                      key: const Key('team-selection-start'),
                      onPressed: () => setState(() => _selectionMode = true),
                      icon: const Icon(Icons.checklist),
                      label: const Text('Tim seç'),
                    ),
                ],
              ),
            ),
          ),
        if (!widget.usePersistentToolbar && toolbar != null) toolbar,
        ...squadIds.map((squadId) {
          final assignments = grouped[squadId]!;
          final teamName = assignments.first.gorevTimAdi ??
              context.l10n.activityDetailUnknownSquadHistory;
          final expanded = squadId == null
              ? _hasExpandedTimDisi
              : _expandedSquadId == squadId;
          final isSelected = _selectedSquadIds.contains(squadId);

          return CollapsibleSquadCard(
            cardKey: Key('activity-team-card-$squadId'),
            headerKey: Key('activity-team-header-$squadId'),
            expandKey: Key('activity-team-expand-$squadId'),
            title: teamName,
            personCount: assignments.length,
            expanded: expanded,
            isSelected: isSelected,
            selectionMode: isSelectionMode,
            onLongPress: () => _onSquadLongPress(squadId),
            onTap:
                isSelectionMode ? () => _toggleSquadSelection(squadId) : null,
            actions: [
              if (widget.onTransferSquad != null &&
                  squadId != null &&
                  !isSelectionMode)
                IconButton(
                  key: Key('activity-team-transfer-$squadId'),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  tooltip: context.l10n.activityTransferSquadTooltip(teamName),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.onTransferSquad!(squadId, teamName),
                ),
            ],
            onToggle: () => setState(() {
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
      ]),
    );
  }
}
