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

  // ── helpers ──────────────────────────────────────────────────

  Future<int> addActivity(String date, {String? title}) =>
      db.into(db.gunlukFaaliyetTable).insert(
            GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: title ?? 'Günlük Faaliyet ($date)',
              tarih: date,
              olusturanKullanici: 'admin',
              olusturmaTarihi: '2026-08-03',
            ),
          );

  Future<int> addPersonnel(String name) => db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
          adSoyad: name,
          rutbe: 'Er',
          birlik: 'K.H',
          kayitTarihi: '2026-08-03',
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

  Future<List<FaaliyetPersonelAtamaTableData>> assignmentsFor(int aid) =>
      (db.select(db.faaliyetPersonelAtamaTable)
            ..where((t) => t.faaliyetId.equals(aid)))
          .get();

  // ── tests ────────────────────────────────────────────────────

  test('taşıma başarılı: personel kaynak karttan çıkar, hedef karta girer',
      () async {
    final p = await addPersonnel('Ali Er');
    final src = await addActivity('2026-08-03', title: 'Sabah');
    final tgt = await addActivity('2026-08-03', title: 'Öğle');
    await addAssignment(
      activityId: src,
      personnelId: p,
      duty: 'NÖBETÇİ',
      note: 'Gece nöbeti',
    );

    final result = await repo.transferPersonnelBetweenActivities(
      assignmentId: (await assignmentsFor(src)).single.id,
      targetActivityId: tgt,
      actor: adminSession,
    );

    expect(result.moved, isTrue);
    expect(result.reason, isNull);
    expect(await assignmentsFor(src), isEmpty);
    final tgtRows = await assignmentsFor(tgt);
    expect(tgtRows.length, 1);
    expect(tgtRows.single.personelId, p);
    expect(tgtRows.single.gorevVeyaIzin, 'NÖBETÇİ');
    expect(tgtRows.single.aciklama, 'Gece nöbeti');
  });

  test('hedefte aynı personel varsa moved:false döner, kaynak değişmez',
      () async {
    final p = await addPersonnel('Veli Er');
    final src = await addActivity('2026-08-03', title: 'Sabah');
    final tgt = await addActivity('2026-08-03', title: 'Öğle');
    await addAssignment(activityId: src, personnelId: p);
    // p zaten hedefte
    await addAssignment(activityId: tgt, personnelId: p);

    final id = (await assignmentsFor(src)).single.id;
    final result = await repo.transferPersonnelBetweenActivities(
      assignmentId: id,
      targetActivityId: tgt,
      actor: adminSession,
    );

    expect(result.moved, isFalse);
    expect(result.reason, contains('zaten'));
    expect(await assignmentsFor(src), hasLength(1));
  });

  test('onaylı durum korunur (aynı tarihte başka çakışma yok)', () async {
    final p = await addPersonnel('Ahmet Er');
    final src = await addActivity('2026-08-03');
    final tgt = await addActivity('2026-08-03', title: 'Akşam');
    await addAssignment(
      activityId: src,
      personnelId: p,
      status: AssignmentStatus.onaylandi,
    );

    final id = (await assignmentsFor(src)).single.id;
    await repo.transferPersonnelBetweenActivities(
      assignmentId: id,
      targetActivityId: tgt,
      actor: adminSession,
    );

    final row = (await assignmentsFor(tgt)).single;
    expect(row.durum, AssignmentStatus.onaylandi);
  });

  test('varolan atama bulunamazsa ArgumentError', () async {
    final tgt = await addActivity('2026-08-03');
    await expectLater(
      repo.transferPersonnelBetweenActivities(
        assignmentId: 99999,
        targetActivityId: tgt,
        actor: adminSession,
      ),
      throwsArgumentError,
    );
  });

  test('hedef faaliyet bulunamazsa ArgumentError, kaynak değişmez', () async {
    final p = await addPersonnel('Mehmet Er');
    final src = await addActivity('2026-08-03');
    await addAssignment(activityId: src, personnelId: p);
    final id = (await assignmentsFor(src)).single.id;

    await expectLater(
      repo.transferPersonnelBetweenActivities(
        assignmentId: id,
        targetActivityId: 99999,
        actor: adminSession,
      ),
      throwsArgumentError,
    );
    expect(await assignmentsFor(src), hasLength(1));
  });

  test('admin değilse AuthorizationException', () async {
    final p = await addPersonnel('Kemal Er');
    final src = await addActivity('2026-08-03');
    final tgt = await addActivity('2026-08-03', title: 'Hedef');
    await addAssignment(activityId: src, personnelId: p);
    final id = (await assignmentsFor(src)).single.id;

    const nonAdmin = UserSessionState(
      username: 'komutan',
      role: UserRole.teamCommander,
      timId: 1,
    );

    expect(
      () => repo.transferPersonnelBetweenActivities(
        assignmentId: id,
        targetActivityId: tgt,
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
  });
}
