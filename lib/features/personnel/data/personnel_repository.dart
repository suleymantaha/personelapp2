import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

class PersonnelRepository {
  final AppDatabase db;

  PersonnelRepository(this.db);

  /// Return all personnel sorted by rank weight (seniority)
  Stream<List<PersonelTableData>> watchAllPersonnelSorted() {
    return db.select(db.personelTable).watch().map((list) {
      final sorted = List<PersonelTableData>.from(list);
      sorted.sort(
        (a, b) => getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe)),
      );
      return sorted;
    });
  }

  /// Return personnel belonging to a specific squad sorted by rank
  Stream<List<PersonelTableData>> watchPersonnelBySquad(int timId) {
    return (db.select(db.personelTable)..where((tbl) => tbl.timId.equals(timId)))
        .watch()
        .map((list) {
      final sorted = List<PersonelTableData>.from(list);
      sorted.sort(
        (a, b) => getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe)),
      );
      return sorted;
    });
  }

  Future<int> addPersonnel({
    required String adSoyad,
    required String rutbe,
    required String birlik,
    int? timId,
    required String kayitTarihi,
  }) {
    return db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: adSoyad,
            rutbe: rutbe,
            birlik: birlik,
            timId: Value(timId),
            kayitTarihi: kayitTarihi,
          ),
        );
  }

  Future<bool> updatePersonnel(PersonelTableData data) {
    return db.update(db.personelTable).replace(data);
  }

  Future<int> deletePersonnel(int id) {
    return (db.delete(db.personelTable)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// Squad operations
  Stream<List<TimTableData>> watchAllSquads() {
    return db.select(db.timTable).watch();
  }

  Future<int> addSquad({required String timAdi, required String olusturmaTarihi}) {
    return db.into(db.timTable).insert(
          TimTableCompanion.insert(
            timAdi: timAdi,
            olusturmaTarihi: olusturmaTarihi,
          ),
        );
  }

  Future<int> deleteSquad(int id) {
    return (db.delete(db.timTable)..where((tbl) => tbl.id.equals(id))).go();
  }
}
