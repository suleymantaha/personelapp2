import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repo;
  late GunlukFaaliyetTableData source;
  late int team, other;
  late List<int> ids;
  const actor = UserSessionState(
      username: 'chief', role: UserRole.teamCommander, timId: 1);
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ActivityRepository(db);
    team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Old team', olusturmaTarihi: '2020-01-01'));
    other = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'New team', olusturmaTarihi: '2020-01-01'));
    final user = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'chief', rol: 'tim_komutani', timId: Value(team)));
    await (db.update(db.timTable)..where((t) => t.id.equals(team)))
        .write(TimTableCompanion(timKomutaniId: Value(user)));
    final activity = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Historical task',
            tarih: '2020-02-01',
            olusturanKullanici: 'chief',
            olusturmaTarihi: '2020-02-01'));
    source = await (db.select(db.gunlukFaaliyetTable)
          ..where((t) => t.id.equals(activity)))
        .getSingle();
    ids = [];
    for (final row in [
      ('onaylandi', 'HEYBET', team),
      ('beklemede', 'HEYBET', team),
      ('reddedildi', 'HEYBET', team),
      ('onaylandi', 'İZİNLİ', team),
      ('onaylandi', 'HEYBET', other)
    ]) {
      final p = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
              adSoyad: 'Person ${ids.length}',
              rutbe: 'J.Er',
              birlik: '1/B',
              kayitTarihi: '2020-01-01',
              timId: Value(other)));
      ids.add(await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activity,
              personelId: p,
              gorevVeyaIzin: row.$2,
              durum: row.$1,
              gorevTimId: Value(row.$3),
              gorevTimAdi: const Value('Historical name'))));
    }
  });
  tearDown(() => db.close());
  Future<ActivityOutputSnapshot> load(
          {UserSessionState session = actor, Iterable<int>? selected}) =>
      repo.loadOutputSnapshot(
          actor: session,
          sources: [source],
          selectedAssignmentIds: selected ?? ids);
  test(
      'commander uses historical snapshot and excludes other team pending rejected leave',
      () async {
    final result = await load();
    expect(result.assignments.map((dynamic a) => a.id), [ids.first]);
    expect(result.personnelMap.length, 1);
  });
  test('explicit selection never widens', () async {
    final result = await load(selected: [ids.last]);
    expect(result.assignments, isEmpty);
  });
  test('selected squad narrows explicit IDs and missing IDs reject', () async {
    final snapshot = await repo.loadOutputSnapshot(
        actor: actor,
        sources: [source],
        selectedAssignmentIds: ids,
        selectedSquadId: other);
    expect(snapshot.assignments, isEmpty);
    await expectLater(load(selected: [999999]), throwsA(isA<StateError>()));
  });
  test('selected IDs cannot belong to a different source', () async {
    await expectLater(
        repo.loadOutputSnapshot(
            actor: actor, sources: [], selectedAssignmentIds: [ids.first]),
        throwsA(isA<StateError>()));
  });
  test('revoked authority rejects cached session', () async {
    await (db.update(db.timTable)..where((t) => t.id.equals(team)))
        .write(const TimTableCompanion(timKomutaniId: Value(null)));
    await expectLater(load(), throwsA(isA<AuthorizationException>()));
  });
  for (final column in ['tarih', 'faaliyet_adi']) {
    test('stale source $column rejects export', () async {
      await db.customStatement(
          'UPDATE gunluk_faaliyet_table SET $column = ? WHERE id = ?',
          [column == 'tarih' ? '2020-02-02' : 'Renamed', source.id]);
      await expectLater(load(), throwsA(isA<StateError>()));
    });
  }
  test('admin account is refreshed and historical other-team rows allowed',
      () async {
    await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    const admin = UserSessionState(username: 'admin', role: UserRole.admin);
    final result = await load(session: admin);
    expect(result.assignments.map((dynamic a) => a.id), [ids.first, ids.last]);
    await (db.delete(db.kullaniciTable)
          ..where((t) => t.kullaniciAdi.equals('admin')))
        .go();
    await expectLater(
        load(session: admin), throwsA(isA<AuthorizationException>()));
  });
}
