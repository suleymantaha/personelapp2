import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression contracts for the validated audit findings. F03 is exercised by
/// backup_snapshot_concurrency_test.dart with two actual database connections.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('F01 regression: new squad commander resolves the created team',
      () async {
    final repository = PersonnelRepository(db);
    final team = await repository.addSquadWithCommander(
        timAdi: 'AUDIT',
        olusturmaTarihi: '2026-11-01',
        komutanKullaniciAdi: 'audit');
    final user = await db.select(db.kullaniciTable).getSingle();
    expect((await db.select(db.timTable).getSingle()).id, team);
    expect(user.timId, team);
    expect(await repository.currentCommanderTeam('audit'), team);
  });

  test('F02 regression: demoted admin cannot approve assignment', () async {
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'audit', rol: 'tim_komutani'));
    final person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'AUDIT',
            rutbe: 'Er',
            birlik: '',
            kayitTarihi: '2026-11-01'));
    final activity = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'AUDIT',
            tarih: '2026-11-01',
            olusturanKullanici: 'audit',
            olusturmaTarihi: '2026-11-01'));
    final assignment = await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activity,
            personelId: person,
            gorevVeyaIzin: 'GÖREVLİ',
            durum: 'beklemede'));
    await expectLater(
        ActivityRepository(db).approveAssignment(assignment,
            actor: const UserSessionState(
                username: 'audit', role: UserRole.admin)),
        throwsA(isA<AuthorizationException>()));
    expect((await db.select(db.faaliyetPersonelAtamaTable).getSingle()).durum,
        'beklemede');
  });

  test('F04 regression: password reset invalidates saved session', () async {
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'admin', sifre: const Value('123456'), rol: 'yönetici'));
    SharedPreferences.setMockInitialValues({'session_username': 'admin'});
    await db.ensureSeeded();
    final admin = await (db.select(db.kullaniciTable)
          ..where((row) => row.kullaniciAdi.equals('admin')))
        .getSingle();
    expect(admin.sifre, isEmpty);
    expect(await SessionStorage.loadValidatedSession(db), isNull);
  });
}
