import 'dart:async';
import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';

enum ActivityDateChangeStatus {
  success,
  unchanged,
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

class ActivityCreateRequest {
  const ActivityCreateRequest({
    required this.faaliyetAdi,
    required this.tarih,
    required this.olusturanKullanici,
    required this.personnelAssignments,
    this.isCommander = false,
  });

  final String faaliyetAdi;
  final String tarih;
  final String olusturanKullanici;
  final List<Map<String, dynamic>> personnelAssignments;
  final bool isCommander;
}

class ApprovalResult {
  const ApprovalResult({
    required this.approvedCount,
    required this.blockedCount,
    this.conflictDescriptions = const [],
  });

  final int approvedCount;
  final int blockedCount;
  final List<String> conflictDescriptions;

  bool get isFullyApproved => blockedCount == 0;
}

class ExistingActivityMatch {
  const ExistingActivityMatch({
    required this.activity,
    required this.newPersonnelCount,
    required this.unchangedPersonnelCount,
    required this.differentPersonnelCount,
  });

  final GunlukFaaliyetTableData activity;
  final int newPersonnelCount;
  final int unchangedPersonnelCount;
  final int differentPersonnelCount;
}

class ActivityMergeResult {
  const ActivityMergeResult({
    required this.activityId,
    required this.addedCount,
    required this.updatedCount,
    required this.skippedCount,
  });

  final int activityId;
  final int addedCount;
  final int updatedCount;
  final int skippedCount;
}

class ActivityRepository {
  ActivityRepository(this.db);

  final AppDatabase db;

  String _normalizeActivityName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

  String _normalizeNote(Object? value) {
    final note = value?.toString().trim() ?? '';
    return note.replaceAll(RegExp(r'\s+'), ' ');
  }

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
      final reports = await _loadDomainReports();
      final existingAssignments = await _loadExistingAssignments();

