part of 'activity_repository.dart';

class TaskTeamRequiredException extends StateError {
  TaskTeamRequiredException(this.personnelId, this.date)
      : super('$date tarihinde Personel #$personnelId için görev timi '
            'doğrulanamadı. Görev timini veya Tim dışı seçeneğini belirtin.');
  final int personnelId;
  final String date;
}

extension ActivityRepositoryTaskTeams on ActivityRepository {
  Future<TaskTeamSnapshot> resolveAssignmentTeam({
    required PersonnelAssignmentInput assignment,
    required String date,
    required UserSessionState actor,
  }) async {
    await _requirePersonnelScope(actor, [assignment]);
    return _taskTeamForDate(assignment.personnelId, date, actor,
        taskTeamId: assignment.teamId, isOutsideTeam: assignment.isOutsideTeam);
  }

  Future<TaskTeamSnapshot> _taskTeamForDate(
      int personId, String date, UserSessionState actor,
      {int? taskTeamId, bool isOutsideTeam = false}) async {
    if (!_isValidIsoDate(date)) throw ArgumentError('Görev tarihi geçersiz.');
    if (taskTeamId != null && isOutsideTeam) {
      throw ArgumentError('Görev timi ve Tim dışı birlikte seçilemez.');
    }
    TaskTeamSnapshot? snapshot;
    if (isOutsideTeam) {
      snapshot = const TaskTeamSnapshot(null, 'Tim dışı');
    } else if (taskTeamId != null) {
      final team = await (db.select(db.timTable)
            ..where((t) => t.id.equals(taskTeamId)))
          .getSingleOrNull();
      if (team == null) throw ArgumentError('Görev timi bulunamadı.');
      snapshot = TaskTeamSnapshot(team.id, team.timAdi);
    } else if (date
            .compareTo(DateTime.now().toIso8601String().split('T').first) >=
        0) {
      // Current membership is the task team for today's and planned duties.
      // Past duties still require dated evidence or an explicit choice.
      final person = await (db.select(db.personelTable)
            ..where((p) => p.id.equals(personId)))
          .getSingle();
      if (person.timId == null) {
        snapshot = const TaskTeamSnapshot(null, 'Tim dışı');
      } else {
        final team = await (db.select(db.timTable)
              ..where((t) => t.id.equals(person.timId!)))
            .getSingleOrNull();
        if (team != null) snapshot = TaskTeamSnapshot(team.id, team.timAdi);
      }
    } else {
      snapshot = await TaskTeamHistory(db).resolve(personId, date);
    }
    if (snapshot == null) throw TaskTeamRequiredException(personId, date);
    if (!actor.isAdmin && snapshot.teamId != actor.timId) {
      throw const AuthorizationException(
          'Görev tarihindeki tim yetki kapsamınız dışında. Yöneticiye başvurun.');
    }
    return snapshot;
  }

  Future<(int?, String?)> _snapshotForAssignment(
      int personId, String date, UserSessionState actor,
      {int? taskTeamId,
      bool isOutsideTeam = false,
      FaaliyetPersonelAtamaTableData? source}) async {
    if (source != null) {
      final origin = await (db.select(db.gunlukFaaliyetTable)
            ..where((f) => f.id.equals(source.faaliyetId)))
          .getSingle();
      if (origin.tarih == date) {
        return (source.gorevTimId, source.gorevTimAdi);
      }
      // Moving a legacy unknown must not turn it into an inferred team.
      if (source.gorevTimId == null && source.gorevTimAdi == null) {
        throw TaskTeamRequiredException(personId, date);
      }
    }
    final value = await _taskTeamForDate(personId, date, actor,
        taskTeamId: taskTeamId, isOutsideTeam: isOutsideTeam);
    return (value.teamId, value.teamName);
  }
}
