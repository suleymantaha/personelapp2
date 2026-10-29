import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/services/task_team_history.dart';
import 'package:personelapp2/core/services/task_team_repair_service.dart';
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
  test('current membership is not historical proof', () async {
    expect(await TaskTeamHistory(db).resolve(1, '2026-02-02'), isNull);
  });
  test('same day conflicting states remain unknown; invalid dates rejected',
      () async {
    await event('2026-01-01T08:00:00', 'eklendi');
    await event('2026-01-01T09:00:00', 'çıkarıldı');
    expect(await TaskTeamHistory(db).resolve(1, '2026-02-02'), isNull);
    expect(await TaskTeamHistory(db).resolve(1, '2026-02-30'), isNull);
  });
  test('verified removal is explicit outside', () async {
    await event('2026-01-01', 'çıkarıldı');
    final result = await TaskTeamHistory(db).resolve(1, '2026-02-02');
    expect(result?.teamId, isNull);
    expect(result?.teamName, 'Tim dışı');
  });
  test('prepare read-only, apply audited, repeat preparation idempotent',
      () async {
    await event('2026-01-01', 'eklendi');
    final service = TaskTeamRepairService(db);
    final preview = await service.prepare(admin);
    expect(preview.candidates, hasLength(1));
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle()).gorevTimId,
        isNull);
    expect(
        await service.apply(
            preview: preview,
            verifiedBackupJson: preview.backupJson,
            actor: admin),
        1);
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle()).gorevTimId,
        1);
    expect(await db.customSelect('SELECT * FROM task_team_repair_audit').get(),
        hasLength(1));
    expect((await service.prepare(admin)).candidates, isEmpty);
  });
  test('mismatch, stale raw data and revoked admin fail without writes',
      () async {
    await event('2026-01-01', 'eklendi');
    final service = TaskTeamRepairService(db);
    final preview = await service.prepare(admin);
    await expectLater(
        service.apply(preview: preview, verifiedBackupJson: '{}', actor: admin),
        throwsStateError);
    await db.customStatement(
        "UPDATE personel_table SET ad_soyad='Changed' WHERE id=1");
    await expectLater(
        service.apply(
            preview: preview,
            verifiedBackupJson: preview.backupJson,
            actor: admin),
        throwsStateError);
    final fresh = await service.prepare(admin);
    await db.customStatement("UPDATE kullanici_table SET rol='tim_komutani'");
    await expectLater(
        service.apply(
            preview: fresh, verifiedBackupJson: fresh.backupJson, actor: admin),
        throwsStateError);
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle()).gorevTimId,
        isNull);
  });
}
