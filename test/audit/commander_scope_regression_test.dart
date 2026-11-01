import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late int commander, team, person, activity;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'session_username': 'legacy'});
    db = AppDatabase(NativeDatabase.memory());
    commander = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'legacy',
            sifre: const Value('synthetic-test-hash'),
            rol: 'tim_komutani'));
    team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Legacy',
        timKomutaniId: Value(commander),
        olusturmaTarihi: '2026-11-01'));
    person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Synthetic',
            rutbe: 'Er',
            birlik: '',
            timId: Value(team),
            kayitTarihi: '2026-11-01'));
    activity = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Synthetic',
            tarih: '2099-11-01',
            olusturanKullanici: 'legacy',
            olusturmaTarihi: '2026-11-01'));
    await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activity,
            personelId: person,
            gorevVeyaIzin: 'GÖREVLİ',
            durum: 'beklemede',
            gorevTimId: Value(team),
            gorevTimAdi: const Value('Legacy')));
  });
  tearDown(() => db.close());

  Future<void> addSecondOwnedTeam() =>
      db.into(db.timTable).insert(TimTableCompanion.insert(
          timAdi: 'Ambiguous',
          timKomutaniId: Value(commander),
          olusturmaTarihi: '2026-11-01'));

  test(
      'legacy activity watcher requires unique ownership even without tasks in second team',
      () async {
    final repository = ActivityRepository(db);
    expect(
        (await repository.watchActivitiesForCommander('legacy').first)
            .map((a) => a.id),
        [activity]);
    expect((await SessionStorage.loadValidatedSession(db))?.timId, team);
    await addSecondOwnedTeam();
    expect(
        await PersonnelRepository(db).currentCommanderTeam('legacy'), isNull);
    expect(
        await repository.watchActivitiesForCommander('legacy').first, isEmpty);
    await (db.update(db.kullaniciTable)..where((u) => u.id.equals(commander)))
        .write(KullaniciTableCompanion(timId: Value(team)));
    expect(
        (await repository.watchActivitiesForCommander('legacy').first)
            .map((a) => a.id),
        [activity]);
  });

  test('ambiguous legacy saved session is cleared without startup exception',
      () async {
    await addSecondOwnedTeam();
    expect(await SessionStorage.loadValidatedSession(db), isNull);
    expect(
        (await SharedPreferences.getInstance()).getString('session_username'),
        isNull);
  });

  test('revoked commander cannot create or add assignments using old session',
      () async {
    final actor = UserSessionState(
        username: 'legacy', role: UserRole.teamCommander, timId: team);
    await (db.update(db.timTable)..where((t) => t.id.equals(team)))
        .write(const TimTableCompanion(timKomutaniId: Value(null)));
    final repository = ActivityRepository(db);
    await expectLater(
        repository.createActivityWithAssignments(
            faaliyetAdi: 'Forbidden',
            tarih: '2099-11-02',
            olusturanKullanici: 'legacy',
            personnelAssignments: [],
            actor: actor),
        throwsA(isA<AuthorizationException>()));
    await expectLater(
        repository.addSingleAssignment(
            faaliyetId: activity,
            personelId: person,
            gorevVeyaIzin: 'GÖREVLİ',
            tarih: '2099-11-01',
            actor: actor),
        throwsA(isA<AuthorizationException>()));
    expect((await db.select(db.gunlukFaaliyetTable).get()).map((a) => a.id),
        [activity]);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
  });
}
