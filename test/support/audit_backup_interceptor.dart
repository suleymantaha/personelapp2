import 'package:drift/drift.dart';

/// Deterministically schedules a concurrent writer between backup table reads.
class AuditBackupInterceptor extends QueryInterceptor {
  bool armed = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) async {
    final rows = await executor.runSelect(statement, args);
    if (armed && statement.contains('FROM "gunluk_faaliyet_table"')) {
      armed = false;
      final activity = await executor.runInsert(
          'INSERT INTO gunluk_faaliyet_table '
          '(faaliyet_adi,tarih,olusturan_kullanici,olusturma_tarihi) '
          'VALUES (?,?,?,?)',
          ['AUDIT RACE', '2026-11-01', 'audit', '2026-11-01']);
      await executor.runInsert(
          'INSERT INTO faaliyet_personel_atama_table '
          '(faaliyet_id,personel_id,gorev_veya_izin,durum) VALUES (?,?,?,?)',
          [activity, 1, 'GÖREVLİ', 'beklemede']);
    }
    return rows;
  }
}
