import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

class ActivityRepository {
  ActivityRepository(this.db);

  final AppDatabase db;

  /// Watch all activities
  Stream<List<GunlukFaaliyetTableData>> watchAllActivities() {
    return db.select(db.gunlukFaaliyetTable).watch();
  }

  /// Watch pending duty assignments
  Stream<List<FaaliyetPersonelAtamaTableData>> watchPendingAssignments() {
    return (db.select(db.faaliyetPersonelAtamaTable)..where(
          (tbl) => tbl.durum.equals(AssignmentStatus.beklemede),
        ))
        .watch();
  }

  /// Watch all duty assignments for a given date
  Stream<List<FaaliyetPersonelAtamaTableData>> watchAssignmentsByDate(
    String dateStr,
  ) {
    final query = db.select(db.faaliyetPersonelAtamaTable).join([
      innerJoin(
        db.gunlukFaaliyetTable,
        db.gunlukFaaliyetTable.id.equalsExp(
          db.faaliyetPersonelAtamaTable.faaliyetId,
        ),
      ),
    ])..where(db.gunlukFaaliyetTable.tarih.equals(dateStr));

    return query.watch().map(
      (rows) => rows
          .map((row) => row.readTable(db.faaliyetPersonelAtamaTable))
          .toList(),
    );
  }

  /// Watch all activities for a specific team/squad
  Stream<List<GunlukFaaliyetTableData>> watchActivitiesForTeam(int timId) {
    final query = db.select(db.gunlukFaaliyetTable).join([
      innerJoin(
        db.faaliyetPersonelAtamaTable,
        db.faaliyetPersonelAtamaTable.faaliyetId.equalsExp(
          db.gunlukFaaliyetTable.id,
        ),
      ),
      innerJoin(
        db.personelTable,
        db.personelTable.id.equalsExp(
          db.faaliyetPersonelAtamaTable.personelId,
        ),
      ),
    ])..where(db.personelTable.timId.equals(timId));

    return query.watch().map((rows) {
      final map = <int, GunlukFaaliyetTableData>{};
      for (final row in rows) {
        final act = row.readTable(db.gunlukFaaliyetTable);
        map[act.id] = act;
      }
      return map.values.toList();
    });
  }

  /// Save daily activity and perform smart conflict evaluation for each assigned personnel
  Future<int> createActivityWithAssignments({
    required String faaliyetAdi,
    required String tarih,
    required String olusturanKullanici,
    required List<Map<String, dynamic>> personnelAssignments,
    bool isCommander = false,
  }) async {
    return db.transaction(() async {
      // 1. Create activity record
      final actId = await db
          .into(db.gunlukFaaliyetTable)
          .insert(
            GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: faaliyetAdi,
              tarih: tarih,
              olusturanKullanici: olusturanKullanici,
              olusturmaTarihi: DateTime.now().toIso8601String(),
            ),
          );

      // Fetch active reports
      final rawReports = await db.select(db.raporKayitTable).get();
      final domainReports = rawReports
          .map(
            (r) => PersonnelReport(
              id: r.id,
              personelId: r.personelId,
              raporBaslangic: r.raporBaslangic,
              raporBitis: r.raporBitis,
              aciklama: r.aciklama,
            ),
          )
          .toList();

      // Fetch existing approved assignments on this date
      final query = db.select(db.faaliyetPersonelAtamaTable).join([
        innerJoin(
          db.gunlukFaaliyetTable,
          db.gunlukFaaliyetTable.id.equalsExp(
            db.faaliyetPersonelAtamaTable.faaliyetId,
          ),
        ),
      ])..where(db.gunlukFaaliyetTable.tarih.equals(tarih));

      final existingRows = await query.get();
      final existingAssignments = existingRows.map((row) {
        final atama = row.readTable(db.faaliyetPersonelAtamaTable);
        final faal = row.readTable(db.gunlukFaaliyetTable);
        return ExistingDutyAssignment(
          id: atama.id,
          faaliyetId: atama.faaliyetId,
          personelId: atama.personelId,
          tarih: faal.tarih,
          gorevVeyaIzin: atama.gorevVeyaIzin,
          durum: atama.durum,
        );
      }).toList();

      // 2. Evaluate and insert each assignment
      for (final item in personnelAssignments) {
        final pId = item['personelId'] as int;
        final gorev = item['gorevVeyaIzin'] as String;

        var evaluatedStatus = ConflictChecker.evaluateAssignmentStatus(
          personelId: pId,
          targetDate: tarih,
          reports: domainReports,
          existingAssignments: existingAssignments,
        );

        // If submitted by Tim Komutanı, force status to 'beklemede' for Admin Approval
        if (isCommander) {
          evaluatedStatus = AssignmentStatus.beklemede;
        }

        await db
            .into(db.faaliyetPersonelAtamaTable)
            .insert(
              FaaliyetPersonelAtamaTableCompanion.insert(
                faaliyetId: actId,
                personelId: pId,
                gorevVeyaIzin: gorev,
                durum: evaluatedStatus,
                aciklama: Value(item['aciklama'] as String?),
              ),
            );
      }

      return actId;
    });
  }

  /// Approve all pending assignments for a specific activity
  Future<int> approveAllAssignmentsForActivity(int activityId) async {
    return (db.update(db.faaliyetPersonelAtamaTable)
          ..where(
            (tbl) =>
                tbl.faaliyetId.equals(activityId) &
                tbl.durum.equals(AssignmentStatus.beklemede),
          ))
        .write(
          const FaaliyetPersonelAtamaTableCompanion(
            durum: Value(AssignmentStatus.onaylandi),
          ),
        );
  }

  /// Reject all pending assignments for a specific activity
  Future<int> rejectAllAssignmentsForActivity(int activityId) async {
    return (db.update(db.faaliyetPersonelAtamaTable)
          ..where(
            (tbl) =>
                tbl.faaliyetId.equals(activityId) &
                tbl.durum.equals(AssignmentStatus.beklemede),
          ))
        .write(
          const FaaliyetPersonelAtamaTableCompanion(
            durum: Value(AssignmentStatus.reddedildi),
          ),
        );
  }

  /// Approve or Reject a pending assignment
  Future<int> updateAssignmentStatus(int assignmentId, String newStatus) {
    return (db.update(db.faaliyetPersonelAtamaTable)
          ..where((tbl) => tbl.id.equals(assignmentId)))
        .write(FaaliyetPersonelAtamaTableCompanion(durum: Value(newStatus)));
  }

  /// Save medical report
  Future<int> addMedicalReport({
    required int personelId,
    required String raporBaslangic,
    required String raporBitis,
    String? aciklama,
  }) {
    return db
        .into(db.raporKayitTable)
        .insert(
          RaporKayitTableCompanion.insert(
            personelId: personelId,
            raporBaslangic: raporBaslangic,
            raporBitis: raporBitis,
            aciklama: Value(aciklama),
          ),
        );
  }
}
