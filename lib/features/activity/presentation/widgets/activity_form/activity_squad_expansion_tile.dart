import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_personnel_duty_row.dart';

class ActivitySquadExpansionTile extends StatelessWidget {
  const ActivitySquadExpansionTile({
    required this.squadName,
    required this.members,
    required this.assignments,
    required this.isAdmin,
    required this.adminOnlyDuties,
    required this.generalDuties,
    required this.onBatchAssign,
    required this.onDutyChanged,
    super.key,
  });

  final String squadName;
  final List<PersonelTableData> members;
  final Map<int, String> assignments;
  final bool isAdmin;
  final List<String> adminOnlyDuties;
  final List<String> generalDuties;
  final void Function(String duty) onBatchAssign;
  final void Function(int personId, String duty) onDutyChanged;

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        members.where((p) => assignments.containsKey(p.id)).length;
    final isSelected = selectedCount > 0;

    return Card(
      elevation: 0,
      color: isSelected
          ? context.accentSubtleBg
          : context.colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? context.accentOrOlive
              : context.cardBorderColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
        title: Text(
          squadName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.accentOrOlive,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              child: isSelected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: context.accentOrOlive,
                      size: 20,
                    )
                  : null,
            ),
            SizedBox(
              width: 44,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 22,
                ),
                tooltip: 'Time Toplu Görev Ata',
                onSelected: onBatchAssign,
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      '⚡ TIME TOPLU GÖREV ATA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: context.accentOrOlive,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...generalDuties.map(
                    (d) => PopupMenuItem<String>(
                      value: d,
                      child: Text('Tümüne "$d" Ata'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'CLEAR',
                    child: Text(
                      'Görevleri Sıfırla',
                      style: TextStyle(
                        color: context.rejectedColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 100,
              height: 28,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: context.accentOrOlive,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${members.length} personel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.onAccentOrOlive,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        children: [
          Divider(
            height: 1,
            color: context.cardBorderColor,
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: context.cardBorderColor,
            ),
            itemBuilder: (context, index) {
              final p = members[index];
              final currentSelection = assignments[p.id];

              final availableDuties = [
                if (isAdmin) ...adminOnlyDuties,
                ...generalDuties,
                if (!isAdmin &&
                    currentSelection != null &&
                    adminOnlyDuties.contains(currentSelection))
                  currentSelection,
              ];

              return ActivityPersonnelDutyRow(
                personnel: p,
                currentSelection: currentSelection,
                availableDuties: availableDuties,
                adminOnlyDuties: adminOnlyDuties,
                onDutyChanged: (val) {
                  if (val != null) {
                    onDutyChanged(p.id, val);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
