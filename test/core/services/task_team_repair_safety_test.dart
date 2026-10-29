import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/services/task_team_repair_service.dart';
import 'dart:convert';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: 'A', olusturmaTarihi: '2026-01-01'));
    await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
        adSoyad: 'Synthetic',
        rutbe: 'R',
        birlik: 'B',
        kayitTarihi: '2026-01-01',
        timId: const Value(1)));
    await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'X',
            tarih: '2026-02-02',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-02-02'));
    await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: 1,
            personelId: 1,
            gorevVeyaIzin: 'X',
            durum: 'onaylandi'));
  });
  tearDown(() => db.close());
  Future<void> event(String date, String action, {int? team = 1}) => db
      .into(db.timUyelikGecmisiTable)
      .insert(TimUyelikGecmisiTableCompanion.insert(
          personelId: 1, tarih: date, islem: action, timId: Value(team)))
      .then((_) {});

  test('non-admin and fake admin are rejected by persisted authorization',
      () async {
    final service = TaskTeamRepairService(db);
    await expectLater(
        service.prepare(const UserSessionState(
            username: 'admin', role: UserRole.teamCommander)),
        throwsStateError);
    await expectLater(
        service.prepare(
            const UserSessionState(username: 'missing', role: UserRole.admin)),
        throwsStateError);
  });
  test('filled snapshots, unknown and verified outside remain unchanged',
      () async {
    await event('2026-01-01', 'çıkarıldı');
    final service = TaskTeamRepairService(db);
    final preview = await service.prepare(admin);
    expect(preview.outsideCount, 1);
    expect(preview.candidates, isEmpty);
    await service.apply(
        preview: preview, verifiedBackupJson: preview.backupJson, actor: admin);
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle())
            .gorevTimAdi,
        isNull);
    await db.customStatement(
        "UPDATE faaliyet_personel_atama_table SET gorev_tim_adi='Preserved'");
    expect((await service.prepare(admin)).outsideCount, 0);
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle())
            .gorevTimAdi,
        'Preserved');
  });
  test('preference changes and previews from another service are rejected',
      () async {
    await event('2026-01-01', 'eklendi');
    final service = TaskTeamRepairService(db);
    final preview = await service.prepare(admin);
    await expectLater(
        TaskTeamRepairService(db).apply(
            preview: preview,
            verifiedBackupJson: preview.backupJson,
            actor: admin),
        throwsStateError);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', 'dark');
    await expectLater(
        service.apply(
            preview: preview,
            verifiedBackupJson: preview.backupJson,
            actor: admin),
        throwsStateError);
  });
  test('audit failure rolls assignment back atomically', () async {
    await event('2026-01-01', 'eklendi');
    await db.customStatement(
        "CREATE TRIGGER fail_audit BEFORE INSERT ON task_team_repair_audit BEGIN SELECT RAISE(ABORT, 'synthetic failure'); END");
    final service = TaskTeamRepairService(db);
    final preview = await service.prepare(admin);
    await expectLater(
        service.apply(
            preview: preview,
            verifiedBackupJson: preview.backupJson,
            actor: admin),
        throwsA(anything));
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle()).gorevTimId,
        isNull);
    expect(await db.customSelect('SELECT * FROM task_team_repair_audit').get(),
        isEmpty);
  });
  test('orphan history export sanitation blocks repair; raw row preserved',
      () async {
    await db.into(db.timUyelikGecmisiTable).insert(
        TimUyelikGecmisiTableCompanion.insert(
            personelId: 999,
            tarih: '2026-01-01',
            islem: 'eklendi',
            timId: const Value(1)));
    await expectLater(
        TaskTeamRepairService(db).prepare(admin), throwsStateError);
    expect(await db.select(db.timUyelikGecmisiTable).get(), hasLength(1));
  });
  test(
      'backup audit roundtrip and old optional-field compatibility preserve snapshots',
      () async {
    await event('2026-01-01', 'eklendi');
    final backup = AppBackupService(db);
    final service = TaskTeamRepairService(db);
    final preview = await service.prepare(admin);
    await service.apply(
        preview: preview, verifiedBackupJson: preview.backupJson, actor: admin);
    final withAudit = await backup.exportBackupJson();
    await backup.restoreBackupJson(withAudit);
    expect(await db.customSelect('SELECT * FROM task_team_repair_audit').get(),
        hasLength(1));
    // A pre-repair backup must restore nulls without automatic backfill.
    final old = jsonDecode(preview.backupJson) as Map<String, dynamic>;
    final payload = old['payload'] as Map<String, dynamic>;
    payload.remove('taskTeamRepairAudit');
    old['checksum'] = AppBackupService.computeCanonicalChecksum(payload);
    await backup.restoreBackupJson(jsonEncode(old));
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle()).gorevTimId,
        isNull);
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle())
            .gorevTimAdi,
        isNull);
    expect(await db.customSelect('SELECT * FROM task_team_repair_audit').get(),
        isEmpty);
  });
}
