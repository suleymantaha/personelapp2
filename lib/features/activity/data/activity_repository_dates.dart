part of 'activity_repository.dart';

extension ActivityRepositoryDateOperations on ActivityRepository {
  Future<ActivityDateChangePreview> previewActivityDateChange({
    required int activityId,
    required String newDate,
    required UserSessionState actor,
  }) async {
    _requireAdmin(actor);
    final activity = await (db.select(db.gunlukFaaliyetTable)
          ..where((tbl) => tbl.id.equals(activityId)))
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

    final assignments = await (db.select(db.faaliyetPersonelAtamaTable)
          ..where((tbl) => tbl.faaliyetId.equals(activityId)))
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
      teamConfirmationPersonnelIds:
          await _dateChangeConfirmationIds(assignments, newDate, actor),
      assignmentSnapshot: List.unmodifiable(assignments),
    );
  }

  Future<ActivityDateChangeResult> changeActivityDate({
    required int activityId,
    required String newDate,
    required UserSessionState actor,
    String? expectedDate,
    List<FaaliyetPersonelAtamaTableData>? expectedAssignments,
    List<PersonnelAssignmentInput> teamConfirmations = const [],
  }) {
    _requireAdmin(actor);
    return db.transaction(() async {
      await requireOutputAuthority(actor);
      final preview = await previewActivityDateChange(
        activityId: activityId,
        newDate: newDate,
        actor: actor,
      );
      if (expectedDate != null && preview.oldDate != expectedDate) {
        throw StateError('Faaliyet tarihi değişti; kaydı yenileyin.');
      }
      if (preview.status != ActivityDateChangeStatus.success) {
        return ActivityDateChangeResult(
          status: preview.status,
          oldDate: preview.oldDate,
          newDate: preview.newDate,
          assignmentCount: preview.assignmentCount,
          pendingAssignmentCount: preview.pendingAssignmentCount,
          teamConfirmationPersonnelIds: preview.teamConfirmationPersonnelIds,
        );
      }

      final activity = await (db.select(db.gunlukFaaliyetTable)
            ..where((tbl) => tbl.id.equals(activityId)))
          .getSingle();
      final assignments = await (db.select(db.faaliyetPersonelAtamaTable)
            ..where((tbl) => tbl.faaliyetId.equals(activityId)))
          .get();
      if (expectedAssignments != null) {
        final expected = {for (final row in expectedAssignments) row.id: row};
        if (assignments.length != expected.length ||
            assignments.any((row) => expected[row.id] != row)) {
          throw StateError('Atama listesi değişti; kaydı yenileyin.');
        }
      }
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
            'Assignment conflict: personnel has an existing record on $newDate. Activity date was not changed.',
            code: 'date_change_conflict',
            date: newDate,
            personnelId: assignment.personelId,
          );
        }
      }

      final automaticTitle = 'Günlük Faaliyet (${activity.tarih})';
      final teamUpdates = await _dateChangeTeamUpdates(
          assignments: assignments,
          date: newDate,
          actor: actor,
          confirmations: teamConfirmations,
          requiredIds: preview.teamConfirmationPersonnelIds);
      final newTitle = activity.faaliyetAdi == automaticTitle
          ? 'Günlük Faaliyet ($newDate)'
          : activity.faaliyetAdi;
      for (final entry in teamUpdates.entries) {
        await (db.update(db.faaliyetPersonelAtamaTable)
              ..where((a) => a.id.equals(entry.key)))
            .write(FaaliyetPersonelAtamaTableCompanion(
                gorevTimId: Value(entry.value.teamId),
                gorevTimAdi: Value(entry.value.teamName)));
      }
      await (db.update(db.gunlukFaaliyetTable)
            ..where((tbl) => tbl.id.equals(activityId)))
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
