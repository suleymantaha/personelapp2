import 'dart:convert';
import 'package:personelapp2/core/database/database.dart';
import 'app_backup_service.dart';

/// Captures raw values too: export sanitization must never hide stale changes.
class TaskTeamRepairGuard {
  TaskTeamRepairGuard(this.db, this.backup);
  final AppDatabase db;
  final AppBackupService backup;

  Future<String> rawSnapshot() async {
    final tables = await db
        .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type='table' ORDER BY name")
        .get();
    final raw = <String, Object?>{
      'schema': (await db
              .customSelect(
                  'SELECT type,name,tbl_name,sql FROM sqlite_master ORDER BY type,name')
              .get())
          .map((r) => r.data)
          .toList(),
    };
    for (final table in tables) {
      final name = table.read<String>('name');
      final quoted = name.replaceAll('"', '""');
      final rows =
          await db.customSelect('SELECT * FROM "$quoted" ORDER BY rowid').get();
      raw[name] = {
        'sql': table.data['sql'],
        'rows': rows.map((r) => r.data).toList()
      };
    }
    return AppBackupService.computeCanonicalChecksum(raw);
  }

  Future<String> safeBackup() async {
    final violations = await db.customSelect('PRAGMA foreign_key_check').get();
    final orphanHistory = await db
        .customSelect(
            'SELECT h.id FROM tim_uyelik_gecmisi_table h LEFT JOIN personel_table p '
            'ON p.id=h.personel_id WHERE p.id IS NULL LIMIT 1')
        .get();
    if (violations.isNotEmpty || orphanHistory.isNotEmpty) {
      throw StateError(
          'Kayıpsız yedek oluşturulamıyor; bozuk başvurular korunuyor.');
    }
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    final supported = {
      ...db.allTables.map((t) => t.actualTableName),
      'task_team_repair_audit',
      'sqlite_sequence'
    };
    if (tables.any((t) => !supported.contains(t.read<String>('name')))) {
      throw StateError('Yedekte desteklenmeyen tablo var; onarım yapılamaz.');
    }
    final json = await backup.exportBackupJson();
    backup.verifyLosslessBackupJson(json);
    return json;
  }

  String payloadChecksum(String json) =>
      AppBackupService.computeCanonicalChecksum(Map<String, Object?>.from(
          (jsonDecode(json) as Map<String, dynamic>)['payload'] as Map));
}
