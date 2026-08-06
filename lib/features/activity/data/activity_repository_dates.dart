part of 'activity_repository.dart';

extension ActivityRepositoryDateOperations on ActivityRepository {
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
}
