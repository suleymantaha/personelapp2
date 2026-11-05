import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import '../../support/task_team_history_fixture.dart';

void main() {
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  late AppDatabase db;
  late ActivityRepository repo;
  late int person;
  const date = '2026-11-06';

  ActivityCreateRequest request(String name, String duty) =>
      ActivityCreateRequest(
        faaliyetAdi: name,
        tarih: date,
        olusturanKullanici: 'admin',
        personnelAssignments: [
          PersonnelAssignmentInput(
              personnelId: person, duty: duty, isOutsideTeam: true),
        ],
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ActivityRepository(db);
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'admin', rol: UserRole.admin.storageValue));
    person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Synthetic Audit',
            rutbe: 'J.Uzm.Çvş.',
            birlik: 'Test',
            kayitTarihi: date));
  });
  tearDown(() => db.close());

  test('all-conflict batch preserves existing empty card without new card',
      () async {
    final existing = await repo.createActivitiesWithAssignments(
        [request('Existing duty', 'NÖBETÇİ')],
        actor: admin);
    final empty = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Preserved empty',
        tarih: date,
        olusturanKullanici: 'admin',
        personnelAssignments: [],
        actor: admin);
    final result = await repo.createActivitiesWithAssignments(
        [request('Attempted HEYBET', 'HEYBET')],
        actor: admin);
    expect(result.addedAssignmentCount, 0);
    expect(result.skippedAssignmentCount, 1);
    expect(result.activityIds, isEmpty);
    final cards = await db.select(db.gunlukFaaliyetTable).get();
    expect(cards.map((c) => c.id),
        unorderedEquals([...existing.activityIds, empty]));
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
  });

  test('batch outcomes distinguish added unchanged and actual conflicts',
      () async {
    final added = await repo.createActivitiesWithAssignments(
        [request('Existing duty', 'NÖBETÇİ')],
        actor: admin);
    final unchanged = await repo.createActivitiesWithAssignments(
        [request('Existing duty', 'NÖBETÇİ')],
        actor: admin);
    final conflict = await repo.createActivitiesWithAssignments(
        [request('Other duty', 'HEYBET')],
        actor: admin);
    expect(added.outcomes.single.status, ActivityImportStatus.added);
    expect(
        unchanged.outcomes.single.status, ActivityImportStatus.alreadyAssigned);
    final outcome = conflict.outcomes.single;
    expect(outcome.status, ActivityImportStatus.conflict);
    expect(outcome.personnelId, person);
    expect(outcome.name, 'Synthetic Audit');
    expect(outcome.rank, 'J.Uzm.Çvş.');
    expect(outcome.activityName, 'Other duty');
    expect(outcome.date, date);
    expect(outcome.duty, 'HEYBET');
    expect(outcome.existingDescription, contains('Existing duty'));
    expect(outcome.existingDescription, contains('NÖBETÇİ'));
  });

  test('existing-activity outcomes retain person and reservation details',
      () async {
    await repo.createActivitiesWithAssignments(
        [request('Existing duty', 'NÖBETÇİ')],
        actor: admin);
    final empty = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Target',
        tarih: date,
        olusturanKullanici: 'admin',
        personnelAssignments: [],
        actor: admin);
    final result = await repo.addAssignmentsToActivity(
        activityId: empty,
        assignments: request('Target', 'HEYBET').personnelAssignments,
        actor: admin);
    expect(result.outcomes.single.status, ActivityImportStatus.conflict);
    expect(result.outcomes.single.name, 'Synthetic Audit');
    expect(
        result.outcomes.single.existingDescription, contains('Existing duty'));
    expect(result.outcomes.single.existingDescription, contains('NÖBETÇİ'));
  });

  test('bulk empty input leaves no new card', () async {
    final result = await repo.createActivitiesWithAssignments([
      const ActivityCreateRequest(
          faaliyetAdi: 'Empty',
          tarih: date,
          olusturanKullanici: 'admin',
          personnelAssignments: []),
    ], actor: admin);
    expect(result.activityIds, isEmpty);
    expect(result.outcomes, isEmpty);
    expect(await db.select(db.gunlukFaaliyetTable).get(), isEmpty);
  });

  test('commander pending approval is added, then already assigned', () async {
    final commanderId = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'commander',
            rol: UserRole.teamCommander.storageValue));
    final teamId = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Synthetic team',
        olusturmaTarihi: date,
        timKomutaniId: Value(commanderId)));
    await (db.update(db.kullaniciTable)..where((t) => t.id.equals(commanderId)))
        .write(KullaniciTableCompanion(timId: Value(teamId)));
    await (db.update(db.personelTable)..where((t) => t.id.equals(person)))
        .write(PersonelTableCompanion(timId: Value(teamId)));
    await seedTaskTeamHistory(db);
    final commander = UserSessionState(
        username: 'commander', role: UserRole.teamCommander, timId: teamId);
    final target = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Target',
        tarih: date,
        olusturanKullanici: 'admin',
        personnelAssignments: [],
        actor: admin);
    final inputs = [
      PersonnelAssignmentInput(personnelId: person, duty: 'HEYBET')
    ];
    final first = await repo.addAssignmentsToActivity(
        activityId: target, assignments: inputs, actor: commander);
    expect(first.outcomes.single.status, ActivityImportStatus.added);
    expect(first.conflictSkippedCount, 0);
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.durum, 'beklemede');
    final second = await repo.addAssignmentsToActivity(
        activityId: target, assignments: inputs, actor: commander);
    expect(second.outcomes.single.status, ActivityImportStatus.alreadyAssigned);
  });

  test('report conflict outcome contains report range and explanation',
      () async {
    await db.into(db.raporKayitTable).insert(RaporKayitTableCompanion.insert(
        personelId: person,
        raporBaslangic: date,
        raporBitis: date,
        aciklama: const Value('Synthetic report')));
    final result = await repo.createActivitiesWithAssignments(
        [request('Target', 'HEYBET')],
        actor: admin);
    expect(result.outcomes.single.status, ActivityImportStatus.conflict);
    expect(result.outcomes.single.existingDescription, contains('Rapor'));
    expect(result.outcomes.single.existingDescription, contains(date));
    expect(result.outcomes.single.existingDescription,
        contains('Synthetic report'));
  });
}
