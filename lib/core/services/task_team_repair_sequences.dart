import 'package:drift/drift.dart';

/// Preserve AUTOINCREMENT high-water marks, including deleted audited rows.
class TaskTeamRepairSequences {
  static const tables = {
    'kullanici_table': 'users',
    'tim_table': 'squads',
    'personel_table': 'personnel',
    'gunluk_faaliyet_table': 'activities',
    'faaliyet_personel_atama_table': 'assignments',
    'rapor_kayit_table': 'reports',
    'tim_uyelik_gecmisi_table': 'membershipHistory',
    'personel_isim_takma_ad_table': 'aliases',
    'toplu_aktarim_gecmisi_table': 'bulkImportHistory',
    'task_team_repair_audit': 'taskTeamRepairAudit',
  };

  static Future<Map<String, int>> read(DatabaseConnectionUser db) async {
    final rows = await db
        .customSelect('SELECT name,seq FROM sqlite_sequence ORDER BY name')
        .get();
    return {
      for (final row in rows) row.read<String>('name'): row.read<int>('seq')
    };
  }

  static Map<String, int> parse(Object? value, Map<String, Object?> payload) {
    if (value == null) return {};
    if (value is! Map || value.keys.any((key) => !tables.containsKey(key))) {
      throw const FormatException('Invalid backup sequences');
    }
    final result = <String, int>{};
    final records = payload['tables'] as Map;
    for (final entry in value.entries) {
      final seq = entry.value;
      // JSON counters must remain exact when restored by the web application.
      if (seq is! int || seq < 0 || seq > 9007199254740991) {
        throw const FormatException('Invalid backup sequence high-water mark');
      }
      final key = tables[entry.key]!;
      final rows = (entry.key == 'task_team_repair_audit'
              ? payload['taskTeamRepairAudit']
              : records[key]) as List? ??
          [];
      if (rows.any((row) =>
          row is! Map || row['id'] is! int || (row['id'] as int) > seq)) {
        throw const FormatException('Backup sequence below existing row ID');
      }
      result[entry.key as String] = seq;
    }
    return result;
  }

  static Future<void> restore(DatabaseConnectionUser db,
      Map<String, int> backed, List<Map<String, Object?>> audit) async {
    final desired = {...await read(db)};
    for (final entry in backed.entries) {
      if ((desired[entry.key] ?? 0) < entry.value) {
        desired[entry.key] = entry.value;
      }
    }
    const assignments = 'faaliyet_personel_atama_table';
    for (final row in audit) {
      final id = row['assignment_id'] as int;
      if ((desired[assignments] ?? 0) < id) desired[assignments] = id;
    }
    for (final entry in desired.entries) {
      if (!tables.containsKey(entry.key)) continue;
      await db.customStatement(
          'DELETE FROM sqlite_sequence WHERE name=?', [entry.key]);
      await db.customStatement(
          'INSERT INTO sqlite_sequence(name,seq) VALUES (?,?)',
          [entry.key, entry.value]);
    }
  }
}
