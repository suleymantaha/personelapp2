import 'package:drift/drift.dart';

/// Raw SQL keeps the additive audit independent of generated application models.
class TaskTeamRepairAudit {
  static Future<void> create(DatabaseConnectionUser db) =>
      db.customStatement('''
    CREATE TABLE IF NOT EXISTS task_team_repair_audit (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      assignment_id INTEGER NOT NULL,
      old_team_id INTEGER,
      old_team_name TEXT,
      new_team_id INTEGER,
      new_team_name TEXT NOT NULL,
      backup_checksum TEXT NOT NULL
    )
  ''');

  static Future<List<Map<String, Object?>>> read(
          DatabaseConnectionUser db) async =>
      (await db
              .customSelect('SELECT * FROM task_team_repair_audit ORDER BY id')
              .get())
          .map((r) => r.data)
          .toList();

  static List<Map<String, Object?>> parse(Object? value) {
    if (value == null) return [];
    if (value is! List || value.length > 100000) {
      throw const FormatException('Onarım denetim kaydı geçersiz.');
    }
    const keys = {
      'id',
      'assignment_id',
      'old_team_id',
      'old_team_name',
      'new_team_id',
      'new_team_name',
      'backup_checksum'
    };
    final ids = <int>{};
    return value.map((item) {
      if (item is! Map ||
          item.keys.toSet().difference(keys).isNotEmpty ||
          item.length != keys.length ||
          item['id'] is! int ||
          !ids.add(item['id'] as int) ||
          item['assignment_id'] is! int ||
          (item['old_team_id'] != null && item['old_team_id'] is! int) ||
          (item['new_team_id'] != null && item['new_team_id'] is! int) ||
          (item['old_team_name'] != null && item['old_team_name'] is! String) ||
          item['new_team_name'] is! String ||
          item['backup_checksum'] is! String) {
        throw const FormatException('Onarım denetim kaydı geçersiz.');
      }
      return Map<String, Object?>.from(item);
    }).toList();
  }

  static Future<void> replace(
      DatabaseConnectionUser db, List<Map<String, Object?>> rows) async {
    await db.customStatement('DELETE FROM task_team_repair_audit');
    for (final row in rows) {
      await db.customStatement(
          'INSERT INTO task_team_repair_audit '
          '(id,assignment_id,old_team_id,old_team_name,new_team_id,new_team_name,backup_checksum) '
          'VALUES (?,?,?,?,?,?,?)',
          [
            row['id'],
            row['assignment_id'],
            row['old_team_id'],
            row['old_team_name'],
            row['new_team_id'],
            row['new_team_name'],
            row['backup_checksum']
          ]);
    }
  }
}
