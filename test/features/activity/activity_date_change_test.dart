import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repository;
  late MatrixRepository matrixRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ActivityRepository(db);
    matrixRepository = MatrixRepository(db);
  });

  tearDown(() => db.close());

  Future<int> addPersonnel(String name) {
    return db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: name,
            rutbe: 'J.Uzm.Çvş.',
            birlik: 'K.H',
            kayitTarihi: '2026-07-01',
          ),
        );
  }

  Future<int> addActivity(String date, {String? title}) {
    return db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: title ?? 'Günlük Faaliyet ($date)',
            tarih: date,
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-07-01',
          ),
        );
  }

  Future<int> addAssignment({
    required int activityId,
    required int personnelId,
    required String status,
  }) {
    return db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activityId,
            personelId: personnelId,
            gorevVeyaIzin: DutyOrLeaveType.heybet,
            durum: status,
          ),
        );
  }

  test(
    'moves activity and matrix day while preserving IDs and safe statuses',
    () async {
      final approvedPerson = await addPersonnel('Onaylı Personel');
      final pendingPerson = await addPersonnel('Bekleyen Personel');
      final rejectedPerson = await addPersonnel('Reddedilen Personel');
      final activityId = await addActivity('2026-07-27');
      final approvedAssignment = await addAssignment(
        activityId: activityId,
        personnelId: approvedPerson,
        status: AssignmentStatus.onaylandi,
      );
      final pendingAssignment = await addAssignment(
        activityId: activityId,
        personnelId: pendingPerson,
        status: AssignmentStatus.beklemede,
      );
      final rejectedAssignment = await addAssignment(
        activityId: activityId,
        personnelId: rejectedPerson,
        status: AssignmentStatus.reddedildi,
      );
      await db.into(db.raporKayitTable).insert(
            RaporKayitTableCompanion.insert(
              personelId: approvedPerson,
              raporBaslangic: '2026-07-28',
              raporBitis: '2026-07-29',
            ),
          );

      final preview = await repository.previewActivityDateChange(
        activityId: activityId,
        newDate: '2026-07-28',
      );
      expect(preview.status, ActivityDateChangeStatus.success);
      expect(preview.assignmentCount, 3);
      expect(preview.pendingAssignmentCount, 1);

      final result = await repository.changeActivityDate(
        activityId: activityId,
        newDate: '2026-07-28',
      );
      expect(result.status, ActivityDateChangeStatus.success);
      expect(result.pendingAssignmentCount, 1);

      final activity = await (db.select(db.gunlukFaaliyetTable)
            ..where((table) => table.id.equals(activityId)))
          .getSingle();
      expect(activity.id, activityId);
      expect(activity.tarih, '2026-07-28');
      expect(activity.faaliyetAdi, 'Günlük Faaliyet (2026-07-28)');

      final assignments = await (db.select(db.faaliyetPersonelAtamaTable)
            ..where((table) => table.faaliyetId.equals(activityId)))
          .get();
      expect(
        assignments.map((assignment) => assignment.id),
        containsAll([
          approvedAssignment,
          pendingAssignment,
          rejectedAssignment,
        ]),
      );
      expect(
        assignments.singleWhere((item) => item.id == approvedAssignment).durum,
        AssignmentStatus.beklemede,
      );
      expect(
        assignments.singleWhere((item) => item.id == pendingAssignment).durum,
        AssignmentStatus.beklemede,
      );
      expect(
        assignments.singleWhere((item) => item.id == rejectedAssignment).durum,
        AssignmentStatus.reddedildi,
      );

      final matrix = await matrixRepository.watchMonthlyMatrix('2026-07').first;
      expect(matrix[approvedPerson]?[27], isNull);
      expect(matrix[approvedPerson]?[28]?.displayCode, 'B');
      expect(
        matrix[approvedPerson]?[28]?.entries.single.duty,
        DutyOrLeaveType.heybet,
      );
    },
  );

  test('moves beside an existing target-date activity without merging',
      () async {
    final personnelId = await addPersonnel('Korunan Personel');
    final sourceId = await addActivity('2026-07-27');
    final targetId = await addActivity('2026-07-28');
    final assignmentId = await addAssignment(
      activityId: sourceId,
      personnelId: personnelId,
      status: AssignmentStatus.onaylandi,
    );

    final result = await repository.changeActivityDate(
      activityId: sourceId,
      newDate: '2026-07-28',
    );
    expect(result.status, ActivityDateChangeStatus.success);

    final source = await (db.select(db.gunlukFaaliyetTable)
          ..where((table) => table.id.equals(sourceId)))
        .getSingle();
    final target = await (db.select(db.gunlukFaaliyetTable)
          ..where((table) => table.id.equals(targetId)))
        .getSingle();
    final assignment = await (db.select(db.faaliyetPersonelAtamaTable)
          ..where((table) => table.id.equals(assignmentId)))
        .getSingle();
    expect(source.tarih, '2026-07-28');
    expect(target.tarih, '2026-07-28');
    expect(assignment.faaliyetId, sourceId);
    expect(assignment.durum, AssignmentStatus.onaylandi);
  });

  test('preserves a custom activity title across a month boundary', () async {
    final activityId = await addActivity(
      '2026-07-31',
      title: 'Özel Gece Devriyesi',
    );

    final result = await repository.changeActivityDate(
      activityId: activityId,
      newDate: '2026-08-01',
    );
    expect(result.status, ActivityDateChangeStatus.success);

    final activity = await (db.select(db.gunlukFaaliyetTable)
          ..where((table) => table.id.equals(activityId)))
        .getSingle();
    expect(activity.tarih, '2026-08-01');
    expect(activity.faaliyetAdi, 'Özel Gece Devriyesi');
  });

  test('rejects invalid and unchanged dates', () async {
    final activityId = await addActivity('2026-07-27');

    final invalid = await repository.changeActivityDate(
      activityId: activityId,
      newDate: '2026-02-30',
    );
    final unchanged = await repository.changeActivityDate(
      activityId: activityId,
      newDate: '2026-07-27',
    );

    expect(invalid.status, ActivityDateChangeStatus.invalidDate);
    expect(unchanged.status, ActivityDateChangeStatus.unchanged);
  });
}