      var pendingCount = 0;
      for (final assignment in assignments) {
        if (assignment.durum != AssignmentStatus.onaylandi) continue;
        final status = ConflictChecker.evaluateAssignmentStatus(
          personelId: assignment.personelId,
          targetDate: newDate,
          targetDuty: assignment.gorevVeyaIzin,
          reports: reports,
          existingAssignments: existingAssignments,
          excludeActivityId: activityId,
        );
        if (status == AssignmentStatus.beklemede) {
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
    final reports = await _loadDomainReports();
    final existingAssignments = await _loadExistingAssignments();

    return assignments.where((assignment) {
      if (assignment.durum != AssignmentStatus.onaylandi) return false;
      final status = ConflictChecker.evaluateAssignmentStatus(
        personelId: assignment.personelId,
        targetDate: newDate,
        targetDuty: assignment.gorevVeyaIzin,
        reports: reports,
        existingAssignments: existingAssignments,
        excludeActivityId: movingActivityId,
      );
      return status == AssignmentStatus.beklemede;
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

  @Deprecated(
    'Aynı tarihte birden fazla faaliyet desteklenir. '
    'Tarih bazlı birleştirme veri kaybına yol açar.',
  )
  Future<void> consolidateDuplicateActivities() async {
    // Intentionally left as a safe no-op for legacy callers.
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
  }) {
    return db.transaction(
      () => _createActivityWithinTransaction(
        ActivityCreateRequest(
          faaliyetAdi: faaliyetAdi,
          tarih: tarih,
          olusturanKullanici: olusturanKullanici,
          personnelAssignments: personnelAssignments,
          isCommander: isCommander,
        ),
      ),
    );
  }

  Future<List<ExistingActivityMatch>> findMatchingActivities({
    required String faaliyetAdi,
    required String tarih,
    required List<Map<String, dynamic>> personnelAssignments,
  }) async {
    final activities = await (db.select(
      db.gunlukFaaliyetTable,
    )..where((table) => table.tarih.equals(tarih)))
        .get();
    final normalizedName = _normalizeActivityName(faaliyetAdi);
    final matches = activities
        .where(
          (activity) =>
              _normalizeActivityName(activity.faaliyetAdi) == normalizedName,
        )
        .toList();
    final result = <ExistingActivityMatch>[];
    for (final activity in matches) {
      final existing = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((table) => table.faaliyetId.equals(activity.id)))
          .get();
      final byPersonnel = {
        for (final assignment in existing) assignment.personelId: assignment,
      };
      var newCount = 0;
      var unchangedCount = 0;
      var differentCount = 0;
      final seen = <int>{};
      for (final item in personnelAssignments) {
        final personId = int.tryParse(item['personelId'].toString());
        if (personId == null || !seen.add(personId)) continue;
        final current = byPersonnel[personId];
        if (current == null) {
          newCount++;
        } else if (current.gorevVeyaIzin.trim() ==
                item['gorevVeyaIzin'].toString().trim() &&
            _normalizeNote(current.aciklama) ==
                _normalizeNote(item['aciklama'])) {
          unchangedCount++;
        } else {
          differentCount++;
        }
      }
      result.add(
        ExistingActivityMatch(
          activity: activity,
          newPersonnelCount: newCount,
          unchangedPersonnelCount: unchangedCount,
          differentPersonnelCount: differentCount,
        ),
      );
    }
    result.sort((a, b) => b.activity.id.compareTo(a.activity.id));
    return result;
  }

  Future<ActivityMergeResult> mergeAssignmentsIntoActivity({
    required int activityId,
    required List<Map<String, dynamic>> personnelAssignments,
    required bool updateDifferentAssignments,
    bool isCommander = false,
  }) {
    return db.transaction(() async {
      final activity = await (db.select(
        db.gunlukFaaliyetTable,
      )..where((table) => table.id.equals(activityId)))
          .getSingle();
      final existingRows = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((table) => table.faaliyetId.equals(activityId)))
          .get();
      final byPersonnel = {
        for (final assignment in existingRows)
          assignment.personelId: assignment,
      };
      final reports = await _loadDomainReports();
      final allAssignments = await _loadExistingAssignments();
      var addedCount = 0;
      var updatedCount = 0;
      var skippedCount = 0;
      final seen = <int>{};

      for (final item in personnelAssignments) {
        final personId = int.tryParse(item['personelId'].toString());
        final duty = item['gorevVeyaIzin']?.toString().trim() ?? '';
        if (personId == null || duty.isEmpty || !seen.add(personId)) continue;
        final note = _normalizeNote(item['aciklama']);
        final current = byPersonnel[personId];
        if (current != null) {
          final isSame = current.gorevVeyaIzin.trim() == duty &&
              _normalizeNote(current.aciklama) == note;
          if (isSame || !updateDifferentAssignments) {
            skippedCount++;
            continue;
          }
          var status = ConflictChecker.evaluateAssignmentStatus(
            personelId: personId,
            targetDate: activity.tarih,
            targetDuty: duty,
            reports: reports,
            existingAssignments: allAssignments,
            excludeAssignmentId: current.id,
          );
          if (isCommander) status = AssignmentStatus.beklemede;
          await (db.update(
            db.faaliyetPersonelAtamaTable,
          )..where((table) => table.id.equals(current.id)))
              .write(
            FaaliyetPersonelAtamaTableCompanion(
              gorevVeyaIzin: Value(duty),
              aciklama: Value(note.isEmpty ? null : note),
              durum: Value(status),
            ),
          );
          updatedCount++;
          continue;
        }

        var status = ConflictChecker.evaluateAssignmentStatus(
          personelId: personId,
          targetDate: activity.tarih,
          targetDuty: duty,
          reports: reports,
          existingAssignments: allAssignments,
        );
        if (isCommander) status = AssignmentStatus.beklemede;
        final assignmentId =
            await db.into(db.faaliyetPersonelAtamaTable).insert(
                  FaaliyetPersonelAtamaTableCompanion.insert(
                    faaliyetId: activityId,
                    personelId: personId,
                    gorevVeyaIzin: duty,
                    durum: status,
                    aciklama: Value(note.isEmpty ? null : note),
                  ),
                );
        allAssignments.add(
          ExistingDutyAssignment(
            id: assignmentId,
            faaliyetId: activityId,
            personelId: personId,
            tarih: activity.tarih,
            gorevVeyaIzin: duty,
            durum: status,
          ),
        );
        addedCount++;
      }
      return ActivityMergeResult(
        activityId: activityId,
        addedCount: addedCount,
        updatedCount: updatedCount,
        skippedCount: skippedCount,
      );
    });
  }

  Future<List<int>> createActivitiesWithAssignments(
    List<ActivityCreateRequest> requests,
  ) {
    return db.transaction(() async {
      final ids = <int>[];
      for (final request in requests) {
        ids.add(await _createActivityWithinTransaction(request));
      }
      return ids;
    });
  }

  Future<List<PersonnelReport>> _loadDomainReports() async {
    final reports = await db.select(db.raporKayitTable).get();
    return reports
        .map(
          (report) => PersonnelReport(
            id: report.id,
            personelId: report.personelId,
            raporBaslangic: report.raporBaslangic,
            raporBitis: report.raporBitis,
            aciklama: report.aciklama,
          ),
        )
        .toList();
  }

  Future<List<ExistingDutyAssignment>> _loadExistingAssignments() async {
    final rows = await db.select(db.faaliyetPersonelAtamaTable).join([
      innerJoin(
        db.gunlukFaaliyetTable,
        db.gunlukFaaliyetTable.id.equalsExp(
          db.faaliyetPersonelAtamaTable.faaliyetId,
        ),
      ),
    ]).get();
    return rows.map((row) {
      final assignment = row.readTable(db.faaliyetPersonelAtamaTable);
      final activity = row.readTable(db.gunlukFaaliyetTable);
      return ExistingDutyAssignment(
        id: assignment.id,
        faaliyetId: assignment.faaliyetId,
        personelId: assignment.personelId,
        tarih: activity.tarih,
        gorevVeyaIzin: assignment.gorevVeyaIzin,
        durum: assignment.durum,
      );
    }).toList();
  }

  Future<int> _createActivityWithinTransaction(
    ActivityCreateRequest request,
  ) async {
    final activityId = await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: request.faaliyetAdi,
            tarih: request.tarih,
            olusturanKullanici: request.olusturanKullanici,
            olusturmaTarihi: DateTime.now().toIso8601String(),
          ),
        );
    final reports = await _loadDomainReports();
    final existingAssignments = await _loadExistingAssignments();
    final seenPersonnel = <int>{};

