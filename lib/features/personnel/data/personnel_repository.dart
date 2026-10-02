import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/password_hasher.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/personnel/domain/personnel_import_models.dart';

export 'package:personelapp2/features/personnel/domain/personnel_import_models.dart';

class PersonnelRepository {
  PersonnelRepository(this.db);

  final AppDatabase db;

  /// Return all personnel sorted by rank weight (seniority)
  Stream<List<PersonelTableData>> watchAllPersonnelSorted({
    bool includeInactive = false,
    bool includeDemo = false,
  }) {
    final query = db.select(db.personelTable);
    if (!includeInactive) query.where((p) => p.aktif.equals(true));
    if (!includeDemo) query.where((p) => p.isDemo.equals(false));
    return query.watch().map((list) {
      return List<PersonelTableData>.from(list)..sort(
        (a, b) => getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe)),
      );
    });
  }

  /// Return personnel belonging to a specific squad sorted by rank
  Stream<List<PersonelTableData>> watchPersonnelBySquad(int timId) {
    return (db.select(db.personelTable)..where(
      (tbl) =>
          tbl.timId.equals(timId) &
          tbl.aktif.equals(true) &
          tbl.isDemo.equals(false),
    )).watch().map((list) {
      return List<PersonelTableData>.from(list)..sort(
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
    String? telefon,
  }) async {
    return db.transaction(() async {
      final newId = await db
          .into(db.personelTable)
          .insert(
            PersonelTableCompanion.insert(
              adSoyad: adSoyad,
              rutbe: rutbe,
              birlik: birlik,
              timId: Value(timId),
              telefon: Value(telefon),
              kayitTarihi: kayitTarihi,
            ),
          );

      if (timId != null) {
        await db
            .into(db.timUyelikGecmisiTable)
            .insert(
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

  Future<PersonnelImportResult> importPersonnelBatch(
    List<PersonnelImportEntry> entries, {
    required String kayitTarihi,
  }) async {
    return db.transaction(() async {
      final existing = await db.select(db.personelTable).get();
      final knownKeys =
          existing
              .map(
                (person) => personnelImportKey(
                  name: person.adSoyad,
                  rank: person.rutbe,
                  unit: person.birlik,
                  teamId: person.timId,
                ),
              )
              .toSet();
      var addedCount = 0;
      var skippedCount = 0;
      var updatedCount = 0;

      for (final entry in entries) {
        final name = entry.adSoyad.trim();
        final rank = normalizeRank(entry.rutbe.trim());
        final key = personnelImportKey(
          name: name,
          rank: rank,
          unit: entry.birlik,
          teamId: entry.timId,
        );
        if (name.isEmpty || entry.skip) {
          skippedCount++;
          continue;
        }
        if (entry.existingPersonnelId != null) {
          final current =
              await (db.select(db.personelTable)..where(
                (p) => p.id.equals(entry.existingPersonnelId!),
              )).getSingleOrNull();
          if (current == null) {
            throw ArgumentError('Güncellenecek personel bulunamadı.');
          }
          await updatePersonnel(
            current.copyWith(
              adSoyad: name,
              rutbe: rank.isEmpty ? 'J.Er' : rank,
              birlik:
                  entry.birlik.trim().isEmpty
                      ? 'Asayiş Timi'
                      : entry.birlik.trim(),
              timId: Value(entry.timId),
            ),
            tarih: kayitTarihi,
          );
          existing.removeWhere((p) => p.id == current.id);
          existing.add(
            (await (db.select(db.personelTable)
              ..where((p) => p.id.equals(current.id))).getSingle()),
          );
          knownKeys
            ..clear()
            ..addAll(
              existing.map(
                (p) => personnelImportKey(
                  name: p.adSoyad,
                  rank: p.rutbe,
                  unit: p.birlik,
                  teamId: p.timId,
                ),
              ),
            );
          updatedCount++;
          continue;
        }
        if (!entry.allowDuplicate &&
            !knownKeys.contains(key) &&
            existing.any(
              (p) =>
                  BulkImportLearningService.normalizeName(p.adSoyad) ==
                      BulkImportLearningService.normalizeName(name) &&
                  p.timId == entry.timId &&
                  (entry.timId != null ||
                      p.birlik.trim() == entry.birlik.trim()),
            )) {
          throw ArgumentError(
            'Aynı adlı personel var. Mevcut kişiyi güncelleyin veya ayrı kişi oluşturmayı seçin.',
          );
        }
        if (!entry.allowDuplicate && knownKeys.contains(key)) {
          skippedCount++;
          continue;
        }

        final newId = await db
            .into(db.personelTable)
            .insert(
              PersonelTableCompanion.insert(
                adSoyad: name,
                rutbe: rank.isEmpty ? 'J.Er' : rank,
                birlik:
                    entry.birlik.trim().isEmpty
                        ? 'Asayiş Timi'
                        : entry.birlik.trim(),
                timId: Value(entry.timId),
                kayitTarihi: kayitTarihi,
              ),
            );
        if (entry.timId != null) {
          await db
              .into(db.timUyelikGecmisiTable)
              .insert(
                TimUyelikGecmisiTableCompanion.insert(
                  personelId: newId,
                  timId: Value(entry.timId),
                  tarih: kayitTarihi,
                  islem: 'eklendi',
                ),
              );
        }
        knownKeys.add(key);
        existing.add(
          await (db.select(db.personelTable)
            ..where((p) => p.id.equals(newId))).getSingle(),
        );
        addedCount++;
      }

      return PersonnelImportResult(
        addedCount: addedCount,
        skippedCount: skippedCount,
        updatedCount: updatedCount,
      );
    });
  }

  Future<bool> updatePersonnel(PersonelTableData data, {String? tarih}) async {
    return db.transaction(() async {
      final oldData =
          await (db.select(db.personelTable)
            ..where((tbl) => tbl.id.equals(data.id))).getSingleOrNull();

      if (oldData == null) return false;
      final result = await db.update(db.personelTable).replace(data);

      if (oldData.timId != data.timId) {
        final islemStr = data.timId == null ? 'çıkarıldı' : 'eklendi';
        await db
            .into(db.timUyelikGecmisiTable)
            .insert(
              TimUyelikGecmisiTableCompanion.insert(
                personelId: data.id,
                timId: Value(data.timId),
                tarih:
                    tarih ?? DateTime.now().toIso8601String().split('T').first,
                islem: islemStr,
              ),
            );
      }

      return result;
    });
  }

  /// Remembers the phone selected for a personnel record so future
  /// TEMGÜNDRAP forms can suggest it automatically.
  Future<int> updatePersonnelPhone(int personnelId, String phone) {
    return (db.update(db.personelTable)..where(
      (table) => table.id.equals(personnelId),
    )).write(PersonelTableCompanion(telefon: Value(phone.trim())));
  }

  Future<int> deletePersonnel(int id, {String? tarih}) async {
    return db.transaction(() async {
      final p =
          await (db.select(db.personelTable)
            ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

      if (p == null || !p.aktif) return 0;
      if (p.timId != null) {
        await db
            .into(db.timUyelikGecmisiTable)
            .insert(
              TimUyelikGecmisiTableCompanion.insert(
                personelId: id,
                timId: Value(p.timId),
                tarih:
                    tarih ?? DateTime.now().toIso8601String().split('T').first,
                islem: 'çıkarıldı',
              ),
            );
      }

      return (db.delete(db.personelTable)
        ..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  /// History Log Operations
  Stream<List<TimUyelikGecmisiTableData>> watchAllHistory() {
    return (db.select(db.timUyelikGecmisiTable)..orderBy([
      (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
    ])).watch();
  }

  Future<void> ensureDefaultSquads() => db.ensureSeeded();

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
    return db
        .into(db.timTable)
        .insert(
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
      final userId = await db
          .into(db.kullaniciTable)
          .insert(
            KullaniciTableCompanion.insert(
              kullaniciAdi: komutanKullaniciAdi,
              sifre: const Value(''),
              rol: 'tim_komutani',
            ),
          );

      // 2. Create squad linked to commander user
      return db
          .into(db.timTable)
          .insert(
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
    return db
        .into(db.kullaniciTable)
        .insert(
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
  }) async {
    final hashedPassword = await PasswordHasher.hashPassword(newPassword);
    return (db.update(db.kullaniciTable)..where(
      (tbl) => tbl.kullaniciAdi.equals(kullaniciAdi),
    )).write(KullaniciTableCompanion(sifre: Value(hashedPassword)));
  }

  /// List all Tim Komutanı accounts
  Stream<List<KullaniciTableData>> watchAllCommanders() {
    return (db.select(db.kullaniciTable)
      ..where((tbl) => tbl.rol.equals('tim_komutani'))).watch();
  }

  /// Reassign or revoke a Tim Komutanı's squad authority
  Future<void> assignCommanderToSquad({
    required int userId,
    required int? timId,
  }) async {
    await db.transaction(() async {
      final user =
          await (db.select(db.kullaniciTable)
            ..where((table) => table.id.equals(userId))).getSingleOrNull();
      if (user == null || user.rol != 'tim_komutani') {
        throw ArgumentError('Tim komutanı hesabı bulunamadı.');
      }
      final target =
          timId == null
              ? null
              : await (db.select(db.timTable)
                ..where((table) => table.id.equals(timId))).getSingleOrNull();
      if (timId != null && target == null) {
        throw ArgumentError('Tim bulunamadı.');
      }
      await (db.update(db.timTable)..where(
        (table) => table.timKomutaniId.equals(userId),
      )).write(const TimTableCompanion(timKomutaniId: Value(null)));
      final previousId = target?.timKomutaniId;
      if (previousId != null && previousId != userId) {
        await (db.update(db.kullaniciTable)..where(
          (table) => table.id.equals(previousId) & table.timId.equals(timId!),
        )).write(const KullaniciTableCompanion(timId: Value(null)));
      }
      await (db.update(db.kullaniciTable)..where(
        (table) => table.id.equals(userId),
      )).write(KullaniciTableCompanion(timId: Value(timId)));
      if (timId != null) {
        await (db.update(db.timTable)..where(
          (table) => table.id.equals(timId),
        )).write(TimTableCompanion(timKomutaniId: Value(userId)));
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
      final person =
          await (db.select(db.personelTable)
            ..where((p) => p.id.equals(personnelId))).getSingle();
      if (!person.aktif || person.isDemo) {
        throw ArgumentError('Aktif gerçek personel seçilmeli.');
      }
      await updatePersonnel(person.copyWith(timId: Value(timId)));

      // 2. Check if user already exists
      final existingUser =
          await (db.select(db.kullaniciTable)..where(
            (tbl) => tbl.kullaniciAdi.equals(kullaniciAdi),
          )).getSingleOrNull();

      int userId;
      if (existingUser != null) {
        userId = existingUser.id;
        await (db.update(db.kullaniciTable)
          ..where((tbl) => tbl.id.equals(userId))).write(
          KullaniciTableCompanion(
            rol: const Value('tim_komutani'),
            timId: Value(timId),
          ),
        );
      } else {
        userId = await db
            .into(db.kullaniciTable)
            .insert(
              KullaniciTableCompanion.insert(
                kullaniciAdi: kullaniciAdi,
                sifre: const Value(''),
                rol: 'tim_komutani',
                timId: Value(timId),
              ),
            );
      }

      await assignCommanderToSquad(userId: userId, timId: timId);
    });
  }

  /// Seed test personnel (e.g. 10 per squad) for trial/testing purposes
  Future<int> seedTestPersonnelPerSquad({int countPerSquad = 10}) async {
    if (!kDebugMode) {
      throw StateError('Test verisi yalnızca geliştirme sürümünde oluşturulur.');
    }
    final squads = await db.select(db.timTable).get();
    if (squads.isEmpty) return 0;

    final firstNames = [
      'Ahmet',
      'Mehmet',
      'Mustafa',
      'Ali',
      'Hüseyin',
      'Hasan',
      'İbrahim',
      'İsmail',
      'Osman',
      'Murat',
      'Ömer',
      'Yusuf',
      'Emre',
      'Burak',
      'Hakan',
      'Serkan',
      'Fatih',
      'Gökhan',
      'Yasin',
      'Bilal',
      'Kaan',
      'Oguz',
      'Eren',
      'Tolga',
    ];

    final lastNames = [
      'YILMAZ',
      'KAYA',
      'DEMİR',
      'ÇELİK',
      'ŞAHİN',
      'YILDIZ',
      'YILDIRIM',
      'ÖZTÜRK',
      'AYDIN',
      'ÖZDEMİR',
      'ARSLAN',
      'DOĞAN',
      'KILIÇ',
      'ASLAN',
      'ÇETİN',
      'KOÇ',
      'KURT',
      'ÖZKAN',
      'ŞEN',
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
      final existingDemo =
          await (db.select(db.personelTable)
            ..where((p) => p.isDemo.equals(true))).get();
      final demoKeys =
          existingDemo.map((p) => '${p.timId}|${p.adSoyad}').toSet();
      var nameIdx = 0;
      for (final squad in squads) {
        final toInsert = <PersonelTableCompanion>[];
        for (var i = 1; i <= countPerSquad; i++) {
          final fName = firstNames[nameIdx % firstNames.length];
          final lName = lastNames[(nameIdx * 3) % lastNames.length];
          final rank = ranks[i % ranks.length];
          nameIdx++;

          if (!demoKeys.add('${squad.id}|$fName $lName')) continue;
          toInsert.add(
            PersonelTableCompanion.insert(
              adSoyad: '$fName $lName',
              isDemo: const Value(true),
              rutbe: rank,
              birlik: MilitaryStructureHelper.getOfficialBirlikName(
                squad.timAdi,
              ),
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

  /// Only explicitly marked demo personnel may be permanently removed here.
  Future<int> deleteAllPersonnel() async {
    if (!kDebugMode) {
      throw StateError('Test verisi temizliği yalnızca geliştirme sürümünde yapılır.');
    }
    return db.transaction(() async {
      final demo =
          await (db.select(db.personelTable)
            ..where((p) => p.isDemo.equals(true))).get();
      final ids = demo.map((p) => p.id).toList();
      if (ids.isEmpty) return 0;
      await (db.delete(db.timUyelikGecmisiTable)
        ..where((h) => h.personelId.isIn(ids))).go();
      return (db.delete(db.personelTable)..where((p) => p.id.isIn(ids))).go();
    });
  }
}
