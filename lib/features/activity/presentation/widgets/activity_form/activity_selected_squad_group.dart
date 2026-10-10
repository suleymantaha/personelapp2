import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'activity_compact_personnel_row.dart';

class ActivitySelectedSquadGroup extends StatelessWidget {
  const ActivitySelectedSquadGroup({
    required this.squadName,
    required this.personnel,
    required this.draft,
    required this.onRemovePersonnel,
    required this.onEditAssignment,
    required this.onAssignDuty,
    super.key,
  });

  final String squadName;
  final List<PersonelTableData> personnel;
  final ActivityFormDraft draft;
  final ValueChanged<int> onRemovePersonnel;
  final ValueChanged<PersonelTableData> onEditAssignment;
  final VoidCallback onAssignDuty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.accentSubtleBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: ExpansionTile(
        key: ValueKey('selected-squad-group-$squadName'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(Icons.groups_rounded, color: context.accentOrOlive),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 190;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    squadName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    compact
                        ? '${personnel.length}'
                        : context.l10n.activityPersonnelCountBadge(personnel.length),
                    style: TextStyle(
                      color: context.accentOrOlive,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('assign-squad-duty-$squadName'),
                  tooltip: context.l10n.activityBatchDutyAssignSquadTooltip(squadName),
                  visualDensity: VisualDensity.compact,
                  onPressed: onAssignDuty,
                  icon: const Icon(Icons.assignment_ind_outlined, size: 20),
                ),
              ],
            );
          },
        ),
        children: [
          DecoratedBox(
            key: ValueKey('selected-squad-list-$squadName'),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var index = 0; index < personnel.length; index++) ...[
                  ActivityCompactPersonnelRow(
                    person: personnel[index],
                    draft: draft,
                    onRemove: () => onRemovePersonnel(personnel[index].id),
                    onTap: () => onEditAssignment(personnel[index]),
                  ),
                  if (index != personnel.length - 1)
                    Divider(
                      height: 1,
                      indent: 12,
                      endIndent: 8,
                      color: context.cardBorderColor,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
