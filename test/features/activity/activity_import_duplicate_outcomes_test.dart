import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

void main() {
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  late AppDatabase db;
  late ActivityRepository repo;
  late int person;
  late int target;
  const date = '2026-11-06';
  PersonnelAssignmentInput input(String duty) => PersonnelAssignmentInput(
      personnelId: person, duty: duty, isOutsideTeam: true);
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ActivityRepository(db);
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'admin', rol: UserRole.admin.storageValue));
    person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Synthetic',
            rutbe: 'J.Uzm.Çvş.',
            birlik: 'Test',
            kayitTarihi: date));
    target = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Target',
        tarih: date,
        olusturanKullanici: 'admin',
        personnelAssignments: [],
        actor: admin);
  });
  tearDown(() => db.close());

  test('repeated conflicting input never claims already assigned', () async {
    await repo.createActivityWithAssignments(
        faaliyetAdi: 'Existing duty',
        tarih: date,
        olusturanKullanici: 'admin',
        personnelAssignments: [input('NÖBETÇİ')],
        actor: admin);
    final result = await repo.addAssignmentsToActivity(
        activityId: target,
        assignments: [input('HEYBET'), input('HEYBET')],
        actor: admin);
    expect(result.outcomes, hasLength(1));
    expect(result.outcomes.single.status, ActivityImportStatus.conflict);
    expect(result.alreadyAssignedCount, 0);
    expect(result.conflictSkippedCount, 1);
  });

  test('empty duty cannot suppress later valid assignment', () async {
    final result = await repo.addAssignmentsToActivity(
        activityId: target,
        assignments: [input('  '), input('HEYBET')],
        actor: admin);
    expect(result.addedCount, 1);
    expect(result.outcomes.single.status, ActivityImportStatus.added);
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevVeyaIzin, 'HEYBET');
  });

  test('rejected target membership still describes the existing row', () async {
    await repo.addAssignmentsToActivity(
        activityId: target, assignments: [input('HEYBET')], actor: admin);
    await db.update(db.faaliyetPersonelAtamaTable).write(
        const FaaliyetPersonelAtamaTableCompanion(durum: Value('reddedildi')));
    final result = await repo.addAssignmentsToActivity(
        activityId: target, assignments: [input('HEYBET')], actor: admin);
    expect(result.outcomes.single.status, ActivityImportStatus.alreadyAssigned);
    expect(result.outcomes.single.existingDescription,
        contains('Target • HEYBET'));
  });

  test('different duty in the same bulk card remains a conflict', () async {
    await repo.addAssignmentsToActivity(
        activityId: target, assignments: [input('METİ')], actor: admin);
    final result = await repo.createActivitiesWithAssignments([
      ActivityCreateRequest(
          faaliyetAdi: 'Target',
          tarih: date,
          olusturanKullanici: 'admin',
          personnelAssignments: [input('HEYBET')]),
    ], actor: admin);
    expect(result.outcomes.single.status, ActivityImportStatus.conflict);
    expect(
        result.outcomes.single.existingDescription, contains('Target • METİ'));
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle())
            .gorevVeyaIzin,
        'METİ');
  });
}
