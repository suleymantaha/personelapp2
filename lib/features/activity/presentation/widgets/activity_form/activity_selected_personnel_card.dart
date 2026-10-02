import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
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
                    '${personnel.length} personel seçildi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('edit-personnel-selection'),
                  onPressed: onEditPersonnel,
                  child: const Text('Düzenle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final timId in groupIds)
              ActivitySelectedSquadGroup(
                squadName: timId == null
                    ? 'Timsiz / Diğer Personeller'
                    : (squadNames[timId] ?? 'Bilinmeyen Tim'),
                personnel: grouped[timId]!,
                draft: draft,
                onRemovePersonnel: onRemovePersonnel,
                onEditAssignment: onEditAssignment,
                onAssignDuty: () => onAssignSquad(
                  timId == null
                      ? 'Timsiz / Diğer Personeller'
                      : (squadNames[timId] ?? 'Bilinmeyen Tim'),
                  grouped[timId]!,
                ),
              ),
            if (personnel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Bir personele farklı görev veya not vermek için adına dokunun.',
                style: context.textStyleSecondary.copyWith(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
