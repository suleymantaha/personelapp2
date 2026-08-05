import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_personnel_duty_row.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/batch_duty_picker.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.only(bottom: 14),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle_rounded,
                color: context.accentOrOlive,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                squadName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.accentOrOlive,
                ),
              ),
            ),
            IconButton(
              key: ValueKey('batch-duty-button-$squadName'),
              icon: const Icon(Icons.more_vert_rounded, size: 22),
              tooltip: 'Time Toplu Görev Ata',
              onPressed: () async {
                final duty = await showBatchDutyPicker(
                  context,
                  squadName: squadName,
                  duties: generalDuties,
                );
                if (duty != null) onBatchAssign(duty);
              },
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 100,
              height: 32,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
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

              return Card(
                elevation: 0,
                color: currentSelection != null
                    ? context.accentSubtleBg
                    : context.colorScheme.surface,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: currentSelection != null
                        ? context.accentOrOlive
                        : context.cardBorderColor,
                    width: currentSelection != null ? 1.5 : 1,
                  ),
                ),
                child: ActivityPersonnelDutyRow(
                  personnel: p,
                  currentSelection: currentSelection,
                  availableDuties: availableDuties,
                  adminOnlyDuties: adminOnlyDuties,
                  onDutyChanged: (val) {
                    if (val != null) {
                      onDutyChanged(p.id, val);
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
