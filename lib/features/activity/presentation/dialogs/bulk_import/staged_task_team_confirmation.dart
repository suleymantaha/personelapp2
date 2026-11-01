import 'package:flutter/material.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import '../task_team_confirmation.dart';
import 'staged_bulk_import.dart';

Future<List<PersonnelAssignmentInput>?> confirmBulkTaskTeams({
  required BuildContext context,
  required ActivityRepository repository,
  required String date,
  required List<PersonnelAssignmentInput> assignments,
  required UserSessionState actor,
  required StagedBulkImport staged,
}) async {
  final existing = await confirmTaskTeams(
      context: context,
      repository: repository,
      date: date,
      assignments: assignments.where((a) => a.personnelId > 0).toList(),
      actor: actor);
  if (existing == null || !context.mounted) return null;
  final result = [...existing];
  for (final assignment in assignments.where((a) => a.personnelId < 0)) {
    if (assignment.teamId != null || assignment.isOutsideTeam) {
      result.add(assignment);
      continue;
    }
    final teams = await repository.db.select(repository.db.timTable).get();
    if (!context.mounted) return null;
    final choice = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
                title: Text('Görev tarihindeki timi doğrula: $date'),
                children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(staged
                              .people[assignment.personnelId]?.adSoyad.value ??
                          'Yeni personel')),
                  for (final team in teams
                      .where((t) => actor.isAdmin || t.id == actor.timId))
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, team.id),
                        child: Text(team.timAdi)),
                  if (actor.isAdmin)
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, -1),
                        child: const Text('Tim dışı')),
                  SimpleDialogOption(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal')),
                ]));
    if (choice == null) return null;
    result.add(PersonnelAssignmentInput(
        personnelId: assignment.personnelId,
        duty: assignment.duty,
        note: assignment.note,
        teamId: choice == -1 ? null : choice,
        isOutsideTeam: choice == -1));
  }
  return result;
}
