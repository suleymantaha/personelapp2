import 'dart:async';
import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

class ActivityRepository {
  ActivityRepository(this.db);

  final AppDatabase db;

  /// Watch activities with optional date range filter and pagination
  Stream<List<GunlukFaaliyetTableData>> watchAllActivities({
    int limit = 100,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) {
    // Auto-clean duplicates in background
    unawaited(consolidateDuplicateActivities());

    final query = db.select(db.gunlukFaaliyetTable);
    if (startDate != null) {
      query.where((tbl) => tbl.tarih.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((tbl) => tbl.tarih.isSmallerOrEqualValue(endDate));
    }
    query
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);
    return query.watch();
  }

  /// Merges duplicate activity entries for the same date and cleans up orphaned duplicates
  Future<void> consolidateDuplicateActivities() async {
    await db.transaction(() async {
      final allActs =
          await (db.select(db.gunlukFaaliyetTable)..orderBy([
                (tbl) => OrderingTerm(expression: tbl.id),
              ]))
              .get();

      final seenDates = <String, int>{};
      for (final act in allActs) {
        if (seenDates.containsKey(act.tarih)) {
          final primaryId = seenDates[act.tarih]!;
          final duplicateId = act.id;

          final dupAssignments = await (db.select(
            db.faaliyetPersonelAtamaTable,
          )..where((tbl) => tbl.faaliyetId.equals(duplicateId))).get();

          for (final atama in dupAssignments) {
            final existsInPrimary =
                await (db.select(db.faaliyetPersonelAtamaTable)..where(
                      (tbl) =>
                          tbl.faaliyetId.equals(primaryId) &
                          tbl.personelId.equals(atama.personelId),
                    ))
                    .getSingleOrNull();

            if (existsInPrimary == null) {
              await (db.update(
                db.faaliyetPersonelAtamaTable,
              )..where((tbl) => tbl.id.equals(atama.id))).write(
                FaaliyetPersonelAtamaTableCompanion(
                  faaliyetId: Value(primaryId),
                ),
              );
            } else {
              await (db.delete(
                db.faaliyetPersonelAtamaTable,
              )..where((tbl) => tbl.id.equals(atama.id))).go();
            }
          }

          await (db.delete(
            db.gunlukFaaliyetTable,
          )..where((tbl) => tbl.id.equals(duplicateId))).go();
        } else {
          seenDates[act.tarih] = act.id;
        }
      }
    });
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
      // 1. Check if an activity record already exists for this date
      final existingActs = await (db.select(
        db.gunlukFaaliyetTable,
      )..where((tbl) => tbl.tarih.equals(tarih))).get();

      int actId;
      if (existingActs.isNotEmpty) {
        actId = existingActs.first.id;
        // Optionally update activity title if needed
        await (db.update(
          db.gunlukFaaliyetTable,
        )..where((tbl) => tbl.id.equals(actId))).write(
          GunlukFaaliyetTableCompanion(
            faaliyetAdi: Value(faaliyetAdi),
            olusturanKullanici: Value(olusturanKullanici),
          ),
        );
      } else {
        actId = await db
            .into(db.gunlukFaaliyetTable)
            .insert(
              GunlukFaaliyetTableCompanion.insert(
                faaliyetAdi: faaliyetAdi,
                tarih: tarih,
                olusturanKullanici: olusturanKullanici,
                olusturmaTarihi: DateTime.now().toIso8601String(),
              ),
            );
      }

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

      // 2. Evaluate and upsert each assignment
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

        // Check if assignment already exists for this activity & personnel
        final currentAssignment =
            await (db.select(db.faaliyetPersonelAtamaTable)..where(
                  (tbl) =>
                      tbl.faaliyetId.equals(actId) & tbl.personelId.equals(pId),
                ))
                .getSingleOrNull();

        if (currentAssignment != null) {
          await (db.update(
            db.faaliyetPersonelAtamaTable,
          )..where((tbl) => tbl.id.equals(currentAssignment.id))).write(
            FaaliyetPersonelAtamaTableCompanion(
              gorevVeyaIzin: Value(gorev),
              durum: Value(evaluatedStatus),
              aciklama: Value(item['aciklama'] as String?),
            ),
          );
        } else {
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
      }

      return actId;
    });
  }

  /// Approve all pending assignments for a specific activity
  Future<int> approveAllAssignmentsForActivity(int activityId) async {
    return (db.update(db.faaliyetPersonelAtamaTable)..where(
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
    return (db.update(db.faaliyetPersonelAtamaTable)..where(
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

  /// Delete a single personnel assignment from an activity
  Future<int> deleteAssignment(int assignmentId) {
    return (db.delete(
      db.faaliyetPersonelAtamaTable,
    )..where((tbl) => tbl.id.equals(assignmentId))).go();
  }

  /// Update assignment duty type, note, and status
  Future<int> updateAssignmentDetails({
    required int assignmentId,
    required String gorevVeyaIzin,
    required String newStatus,
    String? aciklama,
  }) {
    return (db.update(
      db.faaliyetPersonelAtamaTable,
    )..where((tbl) => tbl.id.equals(assignmentId))).write(
      FaaliyetPersonelAtamaTableCompanion(
        gorevVeyaIzin: Value(gorevVeyaIzin),
        aciklama: Value(aciklama),
        durum: Value(newStatus),
      ),
    );
  }

  /// Add a single personnel assignment to an existing activity
  Future<int> addSingleAssignment({
    required int faaliyetId,
    required int personelId,
    required String gorevVeyaIzin,
    required String tarih,
    String? aciklama,
    bool isCommander = false,
  }) async {
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

    var evaluatedStatus = ConflictChecker.evaluateAssignmentStatus(
      personelId: personelId,
      targetDate: tarih,
      reports: domainReports,
      existingAssignments: existingAssignments,
    );

    if (isCommander) {
      evaluatedStatus = AssignmentStatus.beklemede;
    }

    return db
        .into(db.faaliyetPersonelAtamaTable)
        .insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: faaliyetId,
            personelId: personelId,
            gorevVeyaIzin: gorevVeyaIzin,
            durum: evaluatedStatus,
            aciklama: Value(aciklama),
          ),
        );
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
