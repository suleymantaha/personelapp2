import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:personelapp2/core/services/task_team_repair_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());
  const signers =
      '[{"name":"Synthetic A","rank":"R","role":"D"},{"name":"Synthetic B","rank":"S","role":"E"}]';
  test('signer preferences roundtrip and changes invalidate repair preview',
      () async {
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi,rol) VALUES ('admin','yönetici')");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roster_signers_v1', signers);
    final backup = AppBackupService(db);
    final saved = await backup.exportBackupJson();
    await prefs.remove('roster_signers_v1');
    await backup.restoreBackupJson(saved);
    expect(prefs.getString('roster_signers_v1'), signers);
    final service = TaskTeamRepairService(db);
    const actor = UserSessionState(username: 'admin', role: UserRole.admin);
    final preview = await service.prepare(actor);
    await prefs.setString(
        'roster_signers_v1', signers.replaceFirst('Synthetic A', 'Changed'));
    await expectLater(
        service.apply(
            preview: preview,
            verifiedBackupJson: preview.backupJson,
            actor: actor),
        throwsStateError);
  });
  test('invalid signer preference is rejected before writes', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roster_signers_v1', signers);
    final backup = AppBackupService(db);
    final envelope =
        jsonDecode(await backup.exportBackupJson()) as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    (payload['preferences'] as Map)['roster_signers_v1'] = '[{}]';
    envelope['checksum'] = AppBackupService.computeCanonicalChecksum(payload);
    await expectLater(
        backup.restoreBackupJson(jsonEncode(envelope)), throwsFormatException);
    expect(prefs.getString('roster_signers_v1'), signers);
  });
  test('deleted row high-water survives restoring into fresh database',
      () async {
    await db.customStatement(
        "INSERT INTO kullanici_table (id,kullanici_adi,rol) VALUES (100,'old','yönetici')");
    await db.customStatement('DELETE FROM kullanici_table');
    final saved = await AppBackupService(db).exportBackupJson();
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await AppBackupService(fresh).restoreBackupJson(saved);
    await fresh.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi,rol) VALUES ('new','yönetici')");
    expect((await fresh.select(fresh.kullaniciTable).getSingle()).id,
        greaterThan(100));
  });
  test('legacy audit backup reserves deleted assignment IDs', () async {
    await db.customStatement(
        "INSERT INTO task_team_repair_audit (assignment_id,new_team_name,backup_checksum) VALUES (100,'A','synthetic')");
    final backup = AppBackupService(db);
    final envelope =
        jsonDecode(await backup.exportBackupJson()) as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    payload.remove('sqliteSequences');
    envelope['checksum'] = AppBackupService.computeCanonicalChecksum(payload);
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await AppBackupService(fresh).restoreBackupJson(jsonEncode(envelope));
    await fresh.customStatement('PRAGMA foreign_keys=OFF');
    await fresh.customStatement(
        "INSERT INTO faaliyet_personel_atama_table (faaliyet_id,personel_id,gorev_veya_izin,durum) VALUES (1,1,'X','onaylandi')");
    expect(
        (await fresh.select(fresh.faaliyetPersonelAtamaTable).getSingle()).id,
        greaterThan(100));
  });
  test('sequence validation rejects unknown, negative and below-row counters',
      () async {
    await db.customStatement(
        "INSERT INTO kullanici_table (id,kullanici_adi,rol) VALUES (5,'old','yönetici')");
    final backup = AppBackupService(db);
    final saved = await backup.exportBackupJson();
    for (final bad in [
      {'unknown': 1},
      {'kullanici_table': -1},
      {'kullanici_table': 4},
      {'kullanici_table': '5'}
    ]) {
      final envelope = jsonDecode(saved) as Map<String, dynamic>;
      final payload = envelope['payload'] as Map<String, dynamic>;
      payload['sqliteSequences'] = bad;
      envelope['checksum'] = AppBackupService.computeCanonicalChecksum(payload);
      await expectLater(backup.restoreBackupJson(jsonEncode(envelope)),
          throwsFormatException);
      expect((await db.select(db.kullaniciTable).getSingle()).id, 5);
    }
  });
  test('restoring an older backup never lowers existing high-water', () async {
    final backup = AppBackupService(db);
    final saved = await backup.exportBackupJson();
    await db.customStatement(
        "INSERT INTO kullanici_table (id,kullanici_adi,rol) VALUES (500,'old','yönetici')");
    await backup.restoreBackupJson(saved);
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi,rol) VALUES ('new','yönetici')");
    expect(
        (await db.select(db.kullaniciTable).getSingle()).id, greaterThan(500));
  });
}
