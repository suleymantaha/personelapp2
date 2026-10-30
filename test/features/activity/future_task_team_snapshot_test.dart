import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repository;
  late int currentTeam, otherTeam, person;
  late String tomorrow;
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = ActivityRepository(db);
    currentTeam = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Current', olusturmaTarihi: '2000-01-01'));
    otherTeam = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Other', olusturmaTarihi: '2000-01-01'));
    final commander = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'leader',
            rol: 'tim_komutani',
            timId: Value(currentTeam)));
    await (db.update(db.timTable)..where((t) => t.id.equals(currentTeam)))
        .write(TimTableCompanion(timKomutaniId: Value(commander)));
    person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Synthetic',
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01',
            timId: Value(currentTeam)));
    final now = DateTime.now();
    tomorrow = DateTime(now.year, now.month, now.day + 1)
        .toIso8601String()
        .split('T')
        .first;
  });
  tearDown(() => db.close());

  Future<int> create({int? explicitTeam, UserSessionState actor = admin}) =>
      repository.createActivityWithAssignments(
          faaliyetAdi: 'Synthetic',
          tarih: tomorrow,
          olusturanKullanici: actor.username,
          personnelAssignments: [
            PersonnelAssignmentInput(
                personnelId: person, duty: 'GÖREVLİ', teamId: explicitTeam)
          ],
          actor: actor);

  test('future assignment saves current team without membership history',
      () async {
    await create();
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, currentTeam);
    expect(row.gorevTimAdi, 'Current');
    expect(await db.select(db.timUyelikGecmisiTable).get(), isEmpty);
  });

  test('future assignment uses current team even with conflicting history',
      () async {
    for (final team in [currentTeam, otherTeam]) {
      await db.into(db.timUyelikGecmisiTable).insert(
          TimUyelikGecmisiTableCompanion.insert(
              personelId: person,
              timId: Value(team),
              tarih: '2000-01-01',
              islem: 'eklendi'));
    }
    await create();
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, currentTeam);
    expect(row.gorevTimAdi, 'Current');
  });

  test('future task snapshot survives subsequent team and team name changes',
      () async {
    await create();
    await (db.update(db.personelTable)..where((p) => p.id.equals(person)))
        .write(PersonelTableCompanion(timId: Value(otherTeam)));
    await (db.update(db.timTable)..where((t) => t.id.equals(currentTeam)))
        .write(const TimTableCompanion(timAdi: Value('Renamed')));
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, currentTeam);
    expect(row.gorevTimAdi, 'Current');
  });

  test('explicit future task team still takes precedence', () async {
    await create(explicitTeam: otherTeam);
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, otherTeam);
    expect(row.gorevTimAdi, 'Other');
  });

  test('unassigned future personnel is recorded as outside team', () async {
    await (db.update(db.personelTable)..where((p) => p.id.equals(person)))
        .write(const PersonelTableCompanion(timId: Value(null)));
    await create();
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, isNull);
    expect(row.gorevTimAdi, 'Tim dışı');
  });

  test('team leader can add own personnel to future activity', () async {
    final leader = UserSessionState(
        username: 'leader', role: UserRole.teamCommander, timId: currentTeam);
    await create(actor: leader);
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle()).gorevTimId,
        currentTeam);
  });

  test('team leader cannot override future task into another team', () async {
    final leader = UserSessionState(
        username: 'leader', role: UserRole.teamCommander, timId: currentTeam);
    await expectLater(create(actor: leader, explicitTeam: otherTeam),
        throwsA(isA<AuthorizationException>()));
    expect(await db.select(db.gunlukFaaliyetTable).get(), isEmpty);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
  });
}
