import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:personelapp2/features/personnel/data/personnel_order_repository.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:personelapp2/features/personnel/services/personnel_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late PersonnelOrderRepository repository;
  late int squad, first, second;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = PersonnelOrderRepository(db);
    await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'commander', rol: 'tim_komutani'));
    squad = await db
        .into(db.timTable)
        .insert(TimTableCompanion.insert(timAdi: '1-B', olusturmaTarihi: ''));
    first = await PersonnelRepository(db).addPersonnel(
        adSoyad: 'Ali',
        rutbe: 'J.Er',
        birlik: 'A',
        kayitTarihi: '',
        timId: squad);
    second = await PersonnelRepository(db).addPersonnel(
        adSoyad: 'Veli',
        rutbe: 'J.Er',
        birlik: 'A',
        kayitTarihi: '',
        timId: squad);
  });
  tearDown(() => db.close());
  Future<void> save() async {
    await repository.saveSquadOrder([squad], username: 'admin');
    await repository.savePersonnelOrder(squad, [second, first],
        username: 'admin');
  }

  test('persists order without changing membership or history', () async {
    await save();
    final rows = await db.select(db.personelTable).get();
    expect(rows.map((p) => p.sortOrder), [1, 0]);
    expect(rows.map((p) => p.timId), [squad, squad]);
    expect((await db.select(db.timTable).getSingle()).sortOrder, 0);
    expect(await db.select(db.timUyelikGecmisiTable).get(), hasLength(2));
  });
  test('rejects omitted duplicate foreign unknown ids atomically', () async {
    await save();
    for (final ids in [
      [first],
      [first, first],
      [first, 999]
    ]) {
      await expectLater(
          repository.savePersonnelOrder(squad, ids, username: 'admin'),
          throwsArgumentError);
    }
    await expectLater(repository.savePersonnelOrder(999, [], username: 'admin'),
        throwsArgumentError);
    await expectLater(
        repository.savePersonnelOrder(null, [first], username: 'admin'),
        throwsArgumentError);
    await expectLater(
        repository.saveSquadOrder([], username: 'admin'), throwsArgumentError);
    expect((await db.select(db.personelTable).get()).map((p) => p.sortOrder),
        [1, 0]);
  });
  test('requires current admin role for both operations', () async {
    for (final username in ['commander', 'missing']) {
      await expectLater(
          repository.savePersonnelOrder(squad, [first, second],
              username: username),
          throwsStateError);
      await expectLater(repository.saveSquadOrder([squad], username: username),
          throwsStateError);
    }
    expect(
        (await db.select(db.personelTable).get())
            .every((p) => p.sortOrder == null),
        isTrue);
  });
  test('transfer resets order; stale name edits preserve current position',
      () async {
    final stale = await (db.select(db.personelTable)
          ..where((p) => p.id.equals(first)))
        .getSingle();
    await save();
    await PersonnelRepository(db)
        .updatePersonnel(stale.copyWith(adSoyad: 'Yeni'));
    var person = await (db.select(db.personelTable)
          ..where((p) => p.id.equals(first)))
        .getSingle();
    expect(person.sortOrder, 1);
    await PersonnelRepository(db)
        .updatePersonnel(person.copyWith(timId: const Value(null)));
    person = await (db.select(db.personelTable)
          ..where((p) => p.id.equals(first)))
        .getSingle();
    expect(person.sortOrder, isNull);
  });
  test('legacy backup restores order and rejects invalid sort values',
      () async {
    await save();
    final backup = await PersonnelBackupService(db).exportBackupJson();
    final restored = AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    await PersonnelBackupService(restored).importBackupJson(backup);
    expect(
        (await restored.select(restored.personelTable).get())
            .map((p) => p.sortOrder),
        [1, 0]);
    expect((await restored.select(restored.timTable).getSingle()).sortOrder, 0);
    for (final value in [-1, '1', 1.5]) {
      final invalid = jsonDecode(backup) as Map<String, dynamic>;
      invalid['personnel'][0]['sortOrder'] = value;
      await expectLater(
          PersonnelBackupService(restored)
              .importBackupJson(jsonEncode(invalid)),
          throwsFormatException);
    }
  });
  test('full backup roundtrip and older backup compatibility', () async {
    SharedPreferences.setMockInitialValues({});
    await save();
    final backup = await AppBackupService(db).exportBackupJson();
    final restored = AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    await AppBackupService(restored).restoreBackupJson(backup);
    expect(
        (await restored.select(restored.personelTable).get())
            .map((p) => p.sortOrder),
        [1, 0]);
    final old = jsonDecode(backup) as Map<String, dynamic>;
    final payload = old['payload'] as Map<String, dynamic>;
    payload['databaseSchemaVersion'] = 5;
    for (final name in ['squads', 'personnel']) {
      for (final row in payload['tables'][name] as List) {
        (row as Map).remove('sortOrder');
      }
    }
    old['checksum'] = AppBackupService.computeCanonicalChecksum(payload);
    await AppBackupService(restored).restoreBackupJson(jsonEncode(old));
    expect(
        (await restored.select(restored.personelTable).get())
            .every((p) => p.sortOrder == null),
        isTrue);
    expect((await restored.select(restored.timTable).getSingle()).sortOrder,
        isNull);
  });
  test('inactive/demo rows excluded; active omissions rejected', () async {
    await (db.update(db.personelTable)..where((p) => p.id.equals(second)))
        .write(const PersonelTableCompanion(aktif: Value(false)));
    await repository.savePersonnelOrder(squad, [first], username: 'admin');
    await expectLater(
        repository.savePersonnelOrder(squad, [first, second],
            username: 'admin'),
        throwsArgumentError);
    await (db.update(db.personelTable)..where((p) => p.id.equals(second)))
        .write(const PersonelTableCompanion(
            aktif: Value(true), isDemo: Value(true)));
    await repository.savePersonnelOrder(squad, [first], username: 'admin');
    await expectLater(
        repository.savePersonnelOrder(squad, [first, second],
            username: 'admin'),
        throwsArgumentError);
  });
  test('saved positions survive closing and reopening the database', () async {
    final directory = await Directory.systemTemp.createTemp('personnel-order-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/test.sqlite');
    final stored = AppDatabase(NativeDatabase(file));
    await stored.into(stored.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    final id = await stored
        .into(stored.timTable)
        .insert(TimTableCompanion.insert(timAdi: '1-B', olusturmaTarihi: ''));
    await PersonnelOrderRepository(stored)
        .saveSquadOrder([id], username: 'admin');
    await stored.close();
    final reopened = AppDatabase(NativeDatabase(file));
    try {
      expect(
          (await reopened.select(reopened.timTable).getSingle()).sortOrder, 0);
    } finally {
      await reopened.close();
    }
  });
}
