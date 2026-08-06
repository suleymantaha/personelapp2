part of 'activity_repository.dart';

extension ActivityRepositoryConflictOperations on ActivityRepository {
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
}
