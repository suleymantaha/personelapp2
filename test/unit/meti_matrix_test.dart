import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

void main() {
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  late AppDatabase db;
  late ActivityRepository activities;
  late MatrixRepository matrix;
  late int person;
  late int team;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'admin', rol: UserRole.admin.storageValue));
    activities = ActivityRepository(db);
    matrix = MatrixRepository(db);
    team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Test Timi', olusturmaTarihi: '2026-01-01'));
    person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Sentetik Personel',
            rutbe: 'Er',
            birlik: 'Test',
            timId: Value(team),
            kayitTarihi: '2026-01-01'));
  });
  tearDown(() => db.close());

  Future<int> assign(String date, {String duty = 'METİ'}) async {
    await activities.createActivityWithAssignments(
        faaliyetAdi: 'Test Faaliyeti',
        tarih: date,
        olusturanKullanici: 'admin',
        personnelAssignments: [
          PersonnelAssignmentInput(
              personnelId: person, duty: duty, teamId: team)
        ],
        actor: admin);
    return (await db.select(db.faaliyetPersonelAtamaTable).get()).last.id;
  }

  test('METİ appears on one day and counts as one personnel duty day',
      () async {
    await assign('2026-10-12');
    final cells = (await matrix.watchMonthlyMatrix('2026-10').first)[person]!;
    expect(cells.keys, [12]);
    expect(cells[12]!.displayCode, 'X');
    expect(cells[12]!.entries.single.duty, 'METİ');
    expect(cells[12]!.entries.single.isContinuationDay, isFalse);
    final calendar = await matrix.getTeamMonthlyCalendar(
        timId: team, timAdi: 'Test Timi', year: 2026, month: 10);
    expect(calendar.ozet.toplamGorevGunSayisi, 1);
    expect(calendar.ozet.toplamPersonelGorevGunu, 1);
    expect(calendar.ozet.gorevTuruDagilimi, {'METİ': 1});
  });

  test('month-end METİ does not continue into next month', () async {
    await assign('2026-10-31');
    expect(
        (await matrix.watchMonthlyMatrix('2026-10').first)[person]![31]!
            .displayCode,
        'X');
    expect(await matrix.watchMonthlyMatrix('2026-11').first, isEmpty);
  });

  test(
      'editing two-day duty to METİ removes continuation; deleting removes cell',
      () async {
    final id = await assign('2026-10-12', duty: 'HAZIR KITA');
    expect((await matrix.watchMonthlyMatrix('2026-10').first)[person]!.keys,
        [12, 13]);
    final assignment = await (db.select(db.faaliyetPersonelAtamaTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    await activities.updateExistingAssignmentDuties(
        activityId: assignment.faaliyetId,
        assignmentIds: [id],
        duty: 'METİ',
        actor: admin);
    final updated = (await matrix.watchMonthlyMatrix('2026-10').first)[person]!;
    expect(updated.keys, [12]);
    expect(updated[12]!.displayCode, 'X');
    await activities.deleteAssignment(id, actor: admin);
    expect(await matrix.watchMonthlyMatrix('2026-10').first, isEmpty);
  });

  test('pending METİ remains B and rejected METİ is excluded', () async {
    final id = await assign('2026-10-12');
    await (db.update(db.faaliyetPersonelAtamaTable)
          ..where((t) => t.id.equals(id)))
        .write(const FaaliyetPersonelAtamaTableCompanion(
            durum: Value(AssignmentStatus.beklemede)));
    expect(
        (await matrix.watchMonthlyMatrix('2026-10').first)[person]![12]!
            .displayCode,
        'B');
    await (db.update(db.faaliyetPersonelAtamaTable)
          ..where((t) => t.id.equals(id)))
        .write(const FaaliyetPersonelAtamaTableCompanion(
            durum: Value(AssignmentStatus.reddedildi)));
    expect(await matrix.watchMonthlyMatrix('2026-10').first, isEmpty);
  });
}
