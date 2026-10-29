import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/task_team_history.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: 'A', olusturmaTarihi: '2026-01-01'));
    await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: 'B', olusturmaTarihi: '2026-01-01'));
  });
  tearDown(() => db.close());
  Future<void> event(String date, String action, int? team) async {
    await db.into(db.timUyelikGecmisiTable).insert(
        TimUyelikGecmisiTableCompanion.insert(
            personelId: 1, tarih: date, islem: action, timId: Value(team)));
  }

  test('dated history uses latest calendar day, ignores valid future changes',
      () async {
    await event('2026-01-01', 'eklendi', 1);
    await event('2026-03-01', 'eklendi', 2);
    expect((await TaskTeamHistory(db).resolve(1, '2026-02-02'))?.teamId, 1);
    expect((await TaskTeamHistory(db).resolve(1, '2026-03-01'))?.teamId, 2);
  });
  test('same day identical states are certain but distinct teams ambiguous',
      () async {
    await event('2026-01-01T08:00:00', 'eklendi', 1);
    await event('2026-01-01T09:00:00', 'eklendi', 1);
    expect((await TaskTeamHistory(db).resolve(1, '2026-02-02'))?.teamId, 1);
    await event('2026-01-01T10:00:00', 'eklendi', 2);
    expect(await TaskTeamHistory(db).resolve(1, '2026-02-02'), isNull);
  });
  test('invalid event dates and invalid later actions never infer a snapshot',
      () async {
    await event('2026-01-01', 'eklendi', 1);
    await event('2026-03-01', 'unrecognized', 1);
    expect(await TaskTeamHistory(db).resolve(1, '2026-02-02'), isNull);
    await db.delete(db.timUyelikGecmisiTable).go();
    await event('2026-02-30', 'eklendi', 1);
    expect(await TaskTeamHistory(db).resolve(1, '2026-04-01'), isNull);
  });
  test('add without team and deleted team references are unknown', () async {
    await event('2026-01-01', 'eklendi', null);
    expect(await TaskTeamHistory(db).resolve(1, '2026-02-02'), isNull);
    await db.delete(db.timUyelikGecmisiTable).go();
    await db.customStatement('PRAGMA foreign_keys=OFF');
    await event('2026-01-01', 'eklendi', 999);
    expect(await TaskTeamHistory(db).resolve(1, '2026-02-02'), isNull);
  });
}
