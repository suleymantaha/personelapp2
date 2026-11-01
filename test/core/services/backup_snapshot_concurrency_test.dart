import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _WriterBetweenReads extends QueryInterceptor {
  AppDatabase? writer;
  bool armed = false;
  bool blocked = false;

  Future<void> insertActivity() => writer!.transaction(() async {
        final activity = await writer!.into(writer!.gunlukFaaliyetTable).insert(
            GunlukFaaliyetTableCompanion.insert(
                faaliyetAdi: 'CONCURRENT SYNTHETIC',
                tarih: '2026-11-01',
                olusturanKullanici: 'test',
                olusturmaTarihi: '2026-11-01'));
        await writer!.into(writer!.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
                faaliyetId: activity,
                personelId: 1,
                gorevVeyaIzin: 'GÖREVLİ',
                durum: 'beklemede'));
      });

  @override
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) async {
    final rows = await executor.runSelect(statement, args);
    if (armed && statement.contains('FROM "gunluk_faaliyet_table"')) {
      armed = false;
      try {
        await insertActivity();
      } on SqliteException catch (error) {
        if (error.resultCode != 5) rethrow;
        // Native Drift uses BEGIN IMMEDIATE: a concurrent writer is excluded
        // until export commits, rather than being allowed into the snapshot.
        blocked = true;
      }
    }
    return rows;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('backup stays consistent when another connection attempts a commit',
      () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('nizam-backup-');
    final file = File('${directory.path}/snapshot.sqlite');
    NativeDatabase connection() => NativeDatabase(file,
        setup: (sqlite) => sqlite.execute('PRAGMA journal_mode=WAL'));
    final hook = _WriterBetweenReads();
    final reader = AppDatabase(connection().interceptWith(hook));
    final writer = AppDatabase(connection());
    hook.writer = writer;
    addTearDown(() async {
      await reader.close();
      await writer.close();
      for (final child in await directory.list().toList()) {
        await child.delete();
      }
      await directory.delete();
    });
    await reader.into(reader.personelTable).insert(
        PersonelTableCompanion.insert(
            id: const Value(1),
            adSoyad: 'SYNTHETIC',
            rutbe: 'Er',
            birlik: '',
            kayitTarihi: '2026-11-01'));
    await writer.customSelect('SELECT 1').get();
    hook.armed = true;
    final service = AppBackupService(reader);
    final backup = await service.exportBackupJson();
    expect(hook.armed, isFalse);
    // If the reader excludes the writer, retry only after the export commits.
    if (hook.blocked) await hook.insertActivity();
    expect(await writer.select(writer.gunlukFaaliyetTable).get(), hasLength(1));
    expect(await writer.select(writer.faaliyetPersonelAtamaTable).get(),
        hasLength(1));
    await service.inspectBackupJson(backup);
    final envelope = jsonDecode(backup) as Map<String, dynamic>;
    final tables = envelope['payload']['tables'] as Map<String, dynamic>;
    expect(tables['activities'], isEmpty);
    expect(tables['assignments'], isEmpty);
    // Also exercise nested transactions used by task-team repair previews.
    await reader.transaction(() async {
      await service.inspectBackupJson(await service.exportBackupJson());
    });
  });
}