    for (final item in request.personnelAssignments) {
      final rawPersonnelId = item['personelId'];
      final rawDuty = item['gorevVeyaIzin'];
      if (rawPersonnelId == null || rawDuty == null) continue;
      final personnelId = rawPersonnelId is int
          ? rawPersonnelId
          : int.tryParse(rawPersonnelId.toString());
      final duty = rawDuty.toString().trim();
      if (personnelId == null ||
          duty.isEmpty ||
          !seenPersonnel.add(personnelId)) {
        continue;
      }

      var status = ConflictChecker.evaluateAssignmentStatus(
        personelId: personnelId,
        targetDate: request.tarih,
        targetDuty: duty,
        reports: reports,
        existingAssignments: existingAssignments,
      );
      if (request.isCommander) status = AssignmentStatus.beklemede;

      final assignmentId = await db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activityId,
              personelId: personnelId,
              gorevVeyaIzin: duty,
              durum: status,
              aciklama: Value(item['aciklama'] as String?),
            ),
          );
      existingAssignments.add(
        ExistingDutyAssignment(
          id: assignmentId,
          faaliyetId: activityId,
          personelId: personnelId,
          tarih: request.tarih,
          gorevVeyaIzin: duty,
          durum: status,
        ),
      );
    }
    return activityId;
  }

  Future<ApprovalResult> approveAssignment(int assignmentId) {
    return db
        .transaction(() => _approveAssignmentWithinTransaction(assignmentId));
  }

  Future<ApprovalResult> approveAllAssignmentsForActivity(
    int activityId,
  ) {
    return db.transaction(() async {
      final pending = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where(
              (tbl) =>
                  tbl.faaliyetId.equals(activityId) &
                  tbl.durum.equals(AssignmentStatus.beklemede),
            ))
          .get();
      var approvedCount = 0;
      var blockedCount = 0;
      final descriptions = <String>[];
      for (final assignment in pending) {
        final result = await _approveAssignmentWithinTransaction(assignment.id);
        approvedCount += result.approvedCount;
        blockedCount += result.blockedCount;
        descriptions.addAll(result.conflictDescriptions);
      }
      return ApprovalResult(
        approvedCount: approvedCount,
        blockedCount: blockedCount,
        conflictDescriptions: descriptions,
      );
    });
  }

  Future<ApprovalResult> _approveAssignmentWithinTransaction(
    int assignmentId,
  ) async {
    final assignment = await (db.select(
      db.faaliyetPersonelAtamaTable,
    )..where((tbl) => tbl.id.equals(assignmentId)))
        .getSingleOrNull();
    if (assignment == null) {
      return const ApprovalResult(approvedCount: 0, blockedCount: 1);
    }
    final activity = await (db.select(
      db.gunlukFaaliyetTable,
    )..where((tbl) => tbl.id.equals(assignment.faaliyetId)))
        .getSingle();
    final existingAssignments = await _loadExistingAssignments();
    final reports = await _loadDomainReports();
    final status = ConflictChecker.evaluateAssignmentStatus(
      personelId: assignment.personelId,
      targetDate: activity.tarih,
      targetDuty: assignment.gorevVeyaIzin,
      reports: reports,
      existingAssignments: existingAssignments,
      excludeAssignmentId: assignment.id,
    );
    if (status != AssignmentStatus.onaylandi) {
      final descriptions = await _findConflictDescriptions(
        assignment: assignment,
        activity: activity,
      );
      return ApprovalResult(
        approvedCount: 0,
        blockedCount: 1,
        conflictDescriptions: descriptions,
      );
    }
    await (db.update(
      db.faaliyetPersonelAtamaTable,
    )..where((tbl) => tbl.id.equals(assignmentId)))
        .write(
      const FaaliyetPersonelAtamaTableCompanion(
        durum: Value(AssignmentStatus.onaylandi),
      ),
    );
    return const ApprovalResult(approvedCount: 1, blockedCount: 0);
  }

  Future<List<String>> _findConflictDescriptions({
    required FaaliyetPersonelAtamaTableData assignment,
    required GunlukFaaliyetTableData activity,
  }) async {
    if (!DutyOrLeaveType.isOperationalDuty(assignment.gorevVeyaIzin)) {
      return const [];
    }
    final rows = await db.select(db.faaliyetPersonelAtamaTable).join([
      innerJoin(
        db.gunlukFaaliyetTable,
        db.gunlukFaaliyetTable.id.equalsExp(
          db.faaliyetPersonelAtamaTable.faaliyetId,
        ),
      ),
    ]).get();
    final descriptions = <String>[];
    for (final row in rows) {
      final other = row.readTable(db.faaliyetPersonelAtamaTable);
      final otherActivity = row.readTable(db.gunlukFaaliyetTable);
      if (other.id == assignment.id ||
          other.personelId != assignment.personelId ||
          other.durum != AssignmentStatus.onaylandi ||
          !DutyOrLeaveType.isOperationalDuty(other.gorevVeyaIzin)) {
        continue;
      }
      if (DutyCoverage.overlaps(
        firstDate: otherActivity.tarih,
        firstDuty: other.gorevVeyaIzin,
        secondDate: activity.tarih,
        secondDuty: assignment.gorevVeyaIzin,
      )) {
        descriptions.add(
          '${otherActivity.tarih} • ${otherActivity.faaliyetAdi} • '
          '${other.gorevVeyaIzin}',
        );
      }
    }
    return descriptions;
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
  Future<int> updateAssignmentStatus(
    int assignmentId,
    String newStatus,
  ) async {
    if (newStatus == AssignmentStatus.onaylandi) {
      final result = await approveAssignment(assignmentId);
      return result.approvedCount;
    }
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
    return db.transaction(() async {
      final duplicate = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where(
              (tbl) =>
                  tbl.faaliyetId.equals(faaliyetId) &
                  tbl.personelId.equals(personelId),
            ))
          .getSingleOrNull();
      if (duplicate != null) return duplicate.id;

      final reports = await _loadDomainReports();
      final existingAssignments = await _loadExistingAssignments();
      var status = ConflictChecker.evaluateAssignmentStatus(
        personelId: personelId,
        targetDate: tarih,
        targetDuty: gorevVeyaIzin,
        reports: reports,
        existingAssignments: existingAssignments,
      );
      if (isCommander) status = AssignmentStatus.beklemede;

      return db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: faaliyetId,
              personelId: personelId,
              gorevVeyaIzin: gorevVeyaIzin,
              durum: status,
              aciklama: Value(aciklama),
            ),
          );
    });
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
