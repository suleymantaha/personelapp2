import 'package:drift/drift.dart';

class TaskTeamSnapshot {
  const TaskTeamSnapshot(this.teamId, this.teamName);
  final int? teamId;
  final String teamName;
}

/// Date-only activities cannot order distinct membership states within a day.
class TaskTeamHistory {
  TaskTeamHistory(this.db);
  final DatabaseConnectionUser db;

  static String? validDay(String value) {
    final day = value.length >= 10 ? value.substring(0, 10) : value;
    final timestamp = RegExp(
        r'^\d{4}-\d{2}-\d{2}(?:T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?(?:Z|[+-](?:[01]\d|2[0-3]):?[0-5]\d)?)?$');
    if (!timestamp.hasMatch(value)) return null;
    final parsed = DateTime.tryParse(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) ||
        parsed == null ||
        DateTime.tryParse(day)?.toIso8601String().substring(0, 10) != day) {
      return null;
    }
    return day;
  }

  Future<TaskTeamSnapshot?> resolve(int personnelId, String date,
      {bool useRegistrationFallback = false}) async {
    if (date.length != 10 || validDay(date) == null) return null;
    final rows = await db.customSelect(
      'SELECT h.tarih, h.islem, h.tim_id, t.tim_adi FROM '
      'tim_uyelik_gecmisi_table h LEFT JOIN tim_table t ON t.id=h.tim_id '
      'WHERE h.personel_id=?',
      variables: [Variable(personnelId)],
    ).get();
    if (useRegistrationFallback && rows.isEmpty) {
      return _registrationTeam(personnelId, date);
    }
    String? latest;
    final states = <String, TaskTeamSnapshot>{};
    for (final row in rows) {
      final recordedDate = row.read<String>('tarih');
      if (useRegistrationFallback && recordedDate.isEmpty) continue;
      final day = validDay(recordedDate);
      if (day == null) return null;
      final action = row.read<String>('islem');
      final teamId = row.readNullable<int>('tim_id');
      final teamName = row.readNullable<String>('tim_adi');
      if ((action != 'eklendi' && action != 'çıkarıldı') ||
          (teamId != null && (teamName == null || teamName.trim().isEmpty)) ||
          (action == 'eklendi' && teamId == null)) {
        return null;
      }
      if (day.compareTo(date) > 0) continue;
      if (latest == null || day.compareTo(latest) > 0) {
        latest = day;
        states.clear();
      }
      if (day == latest) {
        final snapshot = action == 'çıkarıldı'
            ? const TaskTeamSnapshot(null, 'Tim dışı')
            : TaskTeamSnapshot(teamId, teamName!);
        states['${snapshot.teamId}:${snapshot.teamName}'] = snapshot;
      }
    }
    return states.length == 1 ? states.values.single : null;
  }

  Future<TaskTeamSnapshot?> _registrationTeam(int personnelId, String date) async {
    final person = await db.customSelect(
      'SELECT p.kayit_tarihi, p.tim_id, t.tim_adi FROM personel_table p '
      'LEFT JOIN tim_table t ON t.id=p.tim_id WHERE p.id=? AND p.aktif=1',
      variables: [Variable(personnelId)],
    ).getSingleOrNull();
    if (person == null) return null;
    final registeredDay = validDay(person.read<String>('kayit_tarihi'));
    if (registeredDay == null || registeredDay.compareTo(date) > 0) return null;
    final teamId = person.readNullable<int>('tim_id');
    if (teamId == null) return const TaskTeamSnapshot(null, 'Tim dışı');
    final teamName = person.readNullable<String>('tim_adi');
    if (teamName == null || teamName.trim().isEmpty) return null;
    return TaskTeamSnapshot(teamId, teamName);
  }
}
