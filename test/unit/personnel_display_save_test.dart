import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/data/personnel_order_repository.dart';

void main() {
  late AppDatabase db;
  late PersonnelOrderRepository repo;
  late List<int> teams;
  late int first, second;
  late Map<int?, List<int>> groups;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    repo = PersonnelOrderRepository(db);
    teams = (await db.select(db.timTable).get()).map((t) => t.id).toList();
    Future<int> add(String name) =>
        db.into(db.personelTable).insert(PersonelTableCompanion.insert(
            adSoyad: name,
            rutbe: 'J.Er',
            birlik: '',
            kayitTarihi: '',
            timId: Value(teams.first)));
    first = await add('Ali');
    second = await add('Veli');
    groups = {for (final id in teams) id: <int>[], null: <int>[]};
    groups[teams.first] = [second, first];
  });
  tearDown(() => db.close());
  test(
      'saves all team and personnel positions together without membership changes',
      () async {
    await repo.saveDisplayOrder(teams.reversed.toList(), groups,
        username: 'admin');
    final people = await db.select(db.personelTable).get();
    expect(people.firstWhere((p) => p.id == second).sortOrder, 0);
    expect(people.firstWhere((p) => p.id == first).sortOrder, 1);
    expect(people.every((p) => p.timId == teams.first), isTrue);
    expect(
        (await db.select(db.timTable).get())
            .firstWhere((t) => t.id == teams.last)
            .sortOrder,
        0);
  });
  test('stale member set rejects all writes including teams', () async {
    groups[teams.first] = [first];
    await expectLater(
        repo.saveDisplayOrder(teams.reversed.toList(), groups,
            username: 'admin'),
        throwsArgumentError);
    expect(
        (await db.select(db.timTable).get()).every((t) => t.sortOrder == null),
        isTrue);
    expect(
        (await db.select(db.personelTable).get())
            .every((p) => p.sortOrder == null),
        isTrue);
  });
  test('membership change and revoked administrator reject snapshot', () async {
    await (db.update(db.personelTable)..where((p) => p.id.equals(first)))
        .write(PersonelTableCompanion(timId: Value(teams.last)));
    await expectLater(repo.saveDisplayOrder(teams, groups, username: 'admin'),
        throwsArgumentError);
    await expectLater(repo.saveDisplayOrder(teams, groups, username: 'unknown'),
        throwsStateError);
  });
}
