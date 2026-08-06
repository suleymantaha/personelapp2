part of 'activity_repository.dart';

extension ActivityRepositoryTransferOperations on ActivityRepository {
  Future<SquadTransferResult> transferSquadBetweenActivities({
    required int sourceActivityId,
    required int targetActivityId,
    required int squadId,
    required UserSessionState actor,
  }) {
    _requireAdmin(actor);
    return db.transaction(() async {
      // Load both activities
      final sourceActivity = await (db.select(db.gunlukFaaliyetTable)
            ..where((tbl) => tbl.id.equals(sourceActivityId)))
          .getSingleOrNull();
      if (sourceActivity == null) {
        throw ArgumentError('Kaynak faaliyet bulunamadı: $sourceActivityId');
      }
      final targetActivity = await (db.select(db.gunlukFaaliyetTable)
            ..where((tbl) => tbl.id.equals(targetActivityId)))
          .getSingleOrNull();
      if (targetActivity == null) {
        throw ArgumentError('Hedef faaliyet bulunamadı: $targetActivityId');
      }

      // Find source assignments that belong to the given squad
      final allSourceAssignments = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((tbl) => tbl.faaliyetId.equals(sourceActivityId)))
          .get();

      // Filter by squadId via personnelTable
      final squadPersonnel = await (db.select(db.personelTable)
            ..where((tbl) => tbl.timId.equals(squadId)))
          .get();
      final squadPersonnelIds = squadPersonnel.map((p) => p.id).toSet();

      final toTransfer = allSourceAssignments
          .where((a) => squadPersonnelIds.contains(a.personelId))
          .toList();

      if (toTransfer.isEmpty) {
        return const SquadTransferResult(
          movedCount: 0,
          skippedCount: 0,
          skippedPersonnelIds: [],
        );
      }

      // Load conflict data after removal will take place
      // We pass excludeActivityId=sourceActivityId so those assignments won't
      // block themselves in the conflict check.
      final reports = await _loadDomainReports();
      final existingAssignments = await _loadExistingAssignments();

      var movedCount = 0;
      var skippedCount = 0;
      final skippedPersonnelIds = <int>[];

      for (final assignment in toTransfer) {
        // Check if the personnel already has an assignment in the target activity
        final alreadyInTarget = await (db.select(
          db.faaliyetPersonelAtamaTable,
        )..where(
                (tbl) =>
                    tbl.faaliyetId.equals(targetActivityId) &
                    tbl.personelId.equals(assignment.personelId),
              ))
            .getSingleOrNull();
        if (alreadyInTarget != null) {
          // Personnel already assigned to target; skip to avoid duplicate
          skippedPersonnelIds.add(assignment.personelId);
          skippedCount++;
          continue;
        }

        // Evaluate conflict status for the target activity date,
        // excluding the current source assignment so it doesn't block itself
        final status = ConflictChecker.evaluateAssignmentStatus(
          personelId: assignment.personelId,
          targetDate: targetActivity.tarih,
          targetDuty: assignment.gorevVeyaIzin,
          reports: reports,
          existingAssignments: existingAssignments,
          excludeAssignmentId: assignment.id,
        );

        // Delete from source
        await (db.delete(db.faaliyetPersonelAtamaTable)
              ..where((tbl) => tbl.id.equals(assignment.id)))
            .go();

        // Insert into target
        await db.into(db.faaliyetPersonelAtamaTable).insert(
              FaaliyetPersonelAtamaTableCompanion.insert(
                faaliyetId: targetActivityId,
                personelId: assignment.personelId,
                gorevVeyaIzin: assignment.gorevVeyaIzin,
                durum: status,
                aciklama: Value(assignment.aciklama),
              ),
            );
        movedCount++;
      }

      return SquadTransferResult(
        movedCount: movedCount,
        skippedCount: skippedCount,
        skippedPersonnelIds: skippedPersonnelIds,
      );
    });
  }

  /// Creates a new activity on the source activity's date and transfers the
  /// selected squad into it as one atomic operation.
  Future<SquadTransferResult> createActivityAndTransferSquad({
    required int sourceActivityId,
    required int squadId,
    required String activityName,
    required UserSessionState actor,
  }) {
    _requireAdmin(actor);
    final trimmedName = activityName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(activityName, 'activityName', 'Boş olamaz.');
    }
    return db.transaction(() async {
      final source = await (db.select(db.gunlukFaaliyetTable)
            ..where((table) => table.id.equals(sourceActivityId)))
          .getSingleOrNull();
      if (source == null) {
        throw ArgumentError('Kaynak faaliyet bulunamadı: $sourceActivityId');
      }
      final targetId = await _createActivityWithinTransaction(
        ActivityCreateRequest(
          faaliyetAdi: trimmedName,
          tarih: source.tarih,
          olusturanKullanici: actor.username,
          personnelAssignments: const [],
        ),
        requiresApproval: false,
      );
      final result = await transferSquadBetweenActivities(
        sourceActivityId: sourceActivityId,
        targetActivityId: targetId,
        squadId: squadId,
        actor: actor,
      );
      if (result.movedCount == 0) {
        await (db.delete(db.gunlukFaaliyetTable)
              ..where((table) => table.id.equals(targetId)))
            .go();
      }
      return result;
    });
  }

  /// Tek bir personel atamasını (assignmentId) kaynak faaliyet kartından
  /// [targetActivityId] numaralı karta atomik olarak taşır.
  ///
  /// İşlem adımları (tek transaction):
  ///   1. [assignmentId]'yi doğrula — yoksa [ArgumentError].
  ///   2. [targetActivityId]'yi doğrula — yoksa [ArgumentError].
  ///   3. Hedefte aynı personel varsa [PersonnelTransferResult(moved: false)] döner.
  ///   4. Çakışma kontrolü (ConflictChecker) — kaynak atamanın ID'si hariç tutulur.
  ///   5. Kaynak atamayı siler, hedef karta yeni durum ile ekler.
  Future<PersonnelTransferResult> transferPersonnelBetweenActivities({
    required int assignmentId,
    required int targetActivityId,
    required UserSessionState actor,
  }) {
    _requireAdmin(actor);
    return db.transaction(() async {
      // 1. Kaynak atamayı yükle
      final assignment = await (db.select(db.faaliyetPersonelAtamaTable)
            ..where((tbl) => tbl.id.equals(assignmentId)))
          .getSingleOrNull();
      if (assignment == null) {
        throw ArgumentError('Atama bulunamadı: $assignmentId');
      }

      // 2. Hedef faaliyeti yükle
      final target = await (db.select(db.gunlukFaaliyetTable)
            ..where((tbl) => tbl.id.equals(targetActivityId)))
          .getSingleOrNull();
      if (target == null) {
        throw ArgumentError('Hedef faaliyet bulunamadı: $targetActivityId');
      }

      // 3. Hedefte zaten var mı?
      final alreadyInTarget = await (db.select(db.faaliyetPersonelAtamaTable)
            ..where(
              (tbl) =>
                  tbl.faaliyetId.equals(targetActivityId) &
                  tbl.personelId.equals(assignment.personelId),
            ))
          .getSingleOrNull();
      if (alreadyInTarget != null) {
        return const PersonnelTransferResult(
          moved: false,
          reason: 'Bu personel zaten hedef faaliyette mevcut.',
        );
      }

      // 4. Çakışma kontrolü (kaynak atama ID'si dışlanır → kendini bloklamamak için)
      final reports = await _loadDomainReports();
      final existingAssignments = await _loadExistingAssignments();
      final status = ConflictChecker.evaluateAssignmentStatus(
        personelId: assignment.personelId,
        targetDate: target.tarih,
        targetDuty: assignment.gorevVeyaIzin,
        reports: reports,
        existingAssignments: existingAssignments,
        excludeAssignmentId: assignment.id,
      );

      // 5. Sil & ekle
      await (db.delete(db.faaliyetPersonelAtamaTable)
            ..where((tbl) => tbl.id.equals(assignment.id)))
          .go();

      await db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: targetActivityId,
              personelId: assignment.personelId,
              gorevVeyaIzin: assignment.gorevVeyaIzin,
              durum: status,
              aciklama: Value(assignment.aciklama),
            ),
          );

      return const PersonnelTransferResult(moved: true);
    });
  }

  /// Creates a new activity on the source assignment's date and transfers the
  /// selected personnel into it as one atomic operation.
  Future<PersonnelTransferResult> createActivityAndTransferPersonnel({
    required int assignmentId,
    required String activityName,
    required UserSessionState actor,
  }) {
    _requireAdmin(actor);
    final trimmedName = activityName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(activityName, 'activityName', 'Boş olamaz.');
    }
    return db.transaction(() async {
      final assignment = await (db.select(db.faaliyetPersonelAtamaTable)
            ..where((table) => table.id.equals(assignmentId)))
          .getSingleOrNull();
      if (assignment == null) {
        throw ArgumentError('Atama bulunamadı: $assignmentId');
      }
      final source = await (db.select(db.gunlukFaaliyetTable)
            ..where((table) => table.id.equals(assignment.faaliyetId)))
          .getSingleOrNull();
      if (source == null) {
        throw ArgumentError(
            'Kaynak faaliyet bulunamadı: ${assignment.faaliyetId}');
      }
      final targetId = await _createActivityWithinTransaction(
        ActivityCreateRequest(
          faaliyetAdi: trimmedName,
          tarih: source.tarih,
          olusturanKullanici: actor.username,
          personnelAssignments: const [],
        ),
        requiresApproval: false,
      );
      return transferPersonnelBetweenActivities(
        assignmentId: assignmentId,
        targetActivityId: targetId,
        actor: actor,
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
