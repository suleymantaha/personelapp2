part of 'activity_repository.dart';

extension ActivityRepositoryAssignmentOperations on ActivityRepository {
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

  /// Adds multiple personnel to one existing activity in a single
  /// transaction. Existing members and conflicting assignments are reported
  /// separately instead of aborting the whole import.
  Future<ActivityAssignmentBatchResult> addAssignmentsToActivity({
    required int activityId,
    required List<PersonnelAssignmentInput> assignments,
    required UserSessionState actor,
  }) {
    return db.transaction(() async {
      await _requirePersonnelScope(actor, assignments);
      final activity = await (db.select(db.gunlukFaaliyetTable)
            ..where((table) => table.id.equals(activityId)))
          .getSingleOrNull();
      if (activity == null) {
        throw ArgumentError.value(
            activityId, 'activityId', 'Faaliyet bulunamadı');
      }

      final existingInActivity = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((table) => table.faaliyetId.equals(activityId)))
          .get();
      final existingPersonnelIds =
          existingInActivity.map((row) => row.personelId).toSet();
      final reports = await _loadDomainReports();
      final existingAssignments = await _loadExistingAssignments();
      final seenPersonnelIds = <int>{};
      final conflictDescriptions = <String>[];
      var addedCount = 0;
      var alreadyAssignedCount = 0;
      var conflictSkippedCount = 0;

      for (final assignment in assignments) {
        if (!seenPersonnelIds.add(assignment.personnelId) ||
            existingPersonnelIds.contains(assignment.personnelId)) {
          alreadyAssignedCount++;
          continue;
        }
        final duty = assignment.duty.trim();
        if (duty.isEmpty) continue;

        var status = ConflictChecker.evaluateAssignmentStatus(
          personelId: assignment.personnelId,
          targetDate: activity.tarih,
          targetDuty: duty,
          reports: reports,
          existingAssignments: existingAssignments,
        );
        if (status == AssignmentStatus.beklemede) {
          conflictSkippedCount++;
          conflictDescriptions.add(
            'Personel #${assignment.personnelId}: '
            '${activity.tarih} tarihinde başka bir kayıt bulunuyor.',
          );
          continue;
        }
        if (!actor.isAdmin) status = AssignmentStatus.beklemede;

        final id = await db.into(db.faaliyetPersonelAtamaTable).insert(
              FaaliyetPersonelAtamaTableCompanion.insert(
                faaliyetId: activityId,
                personelId: assignment.personnelId,
                gorevVeyaIzin: duty,
                durum: status,
                aciklama: Value(assignment.note?.trim()),
              ),
            );
        existingAssignments.add(
          ExistingDutyAssignment(
            id: id,
            faaliyetId: activityId,
            personelId: assignment.personnelId,
            tarih: activity.tarih,
            gorevVeyaIzin: duty,
            durum: status,
          ),
        );
        existingPersonnelIds.add(assignment.personnelId);
        addedCount++;
      }

      return ActivityAssignmentBatchResult(
        addedCount: addedCount,
        alreadyAssignedCount: alreadyAssignedCount,
        conflictSkippedCount: conflictSkippedCount,
        conflictDescriptions: conflictDescriptions,
      );
    });
  }

  /// Transfer all assignments belonging to a squad (timId) from one activity
  /// to another within the same day in a single atomic transaction.
  ///
  /// For each personnel in [squadId]:
  ///   1. Remove their assignment from [sourceActivityId].
  ///   2. Re-evaluate conflict status against the [targetActivityId]'s date.
  ///   3. Insert into [targetActivityId] with the new status.
  ///
  /// Returns a [SquadTransferResult] containing counts and any skipped personnel.
}
