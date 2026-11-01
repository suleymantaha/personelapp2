part of 'activity_repository.dart';

extension ActivityRepositoryCopyOperations on ActivityRepository {
  /// Copies the source selection as new assignments using target-date rules.
  /// Existing personnel in a matching destination card are never overwritten.
  Future<ActivityAssignmentBatchResult> copyActivityToDate({
    required int activityId,
    required String newDate,
    required UserSessionState actor,
    String? expectedDate,
    List<FaaliyetPersonelAtamaTableData>? expectedAssignments,
    List<PersonnelAssignmentInput> teamConfirmations = const [],
  }) async {
    _requireAdmin(actor);
    if (!_isValidIsoDate(newDate)) {
      throw ArgumentError.value(newDate, 'newDate', 'Invalid activity date');
    }
    return db.transaction(() async {
      await requireOutputAuthority(actor);
      final source = await (db.select(db.gunlukFaaliyetTable)
            ..where((t) => t.id.equals(activityId)))
          .getSingleOrNull();
      if (source == null) {
        throw ArgumentError.value(
            activityId, 'activityId', 'Activity not found');
      }
      if (expectedDate != null && expectedDate != source.tarih) {
        throw StateError('Faaliyet tarihi değişti; kaydı yenileyin.');
      }
      if (source.tarih == newDate) {
        throw ArgumentError.value(
            newDate, 'newDate', 'Choose a different date');
      }
      final assignments = await _copySourceAssignments(
          activityId, expectedAssignments, teamConfirmations);
      await _requirePersonnelScope(actor, assignments);
      return _copyAssignmentsToDate(source, newDate, assignments, actor);
    });
  }

  Future<List<PersonnelAssignmentInput>> _copySourceAssignments(
    int activityId,
    List<FaaliyetPersonelAtamaTableData>? expectedAssignments,
    List<PersonnelAssignmentInput> confirmations,
  ) async {
    final rows = await (db.select(db.faaliyetPersonelAtamaTable)
          ..where((t) => t.faaliyetId.equals(activityId)))
        .get();
    if (expectedAssignments != null) {
      final expected = {for (final row in expectedAssignments) row.id: row};
      if (rows.length != expectedAssignments.length ||
          rows.any((row) => expected[row.id] != row)) {
        throw StateError('Atama listesi değişti; kaydı yenileyin.');
      }
    }
    final choices = {for (final item in confirmations) item.personnelId: item};
    final personnelIds = rows.map((row) => row.personelId).toSet();
    if (choices.length != confirmations.length ||
        choices.keys.any((id) => !personnelIds.contains(id))) {
      throw StateError('Atama listesi değişti; kaydı yenileyin.');
    }
    return [
      for (final row in rows)
        PersonnelAssignmentInput(
          personnelId: row.personelId,
          duty: row.gorevVeyaIzin,
          note: row.aciklama,
          teamId: choices[row.personelId]?.teamId,
          isOutsideTeam: choices[row.personelId]?.isOutsideTeam ?? false,
        ),
    ];
  }

  Future<ActivityAssignmentBatchResult> _copyAssignmentsToDate(
    GunlukFaaliyetTableData source,
    String date,
    List<PersonnelAssignmentInput> assignments,
    UserSessionState actor,
  ) async {
    final candidates = await (db.select(db.gunlukFaaliyetTable)
          ..where((t) => t.tarih.equals(date)))
        .get();
    final matching = candidates.where((row) =>
        _normalizeActivityName(row.faaliyetAdi) ==
        _normalizeActivityName(source.faaliyetAdi));
    final existing = matching.isEmpty ? null : matching.first;
    final destinationId = existing?.id ??
        await createActivityWithAssignments(
          faaliyetAdi: source.faaliyetAdi,
          tarih: date,
          olusturanKullanici: actor.username,
          personnelAssignments: const [],
          actor: actor,
        );
    final result = await addAssignmentsToActivity(
      activityId: destinationId,
      expectedDate: date,
      assignments: assignments,
      actor: actor,
    );
    if (existing == null && result.addedCount == 0) {
      await (db.delete(db.gunlukFaaliyetTable)
            ..where((t) => t.id.equals(destinationId)))
          .go();
    }
    return result;
  }
}
