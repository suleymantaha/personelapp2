import 'package:flutter/material.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

/// Only an explicit user choice becomes an override; dated automatic resolutions
/// are checked again by the repository when it writes the assignment.
Future<List<PersonnelAssignmentInput>?> confirmTaskTeams({
  required BuildContext context,
  required ActivityRepository repository,
  required String date,
  required List<PersonnelAssignmentInput> assignments,
  required UserSessionState actor,
  Set<int> forceConfirmationFor = const {},
}) async {
  final missing = <int>{};
  for (final assignment in assignments) {
    if (forceConfirmationFor.contains(assignment.personnelId)) {
      missing.add(assignment.personnelId);
      continue;
    }
    try {
      await repository.resolveAssignmentTeam(
          assignment: assignment, date: date, actor: actor);
    } on TaskTeamRequiredException {
      missing.add(assignment.personnelId);
    }
  }
  if (missing.isEmpty) return assignments;
  final people = await repository.db.select(repository.db.personelTable).get();
  final teams = await repository.db.select(repository.db.timTable).get();
  if (!context.mounted) return null;
  final choices = await showDialog<Map<int, int>>(
      context: context,
      builder: (_) => _TaskTeamConfirmation(
          date: date,
          names: {
            for (final p in people)
              if (missing.contains(p.id)) p.id: p.adSoyad
          },
          teams:
              teams.where((t) => actor.isAdmin || t.id == actor.timId).toList(),
          allowOutside: actor.isAdmin));
  if (choices == null) return null;
  return [
    for (final a in assignments)
      if (choices[a.personnelId] case final choice?)
        PersonnelAssignmentInput(
            personnelId: a.personnelId,
            duty: a.duty,
            note: a.note,
            teamId: choice == -1 ? null : choice,
            isOutsideTeam: choice == -1)
      else
        a
  ];
}

class _TaskTeamConfirmation extends StatefulWidget {
  const _TaskTeamConfirmation(
      {required this.date,
      required this.names,
      required this.teams,
      required this.allowOutside});
  final String date;
  final Map<int, String> names;
  final List<TimTableData> teams;
  final bool allowOutside;
  @override
  State<_TaskTeamConfirmation> createState() => _TaskTeamConfirmationState();
}

class _TaskTeamConfirmationState extends State<_TaskTeamConfirmation> {
  final Map<int, int> _choices = {};
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Görev tarihindeki timi doğrula'),
        content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.date} tarihindeki görev timini seçin. '
                    'Bu seçim yalnızca görev kaydına uygulanır; '
                    'personelin bağlı olduğu tim değişmez.'),
                const SizedBox(height: 12),
                for (final entry in widget.names.entries)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('task-team-choice-${entry.key}'),
                        isExpanded: true,
                        decoration: InputDecoration(labelText: entry.value),
                        hint: const Text('Görev timini seçin'),
                        items: [
                          for (final team in widget.teams)
                            DropdownMenuItem(
                                value: team.id, child: Text(team.timAdi)),
                          if (widget.allowOutside)
                            const DropdownMenuItem(
                                value: -1, child: Text('Tim dışı')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _choices[entry.key] = value);
                          }
                        },
                      )),
              ],
            ))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          FilledButton(
              key: const ValueKey('task-team-confirm'),
              onPressed: _choices.length == widget.names.length
                  ? () => Navigator.pop(context, Map<int, int>.of(_choices))
                  : null,
              child: const Text('Seçimleri doğrula')),
        ],
      );
}
