part of 'activity_repository.dart';

extension ActivityRepositoryDateTeams on ActivityRepository {
  Future<Set<int>> _dateChangeConfirmationIds(
      List<FaaliyetPersonelAtamaTableData> assignments,
      String date,
      UserSessionState actor) async {
    final ids = <int>{};
    for (final assignment in assignments) {
      try {
        final target =
            await _taskTeamForDate(assignment.personelId, date, actor);
        final hasSnapshot = assignment.gorevTimAdi?.trim().isNotEmpty == true &&
            (assignment.gorevTimId != null ||
                assignment.gorevTimAdi == 'Tim dışı');
        if (!hasSnapshot || target.teamId != assignment.gorevTimId) {
          ids.add(assignment.personelId);
        }
      } on TaskTeamRequiredException {
        ids.add(assignment.personelId);
      }
    }
    return Set.unmodifiable(ids);
  }

  Future<Map<int, TaskTeamSnapshot>> _dateChangeTeamUpdates({
    required List<FaaliyetPersonelAtamaTableData> assignments,
    required String date,
    required UserSessionState actor,
    required List<PersonnelAssignmentInput> confirmations,
    required Set<int> requiredIds,
  }) async {
    final choices = {
      for (final choice in confirmations) choice.personnelId: choice
    };
    final personnelIds = assignments.map((a) => a.personelId).toSet();
    if (choices.length != confirmations.length ||
        choices.keys.any((id) => !personnelIds.contains(id))) {
      throw StateError('Atama listesi değişti; kaydı yenileyin.');
    }
    final updates = <int, TaskTeamSnapshot>{};
    for (final assignment in assignments) {
      final choice = choices[assignment.personelId];
      if (choice == null) {
        if (requiredIds.contains(assignment.personelId)) {
          throw TaskTeamRequiredException(assignment.personelId, date);
        }
        continue;
      }
      if (choice.teamId == null && !choice.isOutsideTeam) {
        throw ArgumentError('Tarih değişikliği için görev timi seçilmeli.');
      }
      updates[assignment.id] = await _taskTeamForDate(
          assignment.personelId, date, actor,
          taskTeamId: choice.teamId, isOutsideTeam: choice.isOutsideTeam);
    }
    return updates;
  }
}
