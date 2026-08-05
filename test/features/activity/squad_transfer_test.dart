import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repo;

  const adminSession = UserSessionState(
    username: 'admin',
    role: UserRole.admin,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ActivityRepository(db);
  });

  tearDown(() => db.close());

  // ────────────────────────── helpers ──────────────────────────

  Future<int> addSquad(String name) => db.into(db.timTable).insert(
        TimTableCompanion.insert(
          timAdi: name,
          olusturmaTarihi: '2026-08-01',
        ),
      );

  Future<int> addPersonnel(String name, {int? squadId}) =>
      db.into(db.personelTable).insert(
            PersonelTableCompanion.insert(
              adSoyad: name,
              rutbe: 'Er',
              birlik: 'K.H',
              kayitTarihi: '2026-08-01',
              timId: Value(squadId),
            ),
          );

  Future<int> addActivity(String date, {String? title}) =>
      db.into(db.gunlukFaaliyetTable).insert(
            GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: title ?? 'Günlük Faaliyet ($date)',
              tarih: date,
              olusturanKullanici: 'admin',
              olusturmaTarihi: '2026-08-01',
            ),
          );

  Future<int> addAssignment({
    required int activityId,
    required int personnelId,
    String duty = 'GÖREVLİ',
    String status = AssignmentStatus.onaylandi,
    String? note,
  }) =>
      db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activityId,
              personelId: personnelId,
              gorevVeyaIzin: duty,
              durum: status,
              aciklama: Value(note),
            ),
          );

  Future<List<FaaliyetPersonelAtamaTableData>> assignmentsFor(
    int activityId,
  ) =>
      (db.select(db.faaliyetPersonelAtamaTable)
            ..where((tbl) => tbl.faaliyetId.equals(activityId)))
          .get();

  // ─────────────────────────── tests ───────────────────────────

  test(
    'transfers all squad personnel from source to target activity',
    () async {
      final squadId = await addSquad('1-B Timi');
      final p1 = await addPersonnel('Ali Er', squadId: squadId);
      final p2 = await addPersonnel('Veli Er', squadId: squadId);

      final sourceId =
          await addActivity('2026-08-03', title: 'Sabah Faaliyeti');
      final targetId = await addActivity('2026-08-03', title: 'Öğle Faaliyeti');

      await addAssignment(
        activityId: sourceId,
        personnelId: p1,
        duty: 'NÖBETÇİ',
        note: 'İlk nöbet',
      );
      await addAssignment(activityId: sourceId, personnelId: p2);

      final result = await repo.transferSquadBetweenActivities(
        sourceActivityId: sourceId,
        targetActivityId: targetId,
        squadId: squadId,
        actor: adminSession,
      );

      expect(result.movedCount, 2, reason: 'Her iki personel taşınmalıydı');
      expect(result.skippedCount, 0);
      expect(result.isComplete, isTrue);

      // Source should now be empty for this squad
      final sourceAssignments = await assignmentsFor(sourceId);
      expect(
        sourceAssignments.any(
          (a) => a.personelId == p1 || a.personelId == p2,
        ),
        isFalse,
        reason: 'Kaynak faaliyette tim personeli kalmamalı',
      );

      // Target should have them
      final targetAssignments = await assignmentsFor(targetId);
      final targetPersonnelIds = targetAssignments.map((a) => a.personelId);
      expect(targetPersonnelIds, containsAll([p1, p2]));

      // Duty and note should be preserved
      final p1Assignment =
          targetAssignments.firstWhere((a) => a.personelId == p1);
      expect(p1Assignment.gorevVeyaIzin, 'NÖBETÇİ');
      expect(p1Assignment.aciklama, 'İlk nöbet');
    },
  );

  test('creates a new card and transfers the squad in one operation', () async {
    final squadId = await addSquad('Yeni Kart Timi');
    final personId = await addPersonnel('Tim Personeli', squadId: squadId);
    final sourceId = await addActivity('2026-08-03', title: 'Kaynak Kart');
    await addAssignment(activityId: sourceId, personnelId: personId);

    final result = await repo.createActivityAndTransferSquad(
      sourceActivityId: sourceId,
      squadId: squadId,
      activityName: 'Yeni Hedef Kart',
      actor: adminSession,
    );

    expect(result.movedCount, 1);
    final activities = await db.select(db.gunlukFaaliyetTable).get();
    expect(activities, hasLength(2));
    final target = activities.singleWhere(
      (activity) => activity.faaliyetAdi == 'Yeni Hedef Kart',
    );
    expect(target.tarih, '2026-08-03');
    expect(await assignmentsFor(sourceId), isEmpty);
    expect((await assignmentsFor(target.id)).single.personelId, personId);
  });

  test(
    'skips personnel already present in the target activity',
    () async {
      final squadId = await addSquad('2-B Timi');
      final p1 = await addPersonnel('Ahmet Er', squadId: squadId);
      final p2 = await addPersonnel('Mehmet Er', squadId: squadId);

      final sourceId = await addActivity('2026-08-03', title: 'Kaynak Kart');
      final targetId = await addActivity('2026-08-03', title: 'Hedef Kart');

      await addAssignment(activityId: sourceId, personnelId: p1);
      await addAssignment(activityId: sourceId, personnelId: p2);
      // p1 already in target
      await addAssignment(activityId: targetId, personnelId: p1);

      final result = await repo.transferSquadBetweenActivities(
        sourceActivityId: sourceId,
        targetActivityId: targetId,
        squadId: squadId,
        actor: adminSession,
      );

      // p1 was skipped (already in target), p2 was moved
      expect(result.movedCount, 1);
      expect(result.skippedCount, 1);
      expect(result.skippedPersonnelIds, contains(p1));
      expect(result.isComplete, isFalse);

      // p2 must now be in target
      final targetAssignments = await assignmentsFor(targetId);
      expect(
        targetAssignments.any((a) => a.personelId == p2),
        isTrue,
      );

      // p1 must still be in source (wasn't removed since it was skipped)
      final sourceAssignments = await assignmentsFor(sourceId);
      expect(sourceAssignments.any((a) => a.personelId == p1), isTrue);
    },
  );

  test(
    'returns empty result when squad has no assignments in source activity',
    () async {
      final squadId = await addSquad('3-B Timi');
      final sourceId = await addActivity('2026-08-03');
      final targetId = await addActivity('2026-08-03', title: 'Hedef');

      final result = await repo.transferSquadBetweenActivities(
        sourceActivityId: sourceId,
        targetActivityId: targetId,
        squadId: squadId,
        actor: adminSession,
      );

      expect(result.movedCount, 0);
      expect(result.skippedCount, 0);
    },
  );

  test(
    'is atomic: no partial transfer when source activity does not exist',
    () async {
      final squadId = await addSquad('4-B Timi');
      final targetId = await addActivity('2026-08-03');

      await expectLater(
        repo.transferSquadBetweenActivities(
          sourceActivityId: 99999,
          targetActivityId: targetId,
          squadId: squadId,
          actor: adminSession,
        ),
        throwsArgumentError,
      );

      // Target should still be empty
      expect(await assignmentsFor(targetId), isEmpty);
    },
  );

  test(
    'preserves approved status when target date has no conflicts',
    () async {
      final squadId = await addSquad('5-B Timi');
      final p1 = await addPersonnel('Kemal Er', squadId: squadId);

      final sourceId = await addActivity('2026-08-03');
      final targetId = await addActivity('2026-08-03', title: 'Öğleden Sonra');

      await addAssignment(
        activityId: sourceId,
        personnelId: p1,
        status: AssignmentStatus.onaylandi,
      );

      final result = await repo.transferSquadBetweenActivities(
        sourceActivityId: sourceId,
        targetActivityId: targetId,
        squadId: squadId,
        actor: adminSession,
      );

      expect(result.movedCount, 1);

      final targetAssignments = await assignmentsFor(targetId);
      final transferredAssignment =
          targetAssignments.firstWhere((a) => a.personelId == p1);
      // Same date, no other records → should remain onaylandi
      expect(transferredAssignment.durum, AssignmentStatus.onaylandi);
    },
  );

  test(
    'does not affect other squad personnel in the same source activity',
    () async {
      final squadA = await addSquad('6-B Timi');
      final squadB = await addSquad('7-B Timi');
      final pA = await addPersonnel('Tim A Er', squadId: squadA);
      final pB = await addPersonnel('Tim B Er', squadId: squadB);

      final sourceId = await addActivity('2026-08-03');
      final targetId = await addActivity('2026-08-03', title: 'Yeni Kart');

      await addAssignment(activityId: sourceId, personnelId: pA);
      await addAssignment(activityId: sourceId, personnelId: pB);

      await repo.transferSquadBetweenActivities(
        sourceActivityId: sourceId,
        targetActivityId: targetId,
        squadId: squadA,
        actor: adminSession,
      );

      // Squad B should still be in source
      final sourceAssignments = await assignmentsFor(sourceId);
      expect(
        sourceAssignments.any((a) => a.personelId == pB),
        isTrue,
        reason: 'Tim B taşıma işleminden etkilenmemeli',
      );

      // Squad A should be in target
      final targetAssignments = await assignmentsFor(targetId);
      expect(targetAssignments.any((a) => a.personelId == pA), isTrue);
    },
  );

  test(
    'throws AuthorizationException when actor is not admin',
    () async {
      final squadId = await addSquad('8-B Timi');
      final sourceId = await addActivity('2026-08-03');
      final targetId = await addActivity('2026-08-03', title: 'Hedef');

      const nonAdmin = UserSessionState(
        username: 'komutan',
        role: UserRole.teamCommander,
        timId: 1,
      );

      expect(
        () => repo.transferSquadBetweenActivities(
          sourceActivityId: sourceId,
          targetActivityId: targetId,
          squadId: squadId,
          actor: nonAdmin,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('yöneticiler tarafından'),
          ),
        ),
      );
    },
  );
}
