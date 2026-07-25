import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/utils/password_hasher.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

class PersonnelRepository {
  PersonnelRepository(this.db);

  final AppDatabase db;

  /// Return all personnel sorted by rank weight (seniority)
  Stream<List<PersonelTableData>> watchAllPersonnelSorted() {
    return db.select(db.personelTable).watch().map((list) {
      return List<PersonelTableData>.from(list)
        ..sort(
          (a, b) => getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe)),
        );
    });
  }

  /// Return personnel belonging to a specific squad sorted by rank
  Stream<List<PersonelTableData>> watchPersonnelBySquad(int timId) {
    return (db.select(db.personelTable)..where((tbl) => tbl.timId.equals(timId)))
        .watch()
        .map((list) {
      return List<PersonelTableData>.from(list)
        ..sort(
          (a, b) => getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe)),
        );
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

  Future<void> ensureDefaultSquads() async {
    final existingSquads = await db.select(db.timTable).get();
    final existingNames = existingSquads.map((s) => s.timAdi.trim()).toSet();

    final defaultSquads = [
      'K.H',
      "1'inci Bl. K.H",
      '1-B Timi',
      '2-B Timi',
      '3-B Timi',
      '4-B Timi',
      "2'nci Bl. K.H",
      '5-B Timi',
      '6-B Timi',
      '7-B Timi',
      '8-B Timi',
      "3'üncü Bl. K.H",
      '9-B Timi',
      '10-B Timi',
      '11-B Timi',
      '12-B Timi',
    ];
    final nowStr = DateTime.now().toIso8601String();
    for (final name in defaultSquads) {
      if (!existingNames.contains(name)) {
        await db.into(db.timTable).insert(
              TimTableCompanion.insert(
                timAdi: name,
                olusturmaTarihi: nowStr,
              ),
            );
      }
    }
  }

  /// Squad operations
  Stream<List<TimTableData>> watchAllSquads() async* {
    await ensureDefaultSquads();
    yield* db.select(db.timTable).watch();
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
  }) async {
    return db.transaction(() async {
      // 1. Create commander user account with pending password setup
      final userId = await db.into(db.kullaniciTable).insert(
            KullaniciTableCompanion.insert(
              kullaniciAdi: komutanKullaniciAdi,
              sifre: const Value(''),
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

  /// Create a new user account with pending password
  Future<int> createUserAccount({
    required String kullaniciAdi,
    required String rol,
    int? timId,
  }) {
    return db.into(db.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
            kullaniciAdi: kullaniciAdi,
            sifre: const Value(''),
            rol: rol,
            timId: Value(timId),
          ),
        );
  }

  /// Update password for a specific user
  Future<int> updateUserPassword({
    required String kullaniciAdi,
    required String newPassword,
  }) {
    final hashedPassword = PasswordHasher.hashPassword(newPassword);
    return (db.update(db.kullaniciTable)
          ..where((tbl) => tbl.kullaniciAdi.equals(kullaniciAdi)))
        .write(KullaniciTableCompanion(sifre: Value(hashedPassword)));
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

  /// Assign a personnel as commander of a squad by creating/updating user account
  Future<void> assignPersonnelAsCommander({
    required String kullaniciAdi,
    required int timId,
    required int personnelId,
  }) async {
    await db.transaction(() async {
      // 1. Assign personnel to squad
      await (db.update(db.personelTable)
            ..where((tbl) => tbl.id.equals(personnelId)))
          .write(PersonelTableCompanion(timId: Value(timId)));

      // 2. Check if user already exists
      final existingUser = await (db.select(db.kullaniciTable)
            ..where((tbl) => tbl.kullaniciAdi.equals(kullaniciAdi)))
          .getSingleOrNull();

      int userId;
      if (existingUser != null) {
        userId = existingUser.id;
        await (db.update(db.kullaniciTable)
              ..where((tbl) => tbl.id.equals(userId)))
            .write(KullaniciTableCompanion(
          rol: const Value('tim_komutani'),
          timId: Value(timId),
        ));
      } else {
        userId = await db.into(db.kullaniciTable).insert(
              KullaniciTableCompanion.insert(
                kullaniciAdi: kullaniciAdi,
                sifre: const Value(''),
                rol: 'tim_komutani',
                timId: Value(timId),
              ),
            );
      }

      // 3. Update squad commander ID
      await (db.update(db.timTable)..where((tbl) => tbl.id.equals(timId)))
          .write(TimTableCompanion(timKomutaniId: Value(userId)));
    });
  }

  /// Seed test personnel (e.g. 10 per squad) for trial/testing purposes
  Future<int> seedTestPersonnelPerSquad({int countPerSquad = 10}) async {
    final squads = await db.select(db.timTable).get();
    if (squads.isEmpty) return 0;

    final firstNames = [
      'Ahmet', 'Mehmet', 'Mustafa', 'Ali', 'Hüseyin', 'Hasan',
      'İbrahim', 'İsmail', 'Osman', 'Murat', 'Ömer', 'Yusuf',
      'Emre', 'Burak', 'Hakan', 'Serkan', 'Fatih', 'Gökhan',
      'Yasin', 'Bilal', 'Kaan', 'Oguz', 'Eren', 'Tolga',
    ];

    final lastNames = [
      'YILMAZ', 'KAYA', 'DEMİR', 'ÇELİK', 'ŞAHİN', 'YILDIZ',
      'YILDIRIM', 'ÖZTÜRK', 'AYDIN', 'ÖZDEMİR', 'ARSLAN', 'DOĞAN',
      'KILIÇ', 'ASLAN', 'ÇETİN', 'KOÇ', 'KURT', 'ÖZKAN', 'ŞEN',
    ];

    final ranks = [
      'J.Asb.Kd.Bçvş.',
      'J.Asb.Bçvş.',
      'J.Asb.Kd.Üçvş.',
      'J.Asb.Üçvş.',
      'J.Asb.Kd.Çvş.',
      'Uzm.J.VII.Kad.Kıd.Çvş.',
      'J.Uzm.Çvş.',
      'J.Uzm.Onb.',
    ];

    final today = DateTime.now().toIso8601String().split('T').first;
    var insertedCount = 0;

    await db.transaction(() async {
      var nameIdx = 0;
      for (final squad in squads) {
        final toInsert = <PersonelTableCompanion>[];
        for (var i = 1; i <= countPerSquad; i++) {
          final fName = firstNames[nameIdx % firstNames.length];
          final lName = lastNames[(nameIdx * 3) % lastNames.length];
          final rank = ranks[i % ranks.length];
          nameIdx++;

          toInsert.add(
            PersonelTableCompanion.insert(
              adSoyad: '$fName $lName',
              rutbe: rank,
              birlik: '${squad.timAdi} Birliği',
              timId: Value(squad.id),
              kayitTarihi: today,
            ),
          );
        }
        await db.batch((b) => b.insertAll(db.personelTable, toInsert));
        insertedCount += toInsert.length;
      }
    });

    return insertedCount;
  }

  /// Delete all personnel records from database
  Future<int> deleteAllPersonnel() async {
    return db.transaction(() async {
      await db.delete(db.timUyelikGecmisiTable).go();
      return db.delete(db.personelTable).go();
    });
  }
}


