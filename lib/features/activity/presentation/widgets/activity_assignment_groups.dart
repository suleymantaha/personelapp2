import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

class ActivityAssignmentGroups extends StatefulWidget {
  const ActivityAssignmentGroups({
    required this.assignments,
    required this.personnelById,
    required this.squadNames,
    required this.assignmentBuilder,
    this.selectedSquadId,
    super.key,
  });

  final List<FaaliyetPersonelAtamaTableData> assignments;
  final Map<int, PersonelTableData> personnelById;
  final Map<int, String> squadNames;
  final int? selectedSquadId;
  final Widget Function(FaaliyetPersonelAtamaTableData assignment)
      assignmentBuilder;

  @override
  State<ActivityAssignmentGroups> createState() =>
      _ActivityAssignmentGroupsState();
}

class _ActivityAssignmentGroupsState extends State<ActivityAssignmentGroups> {
  int? _expandedSquadId;
  bool _hasExpandedTimDisi = false;

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
      final squadId = widget.personnelById[assignment.personelId]?.timId;
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

    final squadIds = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final nameA = widget.squadNames[a] ?? 'Bilinmeyen Tim';
        final nameB = widget.squadNames[b] ?? 'Bilinmeyen Tim';
        final weightA = MilitaryStructureHelper.getSquadOrderWeight(nameA);
        final weightB = MilitaryStructureHelper.getSquadOrderWeight(nameB);
        if (weightA != weightB) return weightA.compareTo(weightB);
        return nameA.compareTo(nameB);
      });

    return Column(
      children: squadIds.map((squadId) {
        final assignments = grouped[squadId]!;
        final teamName = squadId == null
            ? 'Tim Dışı'
            : (widget.squadNames[squadId] ?? 'Bilinmeyen Tim');
        final expanded =
            squadId == null ? _hasExpandedTimDisi : _expandedSquadId == squadId;

        return Card(
          key: Key('activity-team-card-$squadId'),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: context.cardBorderColor),
          ),
          child: Column(
            children: [
              ListTile(
                key: Key('activity-team-header-$squadId'),
                dense: true,
                leading: Icon(
                  Icons.shield_outlined,
                  size: 19,
                  color: context.accentOrOlive,
                ),
                title: Text(
                  '$teamName — ${assignments.length} kişi',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () => setState(() {
                  if (squadId == null) {
                    _hasExpandedTimDisi = !_hasExpandedTimDisi;
                    _expandedSquadId = null;
                  } else {
                    _expandedSquadId = expanded ? null : squadId;
                    _hasExpandedTimDisi = false;
                  }
                }),
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: Column(
                    children: assignments
                        .map(widget.assignmentBuilder)
                        .toList(growable: false),
                  ),
                ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}
