part of 'activity_repository.dart';

/// A transactionally refreshed, explicitly selected report boundary.
class ActivityOutputSnapshot {
  const ActivityOutputSnapshot(
      {required this.activities,
      required this.assignments,
      required this.personnelMap});
  final List<GunlukFaaliyetTableData> activities;
  final List<FaaliyetPersonelAtamaTableData> assignments;
  final Map<int, PersonelTableData> personnelMap;

  /// Report sources having at least one assignment eligible in this snapshot.
  List<GunlukFaaliyetTableData> get operationalActivities {
    final ids = assignments.map((a) => a.faaliyetId).toSet();
    return activities.where((a) => ids.contains(a.id)).toList();
  }
}

extension ActivityOutputQueries on ActivityRepository {
  /// Recheck persisted account role and current commander ownership.
  /// Call within the transaction that reads or mutates protected output data.
  Future<int?> requireOutputAuthority(UserSessionState actor) async {
    final account = await (db.select(db.kullaniciTable)
          ..where((u) => u.kullaniciAdi.equals(actor.username)))
        .getSingleOrNull();
    if (account == null || account.rol != actor.role.storageValue) {
      throw const AuthorizationException('Oturum yetkisi artık geçerli değil.');
    }
    if (actor.isAdmin) return null;
    final teamId = account.timId;
    final team = teamId == null
        ? null
        : await (db.select(db.timTable)..where((t) => t.id.equals(teamId)))
            .getSingleOrNull();
    if (teamId == null ||
        teamId != actor.timId ||
        team?.timKomutaniId != account.id) {
      throw const AuthorizationException(
          'Tim komutanı yetkisi artık geçerli değil.');
    }
    return teamId;
  }

  Future<ActivityOutputSnapshot> loadOutputSnapshot({
    required UserSessionState actor,
    required List<GunlukFaaliyetTableData> sources,
    required Iterable<int> selectedAssignmentIds,
    int? selectedSquadId,
  }) =>
      db.transaction(() async {
        final teamId = await requireOutputAuthority(actor);
        final sourceById = {for (final source in sources) source.id: source};
        final activities = await (db.select(db.gunlukFaaliyetTable)
              ..where((t) => t.id.isIn(sourceById.keys)))
            .get();
        if (activities.length != sourceById.length ||
            activities.any((a) {
              final old = sourceById[a.id]!;
              return a.tarih != old.tarih || a.faaliyetAdi != old.faaliyetAdi;
            })) {
          throw StateError('Faaliyet değişti. Çıktı seçimini yeniden açın.');
        }
        final ids = selectedAssignmentIds.toSet();
        final selected = await (db.select(db.faaliyetPersonelAtamaTable)
              ..where((t) => t.id.isIn(ids)))
            .get();
        if (selected.length != ids.length ||
            selected.any((a) => !sourceById.containsKey(a.faaliyetId))) {
          throw StateError(
              'Seçilen atamalar değişti. Çıktı seçimini yeniden açın.');
        }
        final assignments = selected
            .where((a) =>
                (actor.isAdmin || a.gorevTimId == teamId) &&
                (selectedSquadId == null || a.gorevTimId == selectedSquadId) &&
                DutyOrLeaveType.isApprovedOperationalDuty(
                    a.gorevVeyaIzin, a.durum))
            .toList();
        final people = await (db.select(db.personelTable)
              ..where((t) => t.id.isIn(assignments.map((a) => a.personelId))))
            .get();
        final pMap = {for (final p in people) p.id: p};
        if (assignments.any((a) => !pMap.containsKey(a.personelId))) {
          throw StateError('Seçilen personel artık bulunamıyor.');
        }
        final freshById = {for (final a in activities) a.id: a};
        return ActivityOutputSnapshot(
            activities: sourceById.keys.map((id) => freshById[id]!).toList(),
            assignments: assignments,
            personnelMap: pMap);
      });
}
