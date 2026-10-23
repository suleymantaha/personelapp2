import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';

class PersonnelOrderRepository {
  PersonnelOrderRepository(this.db);
  final AppDatabase db;

  /// Commit a complete screen draft atomically, rejecting stale memberships.
  Future<void> saveDisplayOrder(
      List<int> squadIds, Map<int?, List<int>> personnelByTeam,
      {required String username}) {
    final teams = List<int>.of(squadIds);
    final groups = {
      for (final entry in personnelByTeam.entries)
        entry.key: List<int>.of(entry.value)
    };
    return db.transaction(() async {
      await _requireAdmin(username);
      final squads = await db.select(db.timTable).get();
      final people = (await db.select(db.personelTable).get())
          .where((p) => p.aktif && !p.isDemo)
          .toList();
      _requireExactIds(teams, squads.map((t) => t.id));
      final expectedKeys = <int?>{
        null,
        ...teams,
        ...people.map((p) => p.timId)
      };
      if (groups.length != expectedKeys.length ||
          !expectedKeys.containsAll(groups.keys)) {
        throw ArgumentError('Tim listesi değişti. Yeniden açın.');
      }
      for (final entry in groups.entries) {
        _requireExactIds(entry.value,
            people.where((p) => p.timId == entry.key).map((p) => p.id));
      }
      for (var i = 0; i < teams.length; i++) {
        await (db.update(db.timTable)..where((t) => t.id.equals(teams[i])))
            .write(TimTableCompanion(sortOrder: Value(i)));
      }
      for (final ids in groups.values) {
        for (var i = 0; i < ids.length; i++) {
          await (db.update(db.personelTable)..where((p) => p.id.equals(ids[i])))
              .write(PersonelTableCompanion(sortOrder: Value(i)));
        }
      }
    });
  }

  Future<void> saveSquadOrder(List<int> ids, {required String username}) {
    final requested = List<int>.of(ids);
    return db.transaction(() async {
      await _requireAdmin(username);
      final squads = await db.select(db.timTable).get();
      _requireExactIds(requested, squads.map((s) => s.id));
      for (var index = 0; index < requested.length; index++) {
        await (db.update(db.timTable)
              ..where((t) => t.id.equals(requested[index])))
            .write(TimTableCompanion(sortOrder: Value(index)));
      }
    });
  }

  Future<void> savePersonnelOrder(int? timId, List<int> ids,
      {required String username}) {
    final requested = List<int>.of(ids);
    return db.transaction(() async {
      await _requireAdmin(username);
      if (timId != null) {
        final squad = await (db.select(db.timTable)
              ..where((t) => t.id.equals(timId)))
            .getSingleOrNull();
        if (squad == null) throw ArgumentError('Tim bulunamadı.');
      }
      final people = await (db.select(db.personelTable)
            ..where((p) =>
                p.aktif.equals(true) &
                p.isDemo.equals(false) &
                (timId == null ? p.timId.isNull() : p.timId.equals(timId))))
          .get();
      _requireExactIds(requested, people.map((p) => p.id));
      for (var index = 0; index < requested.length; index++) {
        await (db.update(db.personelTable)
              ..where((p) => p.id.equals(requested[index])))
            .write(PersonelTableCompanion(sortOrder: Value(index)));
      }
    });
  }

  Future<void> _requireAdmin(String username) async {
    final user = await (db.select(db.kullaniciTable)
          ..where((u) => u.kullaniciAdi.equals(username)))
        .getSingleOrNull();
    if (user?.rol != 'yönetici') {
      throw StateError('Sıralamayı yalnızca yönetici değiştirebilir.');
    }
  }

  void _requireExactIds(List<int> requested, Iterable<int> current) {
    final expected = current.toSet();
    if (requested.length != expected.length ||
        requested.toSet().length != requested.length ||
        !expected.containsAll(requested)) {
      throw ArgumentError(
          'Liste değişti. Listeyi yeniden açıp sıralamayı tekrar kaydedin.');
    }
  }
}
