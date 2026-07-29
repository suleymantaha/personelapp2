import 'dart:async';
import 'package:drift/drift.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';
import 'package:personelapp2/features/activity/domain/models/activity_create_request.dart';

export 'package:personelapp2/features/activity/domain/models/activity_create_request.dart';

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

class ActivityBatchCreateResult {
  const ActivityBatchCreateResult({
    required this.activityIds,
    required this.addedAssignmentCount,
    required this.skippedAssignmentCount,
    this.conflictDescriptions = const [],
  });

  final List<int> activityIds;
  final int addedAssignmentCount;
  final int skippedAssignmentCount;
  final List<String> conflictDescriptions;
}

class AssignmentConflictException implements Exception {
  const AssignmentConflictException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ActivityRepository {
  ActivityRepository(this.db);

  final AppDatabase db;

  void _requireAdmin(UserSessionState actor) {
    if (!actor.isAdmin) {
      throw const AuthorizationException(
        'Bu işlem yalnızca yöneticiler tarafından yapılabilir.',
      );
    }
  }

  Future<void> _requirePersonnelScope(
    UserSessionState actor,
    List<PersonnelAssignmentInput> assignments,
  ) async {
    final personnelIds = assignments.map((item) => item.personnelId).toSet();
    if (personnelIds.isEmpty) return;

    final personnel = await (db.select(
      db.personelTable,
    )..where((table) => table.id.isIn(personnelIds)))
        .get();
    if (personnel.length != personnelIds.length) {
      throw const AuthorizationException(
        'Atama listesindeki personelden biri bulunamadı.',
      );
    }
    if (actor.isAdmin) return;

    final teamId = actor.timId;
    if (teamId == null || personnel.any((person) => person.timId != teamId)) {
      throw const AuthorizationException(
        'Tim komutanı yalnızca kendi timindeki personele atama yapabilir.',
      );
    }
  }

  String _normalizeActivityName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

  String _normalizeNote(String? value) {
    final note = value?.trim() ?? '';
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

      for (final assignment in assignments) {
        final status = ConflictChecker.evaluateAssignmentStatus(
          personelId: assignment.personelId,
          targetDate: newDate,
          targetDuty: assignment.gorevVeyaIzin,
          reports: reports,
          existingAssignments: existingAssignments,
          excludeActivityId: activityId,
        );
        if (status == AssignmentStatus.beklemede) {
          throw AssignmentConflictException(
            '$newDate tarihinde personelin başka bir kaydı bulunuyor. '
            'Faaliyet tarihi değiştirilmedi.',
          );
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
        pendingAssignmentCount: 0,
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
    required List<PersonnelAssignmentInput> personnelAssignments,
    required UserSessionState actor,
  }) {
    return db.transaction(() async {
      await _requirePersonnelScope(actor, personnelAssignments);
      return _createActivityWithinTransaction(
        ActivityCreateRequest(
          faaliyetAdi: faaliyetAdi,
          tarih: tarih,
          olusturanKullanici: olusturanKullanici,
          personnelAssignments: personnelAssignments,
        ),
        requiresApproval: !actor.isAdmin,
      );
    });
  }

  Future<List<ExistingActivityMatch>> findMatchingActivities({
    required String faaliyetAdi,
    required String tarih,
    required List<PersonnelAssignmentInput> personnelAssignments,
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
    if (matches.isEmpty) return const [];
    final assignments = await (db.select(
      db.faaliyetPersonelAtamaTable,
    )..where((table) => table.faaliyetId.isIn(matches.map((item) => item.id))))
        .get();
    final assignmentsByActivity = <int, List<FaaliyetPersonelAtamaTableData>>{};
    for (final assignment in assignments) {
      assignmentsByActivity
          .putIfAbsent(assignment.faaliyetId, () => [])
          .add(assignment);
    }
    final result = <ExistingActivityMatch>[];
    for (final activity in matches) {
      final existing = assignmentsByActivity[activity.id] ??
          const <FaaliyetPersonelAtamaTableData>[];
      final byPersonnel = {
        for (final assignment in existing) assignment.personelId: assignment,
      };
      var newCount = 0;
      var unchangedCount = 0;
      var differentCount = 0;
      final seen = <int>{};
      for (final item in personnelAssignments) {
        final personId = item.personnelId;
        if (!seen.add(personId)) continue;
        final current = byPersonnel[personId];
        if (current == null) {
          newCount++;
        } else if (current.gorevVeyaIzin.trim() == item.duty.trim() &&
            _normalizeNote(current.aciklama) == _normalizeNote(item.note)) {
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
    required List<PersonnelAssignmentInput> personnelAssignments,
    required bool updateDifferentAssignments,
    required UserSessionState actor,
  }) {
    return db.transaction(() async {
      await _requirePersonnelScope(actor, personnelAssignments);
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
        final personId = item.personnelId;
        final duty = item.duty.trim();
        if (duty.isEmpty || !seen.add(personId)) continue;
        final note = _normalizeNote(item.note);
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
          if (status == AssignmentStatus.beklemede) {
            skippedCount++;
            continue;
          }
          if (!actor.isAdmin) status = AssignmentStatus.beklemede;
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
        if (status == AssignmentStatus.beklemede) {
          skippedCount++;
          continue;
        }
        if (!actor.isAdmin) status = AssignmentStatus.beklemede;
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

  Future<ActivityBatchCreateResult> createActivitiesWithAssignments(
    List<ActivityCreateRequest> requests, {
    required UserSessionState actor,
  }) {
    return db.transaction(() async {
      if (!actor.isAdmin) {
        throw const AuthorizationException(
          'Toplu faaliyet içe aktarma yalnızca yöneticilere açıktır.',
        );
      }
      final ids = <int>[];
      final skipped = <({int personelId, String date, String activity})>[];
      var addedCount = 0;
      for (final request in requests) {
        final activitySkipped = <int>[];
        final id = await _createActivityWithinTransaction(
          request,
          requiresApproval: false,
          skippedPersonnelIds: activitySkipped,
        );
        ids.add(id);
        final inserted = await (db.select(
          db.faaliyetPersonelAtamaTable,
        )..where((table) => table.faaliyetId.equals(id)))
            .get();
        addedCount += inserted.length;
        skipped.addAll(
          activitySkipped.map(
            (personelId) => (
              personelId: personelId,
              date: request.tarih,
              activity: request.faaliyetAdi,
            ),
          ),
        );
      }
      final personnelIds = skipped.map((item) => item.personelId).toSet();
      final personnel = personnelIds.isEmpty
          ? const <PersonelTableData>[]
          : await (db.select(
              db.personelTable,
            )..where((table) => table.id.isIn(personnelIds)))
              .get();
      final names = {for (final person in personnel) person.id: person.adSoyad};
      return ActivityBatchCreateResult(
        activityIds: ids,
        addedAssignmentCount: addedCount,
        skippedAssignmentCount: skipped.length,
        conflictDescriptions: [
          for (final item in skipped)
            '${names[item.personelId] ?? 'Personel #${item.personelId}'}: '
                '${item.date} tarihinde mevcut kaydı nedeniyle '
                '${item.activity} faaliyetine eklenmedi.',
        ],
      );
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

  Future<Map<int, String>> getDailyReservationDescriptions(
    String targetDate,
  ) async {
    final result = <int, String>{};
    final rows = await db.select(db.faaliyetPersonelAtamaTable).join([
      innerJoin(
        db.gunlukFaaliyetTable,
        db.gunlukFaaliyetTable.id.equalsExp(
          db.faaliyetPersonelAtamaTable.faaliyetId,
        ),
      ),
    ]).get();
    for (final row in rows) {
      final assignment = row.readTable(db.faaliyetPersonelAtamaTable);
      final activity = row.readTable(db.gunlukFaaliyetTable);
      if (assignment.durum == AssignmentStatus.reddedildi ||
          !DutyCoverage.coveredDates(
            startDate: activity.tarih,
            duty: assignment.gorevVeyaIzin,
          ).contains(targetDate)) {
        continue;
      }
      result.putIfAbsent(
        assignment.personelId,
        () => '${activity.faaliyetAdi} • ${assignment.gorevVeyaIzin}',
      );
    }
    final reports = await db.select(db.raporKayitTable).get();
    for (final report in reports) {
      if (targetDate.compareTo(report.raporBaslangic) >= 0 &&
          targetDate.compareTo(report.raporBitis) <= 0) {
        result.putIfAbsent(
          report.personelId,
          () => 'Rapor • ${report.raporBaslangic} - ${report.raporBitis}',
        );
      }
    }
    return result;
  }

  Future<List<String>> auditExistingDailyConflicts() async {
    final personnel = await db.select(db.personelTable).get();
    final names = {for (final person in personnel) person.id: person.adSoyad};
    final entriesByPersonAndDate = <String, List<String>>{};
    final rows = await db.select(db.faaliyetPersonelAtamaTable).join([
      innerJoin(
        db.gunlukFaaliyetTable,
        db.gunlukFaaliyetTable.id.equalsExp(
          db.faaliyetPersonelAtamaTable.faaliyetId,
        ),
      ),
    ]).get();
    for (final row in rows) {
      final assignment = row.readTable(db.faaliyetPersonelAtamaTable);
      final activity = row.readTable(db.gunlukFaaliyetTable);
      if (assignment.durum == AssignmentStatus.reddedildi) continue;
      for (final date in DutyCoverage.coveredDates(
        startDate: activity.tarih,
        duty: assignment.gorevVeyaIzin,
      )) {
        entriesByPersonAndDate
            .putIfAbsent('${assignment.personelId}|$date', () => [])
            .add('${activity.faaliyetAdi} • ${assignment.gorevVeyaIzin}');
      }
    }
    final reports = await db.select(db.raporKayitTable).get();
    for (final report in reports) {
      var day = DateTime.parse(report.raporBaslangic);
      final last = DateTime.parse(report.raporBitis);
      while (!day.isAfter(last)) {
        final date = '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}';
        entriesByPersonAndDate
            .putIfAbsent('${report.personelId}|$date', () => [])
            .add('Rapor');
        day = day.add(const Duration(days: 1));
      }
    }
    final conflicts = <String>[];
    for (final entry in entriesByPersonAndDate.entries) {
      if (entry.value.length < 2) continue;
      final parts = entry.key.split('|');
      final personId = int.parse(parts.first);
      conflicts.add(
        '${names[personId] ?? 'Personel #$personId'} • ${parts.last}: '
        '${entry.value.join(' | ')}',
      );
    }
    conflicts.sort();
    return conflicts;
  }

  Future<int> _createActivityWithinTransaction(
    ActivityCreateRequest request, {
    required bool requiresApproval,
    List<int>? skippedPersonnelIds,
  }) async {
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
      final personnelId = item.personnelId;
      final duty = item.duty.trim();
      if (duty.isEmpty || !seenPersonnel.add(personnelId)) {
        continue;
      }

      var status = ConflictChecker.evaluateAssignmentStatus(
        personelId: personnelId,
        targetDate: request.tarih,
        targetDuty: duty,
        reports: reports,
        existingAssignments: existingAssignments,
      );
      if (status == AssignmentStatus.beklemede) {
        skippedPersonnelIds?.add(personnelId);
        continue;
      }
      if (requiresApproval) status = AssignmentStatus.beklemede;

      final assignmentId = await db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activityId,
              personelId: personnelId,
              gorevVeyaIzin: duty,
              durum: status,
              aciklama: Value(item.note),
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

  Future<ApprovalResult> approveAssignment(
    int assignmentId, {
    required UserSessionState actor,
  }) {
    _requireAdmin(actor);
    return db
        .transaction(() => _approveAssignmentWithinTransaction(assignmentId));
  }

  Future<ApprovalResult> approveAllAssignmentsForActivity(
    int activityId, {
    required UserSessionState actor,
  }) {
    _requireAdmin(actor);
    return db.transaction(() async {
      final pending = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where(
              (tbl) =>
                  tbl.faaliyetId.equals(activityId) &
                  tbl.durum.equals(AssignmentStatus.beklemede),
            ))
          .get();
      if (pending.isEmpty) {
        return const ApprovalResult(approvedCount: 0, blockedCount: 0);
      }
      final activity = await (db.select(
        db.gunlukFaaliyetTable,
      )..where((table) => table.id.equals(activityId)))
          .getSingle();
      final existingAssignments = await _loadExistingAssignments();
      final reports = await _loadDomainReports();
      var approvedCount = 0;
      var blockedCount = 0;
      final descriptions = <String>[];
      for (final assignment in pending) {
        final result = await _approveAssignmentWithContext(
          assignment: assignment,
          activity: activity,
          existingAssignments: existingAssignments,
          reports: reports,
        );
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
    return _approveAssignmentWithContext(
      assignment: assignment,
      activity: activity,
      existingAssignments: existingAssignments,
      reports: reports,
    );
  }

  Future<ApprovalResult> _approveAssignmentWithContext({
    required FaaliyetPersonelAtamaTableData assignment,
    required GunlukFaaliyetTableData activity,
    required List<ExistingDutyAssignment> existingAssignments,
    required List<PersonnelReport> reports,
  }) async {
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
    )..where((tbl) => tbl.id.equals(assignment.id)))
        .write(
      const FaaliyetPersonelAtamaTableCompanion(
        durum: Value(AssignmentStatus.onaylandi),
      ),
    );
    final index = existingAssignments.indexWhere(
      (existing) => existing.id == assignment.id,
    );
    if (index >= 0) {
      final existing = existingAssignments[index];
      existingAssignments[index] = ExistingDutyAssignment(
        id: existing.id,
        faaliyetId: existing.faaliyetId,
        personelId: existing.personelId,
        tarih: existing.tarih,
        gorevVeyaIzin: existing.gorevVeyaIzin,
        durum: AssignmentStatus.onaylandi,
      );
    }
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
  Future<int> rejectAllAssignmentsForActivity(
    int activityId, {
    required UserSessionState actor,
  }) async {
    _requireAdmin(actor);
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
    String newStatus, {
    required UserSessionState actor,
  }) async {
    _requireAdmin(actor);
    if (newStatus == AssignmentStatus.onaylandi) {
      final result = await approveAssignment(assignmentId, actor: actor);
      return result.approvedCount;
    }
    return (db.update(db.faaliyetPersonelAtamaTable)
          ..where((tbl) => tbl.id.equals(assignmentId)))
        .write(FaaliyetPersonelAtamaTableCompanion(durum: Value(newStatus)));
  }

  /// Delete a single personnel assignment from an activity
  Future<int> deleteAssignment(
    int assignmentId, {
    required UserSessionState actor,
  }) {
    _requireAdmin(actor);
    return (db.delete(
      db.faaliyetPersonelAtamaTable,
    )..where((tbl) => tbl.id.equals(assignmentId)))
        .go();
  }

  /// Delete multiple personnel assignments from the same activity.
  Future<int> deleteAssignments(
    Iterable<int> assignmentIds, {
    required UserSessionState actor,
  }) {
    _requireAdmin(actor);
    final ids = assignmentIds.toSet();
    if (ids.isEmpty) return Future.value(0);
    return db.transaction(() async {
      var deleted = 0;
      for (final id in ids) {
        deleted += await (db.delete(
          db.faaliyetPersonelAtamaTable,
        )..where((tbl) => tbl.id.equals(id)))
            .go();
      }
      return deleted;
    });
  }

  /// Update assignment duty type, note, and status
  Future<int> updateAssignmentDetails({
    required int assignmentId,
    required String gorevVeyaIzin,
    required String newStatus,
    String? aciklama,
    required UserSessionState actor,
  }) {
    _requireAdmin(actor);
    return db.transaction(() async {
      final assignment = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((table) => table.id.equals(assignmentId)))
          .getSingle();
      final activity = await (db.select(
        db.gunlukFaaliyetTable,
      )..where((table) => table.id.equals(assignment.faaliyetId)))
          .getSingle();
      if (newStatus != AssignmentStatus.reddedildi) {
        final status = ConflictChecker.evaluateAssignmentStatus(
          personelId: assignment.personelId,
          targetDate: activity.tarih,
          targetDuty: gorevVeyaIzin,
          reports: await _loadDomainReports(),
          existingAssignments: await _loadExistingAssignments(),
          excludeAssignmentId: assignmentId,
        );
        if (status == AssignmentStatus.beklemede) {
          throw AssignmentConflictException(
            '${activity.tarih} tarihinde personelin başka bir kaydı bulunuyor.',
          );
        }
      }
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
    });
  }

  /// Add a single personnel assignment to an existing activity
  Future<int> addSingleAssignment({
    required int faaliyetId,
    required int personelId,
    required String gorevVeyaIzin,
    required String tarih,
    String? aciklama,
    required UserSessionState actor,
  }) async {
    return db.transaction(() async {
      await _requirePersonnelScope(
        actor,
        [
          PersonnelAssignmentInput(
            personnelId: personelId,
            duty: gorevVeyaIzin,
            note: aciklama,
          ),
        ],
      );
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
      if (status == AssignmentStatus.beklemede) {
        throw AssignmentConflictException(
          '$tarih tarihinde personelin başka bir görevi veya kaydı bulunuyor.',
        );
      }
      if (!actor.isAdmin) status = AssignmentStatus.beklemede;

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
    return db.transaction(() async {
      final reports = await _loadDomainReports();
      final assignments = await _loadExistingAssignments();
      var day = DateTime.parse(raporBaslangic);
      final lastDay = DateTime.parse(raporBitis);
      while (!day.isAfter(lastDay)) {
        final date = '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}';
        final status = ConflictChecker.evaluateAssignmentStatus(
          personelId: personelId,
          targetDate: date,
          targetDuty: DutyOrLeaveType.raporlu,
          reports: reports,
          existingAssignments: assignments,
        );
        if (status == AssignmentStatus.beklemede) {
          throw AssignmentConflictException(
            '$date tarihinde personelin başka bir görevi, izni veya raporu '
            'bulunuyor. Rapor kaydedilmedi.',
          );
        }
        day = day.add(const Duration(days: 1));
      }
      return db.into(db.raporKayitTable).insert(
            RaporKayitTableCompanion.insert(
              personelId: personelId,
              raporBaslangic: raporBaslangic,
              raporBitis: raporBitis,
              aciklama: Value(aciklama),
            ),
          );
    });
  }
}
