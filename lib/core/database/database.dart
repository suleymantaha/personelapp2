import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:personelapp2/core/database/tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    KullaniciTable,
    TimTable,
    PersonelTable,
    GunlukFaaliyetTable,
    FaaliyetPersonelAtamaTable,
    RaporKayitTable,
    TimUyelikGecmisiTable,
    PersonelIsimTakmaAdTable,
    TopluAktarimGecmisiTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
      },
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(timUyelikGecmisiTable);
          await _validateMembershipHistoryMigration();
        }
        if (from < 3) {
          await m.createTable(personelIsimTakmaAdTable);
          await m.createTable(topluAktarimGecmisiTable);
        }
        if (from < 4) {
          final personnelTableExists =
              await customSelect(
                "SELECT 1 FROM sqlite_master WHERE type = 'table' "
                "AND name = 'personel_table';",
              ).getSingleOrNull();
          if (personnelTableExists != null) {
            await m.addColumn(personelTable, personelTable.telefon);
          }
        }
        if (from < 5) {
          if (await _tableExists('personel_table')) {
            await m.addColumn(personelTable, personelTable.aktif);
            await m.addColumn(personelTable, personelTable.isDemo);
          }
          if (await _tableExists('faaliyet_personel_atama_table')) {
            await m.addColumn(
              faaliyetPersonelAtamaTable,
              faaliyetPersonelAtamaTable.gorevTimId,
            );
            await m.addColumn(
              faaliyetPersonelAtamaTable,
              faaliyetPersonelAtamaTable.gorevTimAdi,
            );
            await backfillTaskTeamsFromHistory();
          }
        }
      },
    );
  }

  Future<bool> _tableExists(String name) async =>
      await customSelect(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        variables: [Variable(name)],
      ).getSingleOrNull() !=
      null;

  Future<void> backfillTaskTeamsFromHistory() async {
    if (!await _tableExists('tim_uyelik_gecmisi_table') ||
        !await _tableExists('gunluk_faaliyet_table') ||
        !await _tableExists('tim_table')) {
      return;
    }
    await customStatement("""
      UPDATE faaliyet_personel_atama_table AS a SET gorev_tim_id = (
        SELECT CASE WHEN h.islem = 'çıkarıldı' THEN NULL ELSE h.tim_id END
        FROM tim_uyelik_gecmisi_table h JOIN gunluk_faaliyet_table f ON f.id = a.faaliyet_id
        WHERE h.personel_id = a.personel_id AND substr(h.tarih, 1, 10) <= f.tarih
        ORDER BY h.tarih DESC, h.id DESC LIMIT 1
      ) WHERE gorev_tim_id IS NULL AND gorev_tim_adi IS NULL
    """);
    await customStatement("""
      UPDATE faaliyet_personel_atama_table SET gorev_tim_adi = (
        SELECT tim_adi FROM tim_table WHERE id = gorev_tim_id
      ) WHERE gorev_tim_id IS NOT NULL AND gorev_tim_adi IS NULL
    """);
  }

  Future<void> _validateMembershipHistoryMigration() async {
    final schemaObject =
        await customSelect(
          "SELECT type FROM sqlite_master "
          "WHERE name = 'tim_uyelik_gecmisi_table';",
        ).getSingleOrNull();
    if (schemaObject?.read<String>('type') != 'table') {
      throw StateError(
        'v2 migration failed: tim_uyelik_gecmisi_table was not created.',
      );
    }
  }

  /// Safe asynchronous seeding method called after database connection is active
  Future<void> ensureSeeded() => transaction(() async {
    final adminUser =
        await (select(kullaniciTable)
          ..where((tbl) => tbl.kullaniciAdi.equals('admin'))).getSingleOrNull();
    if (adminUser == null) {
      await into(kullaniciTable).insert(
        KullaniciTableCompanion.insert(
          kullaniciAdi: 'admin',
          sifre: const Value(''),
          rol: 'yönetici',
        ),
      );
    } else if (adminUser.sifre == '123456') {
      // Invalidate the legacy well-known credential. The existing first-login
      // flow will require a new password before creating a session.
      await (update(kullaniciTable)..where(
        (table) => table.id.equals(adminUser.id),
      )).write(const KullaniciTableCompanion(sifre: Value('')));
    }

    final existingSquads = await select(timTable).get();
    if (adminUser != null || existingSquads.isNotEmpty) {
      final hasMeti = existingSquads.any((s) {
        final u = s.timAdi.toUpperCase();
        return u.contains('METİ') || u.contains('METI');
      });
      if (!hasMeti && existingSquads.isNotEmpty) {
        final nowStr = DateTime.now().toIso8601String();
        await into(timTable).insert(
          TimTableCompanion.insert(
            timAdi: 'METİ Timi',
            olusturmaTarihi: nowStr,
          ),
        );
      }
      return;
    }
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
      'METİ Timi',
    ];
    final nowStr = DateTime.now().toIso8601String();
    final toInsert = <TimTableCompanion>[];
    for (final name in defaultSquads) {
      if (!existingNames.contains(name)) {
        toInsert.add(
          TimTableCompanion.insert(timAdi: name, olusturmaTarihi: nowStr),
        );
      }
    }
    if (toInsert.isNotEmpty) {
      await batch((b) => b.insertAll(timTable, toInsert));
    }
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'jandarma_app.sqlite'));
    return NativeDatabase(file);
  });
}
