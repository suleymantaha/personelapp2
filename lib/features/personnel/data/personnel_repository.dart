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
    required String kayitTarihi,
    int? timId,
  }) async {
    return db.transaction(() async {
      final newId = await db.into(db.personelTable).insert(
            PersonelTableCompanion.insert(
              adSoyad: adSoyad,
              rutbe: rutbe,
              birlik: birlik,
              timId: Value(timId),
              kayitTarihi: kayitTarihi,
            ),
          );

      if (timId != null) {
        await db.into(db.timUyelikGecmisiTable).insert(
              TimUyelikGecmisiTableCompanion.insert(
                personelId: newId,
                timId: Value(timId),
                tarih: kayitTarihi,
                islem: 'eklendi',
              ),
            );
      }

      return newId;
    });
  }

  Future<bool> updatePersonnel(PersonelTableData data, {String? tarih}) async {
    final oldData = await (db.select(db.personelTable)
          ..where((tbl) => tbl.id.equals(data.id)))
        .getSingleOrNull();

    final result = await db.update(db.personelTable).replace(data);

    if (oldData != null && oldData.timId != data.timId) {
      final islemStr = data.timId == null ? 'çıkarıldı' : 'eklendi';
      await db.into(db.timUyelikGecmisiTable).insert(
            TimUyelikGecmisiTableCompanion.insert(
              personelId: data.id,
              timId: Value(data.timId),
              tarih: tarih ?? DateTime.now().toIso8601String().split('T').first,
              islem: islemStr,
            ),
          );
    }

    return result;
  }

  Future<int> deletePersonnel(int id, {String? tarih}) async {
    return db.transaction(() async {
      final p = await (db.select(db.personelTable)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      if (p != null && p.timId != null) {
        await db.into(db.timUyelikGecmisiTable).insert(
              TimUyelikGecmisiTableCompanion.insert(
                personelId: id,
                timId: Value(p.timId),
                tarih: tarih ?? DateTime.now().toIso8601String().split('T').first,
                islem: 'çıkarıldı',
              ),
            );
      }

      return (db.delete(db.personelTable)..where((tbl) => tbl.id.equals(id)))
          .go();
    });
  }

  /// History Log Operations
  Stream<List<TimUyelikGecmisiTableData>> watchAllHistory() {
    return (db.select(db.timUyelikGecmisiTable)
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Squad operations
  Stream<List<TimTableData>> watchAllSquads() {
    return db.select(db.timTable).watch();
  }

  Future<int> addSquad({
    required String timAdi,
    required String olusturmaTarihi,
    int? timKomutaniId,
  }) {
    return db.into(db.timTable).insert(
          TimTableCompanion.insert(
            timAdi: timAdi,
            olusturmaTarihi: olusturmaTarihi,
            timKomutaniId: Value(timKomutaniId),
          ),
        );
  }

  Future<int> addSquadWithCommander({
    required String timAdi,
    required String olusturmaTarihi,
    required String komutanKullaniciAdi,
    required String komutanSifre,
  }) async {
    return db.transaction(() async {
      // 1. Create commander user account
      final userId = await db.into(db.kullaniciTable).insert(
            KullaniciTableCompanion.insert(
              kullaniciAdi: komutanKullaniciAdi,
              sifre: komutanSifre,
              rol: 'tim_komutani',
            ),
          );

      // 2. Create squad linked to commander user
      return db.into(db.timTable).insert(
            TimTableCompanion.insert(
              timAdi: timAdi,
              olusturmaTarihi: olusturmaTarihi,
              timKomutaniId: Value(userId),
            ),
          );
    });
  }

  /// List all Tim Komutanı accounts
  Stream<List<KullaniciTableData>> watchAllCommanders() {
    return (db.select(db.kullaniciTable)
          ..where((tbl) => tbl.rol.equals('tim_komutani')))
        .watch();
  }

  /// Reassign or revoke a Tim Komutanı's squad authority
  Future<void> assignCommanderToSquad({
    required int userId,
    required int? timId,
  }) async {
    await db.transaction(() async {
      // 1. Update user's timId
      await (db.update(db.kullaniciTable)..where((tbl) => tbl.id.equals(userId)))
          .write(KullaniciTableCompanion(timId: Value(timId)));

      // 2. If assigning to a squad, update timKomutaniId on timTable
      if (timId != null) {
        await (db.update(db.timTable)..where((tbl) => tbl.id.equals(timId)))
            .write(TimTableCompanion(timKomutaniId: Value(userId)));
      } else {
        // Clear squad commander link if revoked
        await (db.update(db.timTable)
              ..where((tbl) => tbl.timKomutaniId.equals(userId)))
            .write(const TimTableCompanion(timKomutaniId: Value(null)));
      }
    });
  }

  Future<int> deleteSquad(int id) {
    return (db.delete(db.timTable)..where((tbl) => tbl.id.equals(id))).go();
  }
}
