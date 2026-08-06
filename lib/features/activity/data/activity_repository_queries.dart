part of 'activity_repository.dart';

extension ActivityRepositoryQueryOperations on ActivityRepository {
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

  Future<ActivityAssignmentPreview> previewActivityAssignments({
    required String tarih,
    required List<PersonnelAssignmentInput> personnelAssignments,
    required UserSessionState actor,
  }) async {
    await _requirePersonnelScope(actor, personnelAssignments);
    final reports = await _loadDomainReports();
    final existingAssignments = await _loadExistingAssignments();
    final personnelIds = personnelAssignments
        .map((assignment) => assignment.personnelId)
        .toSet();
    final personnel = personnelIds.isEmpty
        ? <PersonelTableData>[]
        : await (db.select(db.personelTable)
              ..where((table) => table.id.isIn(personnelIds)))
            .get();
    final personnelById = {for (final person in personnel) person.id: person};
    final squads = await db.select(db.timTable).get();
    final seen = <int>{};
    final items = <ActivityAssignmentPreviewItem>[];

    for (final assignment in personnelAssignments) {
      final duty = assignment.duty.trim();
      if (duty.isEmpty || !seen.add(assignment.personnelId)) continue;
      final person = personnelById[assignment.personnelId];
      if (person == null) continue;
      final evaluatedStatus = ConflictChecker.evaluateAssignmentStatus(
        personelId: person.id,
        targetDate: tarih,
        targetDuty: duty,
        reports: reports,
        existingAssignments: existingAssignments,
      );
      final hasConflict = evaluatedStatus == AssignmentStatus.beklemede;
      items.add(
        ActivityAssignmentPreviewItem(
          personnelId: person.id,
          name: person.adSoyad,
          rank: person.rutbe,
          squadId: person.timId,
          duty: duty,
          note: assignment.note,
          expectedStatus: hasConflict || !actor.isAdmin
              ? AssignmentStatus.beklemede
              : AssignmentStatus.onaylandi,
          hasConflict: hasConflict,
        ),
      );
    }

    return ActivityAssignmentPreview(
      items: items,
      squadNames: {for (final squad in squads) squad.id: squad.timAdi},
    );
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
      var unchangedCount = 0;
      var conflictSkippedCount = 0;
      final skippedPersonnelIds = <int>[];
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
          if (isSame) {
            unchangedCount++;
            continue;
          }
          if (!updateDifferentAssignments) {
            conflictSkippedCount++;
            skippedPersonnelIds.add(personId);
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
            conflictSkippedCount++;
            skippedPersonnelIds.add(personId);
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
          conflictSkippedCount++;
          skippedPersonnelIds.add(personId);
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
        skippedCount: unchangedCount + conflictSkippedCount,
        unchangedCount: unchangedCount,
        conflictSkippedCount: conflictSkippedCount,
        skippedPersonnelIds: skippedPersonnelIds,
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
      var alreadyAssignedCount = 0;

      for (final request in requests) {
        final existingActivity = await (db.select(db.gunlukFaaliyetTable)
              ..where((tbl) => tbl.tarih.equals(request.tarih)))
            .getSingleOrNull();

        if (existingActivity != null) {
          ids.add(existingActivity.id);
          final mergeResult = await mergeAssignmentsIntoActivity(
            activityId: existingActivity.id,
            personnelAssignments: request.personnelAssignments,
            updateDifferentAssignments: false,
            actor: actor,
          );
          addedCount += mergeResult.addedCount;
          alreadyAssignedCount += mergeResult.unchangedCount;
          skipped.addAll(
            mergeResult.skippedPersonnelIds.map(
              (personelId) => (
                personelId: personelId,
                date: request.tarih,
                activity: request.faaliyetAdi,
              ),
            ),
          );
        } else {
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
        alreadyAssignedCount: alreadyAssignedCount,
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
}
