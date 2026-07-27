import 'dart:async';
import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

enum ActivityDateChangeStatus {
  success,
  unchanged,
  targetDateOccupied,
  activityNotFound,
  invalidDate,
}

class ActivityDateChangePreview {
  const ActivityDateChangePreview({
    required this.status,
    required this.oldDate,
    required this.newDate,
    required this.assignmentCount,
    required this.pendingAssignmentCount,
  });

  final ActivityDateChangeStatus status;
  final String oldDate;
  final String newDate;
  final int assignmentCount;
  final int pendingAssignmentCount;

  bool get canChange =>
      status == ActivityDateChangeStatus.success ||
      status == ActivityDateChangeStatus.unchanged;
}

class ActivityDateChangeResult extends ActivityDateChangePreview {
  const ActivityDateChangeResult({
    required super.status,
    required super.oldDate,
    required super.newDate,
    required super.assignmentCount,
    required super.pendingAssignmentCount,
  });
}

class ActivityRepository {
  ActivityRepository(this.db);

  final AppDatabase db;

  bool _isValidIsoDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    final canonical = '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    return canonical == value;
  }

  Future<ActivityDateChangePreview> previewActivityDateChange({
    required int activityId,
    required String newDate,
  }) async {
    final activity = await (db.select(
      db.gunlukFaaliyetTable,
    )..where((tbl) => tbl.id.equals(activityId)))
        .getSingleOrNull();
    if (activity == null) {
      return ActivityDateChangePreview(
        status: ActivityDateChangeStatus.activityNotFound,
        oldDate: '',
        newDate: newDate,
        assignmentCount: 0,
        pendingAssignmentCount: 0,
      );
    }

    final assignments = await (db.select(
      db.faaliyetPersonelAtamaTable,
    )..where((tbl) => tbl.faaliyetId.equals(activityId)))
        .get();
    if (!_isValidIsoDate(newDate)) {
      return ActivityDateChangePreview(
        status: ActivityDateChangeStatus.invalidDate,
        oldDate: activity.tarih,
        newDate: newDate,
        assignmentCount: assignments.length,
        pendingAssignmentCount: 0,
      );
    }
    if (activity.tarih == newDate) {
      return ActivityDateChangePreview(
        status: ActivityDateChangeStatus.unchanged,
        oldDate: activity.tarih,
        newDate: newDate,
        assignmentCount: assignments.length,
        pendingAssignmentCount: 0,
      );
    }

    final occupied = await (db.select(db.gunlukFaaliyetTable)
          ..where(
            (tbl) => tbl.tarih.equals(newDate) & tbl.id.isNotValue(activityId),
          ))
        .get();
    if (occupied.isNotEmpty) {
      return ActivityDateChangePreview(
        status: ActivityDateChangeStatus.targetDateOccupied,
        oldDate: activity.tarih,
        newDate: newDate,
        assignmentCount: assignments.length,
        pendingAssignmentCount: 0,
      );
    }

    final pendingCount = await _countApprovedAssignmentsBecomingPending(
      assignments: assignments,
      newDate: newDate,
      movingActivityId: activityId,
    );
    return ActivityDateChangePreview(
      status: ActivityDateChangeStatus.success,
      oldDate: activity.tarih,
      newDate: newDate,
      assignmentCount: assignments.length,
      pendingAssignmentCount: pendingCount,
    );
  }

  Future<ActivityDateChangeResult> changeActivityDate({
    required int activityId,
    required String newDate,
  }) {
    return db.transaction(() async {
      final preview = await previewActivityDateChange(
        activityId: activityId,
        newDate: newDate,
      );
      if (preview.status != ActivityDateChangeStatus.success) {
        return ActivityDateChangeResult(
          status: preview.status,
          oldDate: preview.oldDate,
          newDate: preview.newDate,
          assignmentCount: preview.assignmentCount,
          pendingAssignmentCount: preview.pendingAssignmentCount,
        );
      }

      final activity = await (db.select(
        db.gunlukFaaliyetTable,
      )..where((tbl) => tbl.id.equals(activityId)))
          .getSingle();
      final assignments = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((tbl) => tbl.faaliyetId.equals(activityId)))
          .get();
      final reports = await db.select(db.raporKayitTable).get();

      var pendingCount = 0;
      for (final assignment in assignments) {
        if (assignment.durum != AssignmentStatus.onaylandi) continue;
        final hasReport = reports.any(
          (report) =>
              report.personelId == assignment.personelId &&
              newDate.compareTo(report.raporBaslangic) >= 0 &&
              newDate.compareTo(report.raporBitis) <= 0,
        );
        if (hasReport) {
          await (db.update(db.faaliyetPersonelAtamaTable)
                ..where((tbl) => tbl.id.equals(assignment.id)))
              .write(
            const FaaliyetPersonelAtamaTableCompanion(
              durum: Value(AssignmentStatus.beklemede),
            ),
          );
          pendingCount++;
        }
      }

      final automaticTitle = 'Günlük Faaliyet (${activity.tarih})';
      final newTitle = activity.faaliyetAdi == automaticTitle
          ? 'Günlük Faaliyet ($newDate)'
          : activity.faaliyetAdi;
      await (db.update(
        db.gunlukFaaliyetTable,
      )..where((tbl) => tbl.id.equals(activityId)))
          .write(
        GunlukFaaliyetTableCompanion(
          tarih: Value(newDate),
          faaliyetAdi: Value(newTitle),
        ),
      );

      return ActivityDateChangeResult(
        status: ActivityDateChangeStatus.success,
        oldDate: activity.tarih,
        newDate: newDate,
        assignmentCount: assignments.length,
        pendingAssignmentCount: pendingCount,
      );
    });
  }

  Future<int> _countApprovedAssignmentsBecomingPending({
    required List<FaaliyetPersonelAtamaTableData> assignments,
    required String newDate,
    required int movingActivityId,
  }) async {
    final reports = await db.select(db.raporKayitTable).get();
    final otherRows = await (db
            .select(
      db.faaliyetPersonelAtamaTable,
    )
            .join([
      innerJoin(
        db.gunlukFaaliyetTable,
        db.gunlukFaaliyetTable.id.equalsExp(
          db.faaliyetPersonelAtamaTable.faaliyetId,
        ),
      ),
    ])
          ..where(
            db.gunlukFaaliyetTable.tarih.equals(newDate) &
                db.gunlukFaaliyetTable.id.isNotValue(movingActivityId) &
                db.faaliyetPersonelAtamaTable.durum.equals(
                  AssignmentStatus.onaylandi,
                ),
          ))
        .get();
    final occupiedPersonnelIds = otherRows
        .map(
          (row) => row.readTable(db.faaliyetPersonelAtamaTable).personelId,
        )
        .toSet();

    return assignments.where((assignment) {
      if (assignment.durum != AssignmentStatus.onaylandi) return false;
      final hasReport = reports.any(
        (report) =>
            report.personelId == assignment.personelId &&
            newDate.compareTo(report.raporBaslangic) >= 0 &&
            newDate.compareTo(report.raporBitis) <= 0,
      );
      return hasReport || occupiedPersonnelIds.contains(assignment.personelId);
    }).length;
  }

  /// Watch activities with optional date range filter and pagination
  Stream<List<GunlukFaaliyetTableData>> watchAllActivities({
    int limit = 100,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) {
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
      final allActs = await (db.select(db.gunlukFaaliyetTable)
            ..orderBy([
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
          )..where((tbl) => tbl.faaliyetId.equals(duplicateId)))
              .get();

          for (final atama in dupAssignments) {
            final existsInPrimary =
                await (db.select(db.faaliyetPersonelAtamaTable)
                      ..where(
                        (tbl) =>
                            tbl.faaliyetId.equals(primaryId) &
                            tbl.personelId.equals(atama.personelId),
                      ))
                    .getSingleOrNull();

            if (existsInPrimary == null) {
              await (db.update(
                db.faaliyetPersonelAtamaTable,
              )..where((tbl) => tbl.id.equals(atama.id)))
                  .write(
                FaaliyetPersonelAtamaTableCompanion(
                  faaliyetId: Value(primaryId),
                ),
              );
            } else {
              await (db.delete(
                db.faaliyetPersonelAtamaTable,
              )..where((tbl) => tbl.id.equals(atama.id)))
                  .go();
            }
          }

          await (db.delete(
            db.gunlukFaaliyetTable,
          )..where((tbl) => tbl.id.equals(duplicateId)))
              .go();
        } else {
          seenDates[act.tarih] = act.id;
        }
      }
    });
  }

  /// Watch pending duty assignments
  Stream<List<FaaliyetPersonelAtamaTableData>> watchPendingAssignments() {
    return (db.select(db.faaliyetPersonelAtamaTable)
          ..where(
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
    ])
      ..where(db.gunlukFaaliyetTable.tarih.equals(dateStr));

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
    ])
      ..where(db.personelTable.timId.equals(timId));

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
      )..where((tbl) => tbl.tarih.equals(tarih)))
          .get();

      int actId;
      if (existingActs.isNotEmpty) {
        actId = existingActs.first.id;
        // Optionally update activity title if needed
        await (db.update(
          db.gunlukFaaliyetTable,
        )..where((tbl) => tbl.id.equals(actId)))
            .write(
          GunlukFaaliyetTableCompanion(
            faaliyetAdi: Value(faaliyetAdi),
            olusturanKullanici: Value(olusturanKullanici),
          ),
        );
      } else {
        actId = await db.into(db.gunlukFaaliyetTable).insert(
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
      ])
        ..where(db.gunlukFaaliyetTable.tarih.equals(tarih));

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
        final rawPid = item['personelId'];
        final rawGorev = item['gorevVeyaIzin'];
        if (rawPid == null || rawGorev == null) continue;

        final pId = rawPid is int ? rawPid : int.tryParse(rawPid.toString());
        final gorev = rawGorev.toString();
        if (pId == null || gorev.isEmpty) continue;

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
        final currentAssignment = await (db
                .select(db.faaliyetPersonelAtamaTable)
              ..where(
                (tbl) =>
                    tbl.faaliyetId.equals(actId) & tbl.personelId.equals(pId),
              ))
            .getSingleOrNull();

        if (currentAssignment != null) {
          await (db.update(
            db.faaliyetPersonelAtamaTable,
          )..where((tbl) => tbl.id.equals(currentAssignment.id)))
              .write(
            FaaliyetPersonelAtamaTableCompanion(
              gorevVeyaIzin: Value(gorev),
              durum: Value(evaluatedStatus),
              aciklama: Value(item['aciklama'] as String?),
            ),
          );
        } else {
          await db.into(db.faaliyetPersonelAtamaTable).insert(
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

  /// Delete a single personnel assignment from an activity
  Future<int> deleteAssignment(int assignmentId) {
    return (db.delete(
      db.faaliyetPersonelAtamaTable,
    )..where((tbl) => tbl.id.equals(assignmentId)))
        .go();
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
    )..where((tbl) => tbl.id.equals(assignmentId)))
        .write(
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
    ])
      ..where(db.gunlukFaaliyetTable.tarih.equals(tarih));

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

    return db.into(db.faaliyetPersonelAtamaTable).insert(
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
    return db.into(db.raporKayitTable).insert(
          RaporKayitTableCompanion.insert(
            personelId: personelId,
            raporBaslangic: raporBaslangic,
            raporBitis: raporBitis,
            aciklama: Value(aciklama),
          ),
        );
  }
}
