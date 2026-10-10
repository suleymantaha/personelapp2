import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'activity_selected_squad_group.dart';

class ActivitySelectedPersonnelCard extends StatelessWidget {
  const ActivitySelectedPersonnelCard({
    required this.personnel,
    required this.squadNames,
    required this.draft,
    required this.onRemovePersonnel,
    required this.onEditPersonnel,
    required this.onEditAssignment,
    required this.onAssignSquad,
    super.key,
  });

  final List<PersonelTableData> personnel;
  final Map<int, String> squadNames;
  final ActivityFormDraft draft;
  final ValueChanged<int> onRemovePersonnel;
  final VoidCallback onEditPersonnel;
  final ValueChanged<PersonelTableData> onEditAssignment;
  final void Function(String squadName, List<PersonelTableData> personnel)
      onAssignSquad;

  @override
  Widget build(BuildContext context) {
    final grouped = <int?, List<PersonelTableData>>{};
    for (final person in personnel) {
      grouped.putIfAbsent(person.timId, () => []).add(person);
    }
    final groupIds = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final nameA = squadNames[a] ?? '';
        final nameB = squadNames[b] ?? '';
        final weightA = MilitaryStructureHelper.getSquadOrderWeight(nameA);
        final weightB = MilitaryStructureHelper.getSquadOrderWeight(nameB);
        return weightA != weightB
            ? weightA.compareTo(weightB)
            : nameA.compareTo(nameB);
      });

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.accentOrOlive,
                  foregroundColor: context.onAccentOrOlive,
                  child: const Icon(Icons.groups_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.activitySelectedPersonnelCount(personnel.length),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('edit-personnel-selection'),
                  onPressed: onEditPersonnel,
                  child: Text(context.l10n.commonEdit),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final timId in groupIds)
              ActivitySelectedSquadGroup(
                squadName: timId == null
                    ? context.l10n.bulkImportUnassignedOrOtherPersonnel
                    : (squadNames[timId] ?? context.l10n.personnelPickerUnknownTeam),
                personnel: grouped[timId]!,
                draft: draft,
                onRemovePersonnel: onRemovePersonnel,
                onEditAssignment: onEditAssignment,
                onAssignDuty: () => onAssignSquad(
                  timId == null
                      ? context.l10n.bulkImportUnassignedOrOtherPersonnel
                      : (squadNames[timId] ?? context.l10n.personnelPickerUnknownTeam),
                  grouped[timId]!,
                ),
              ),
            if (personnel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.activitySelectedPersonnelEditHint,
                style: context.textStyleSecondary.copyWith(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
