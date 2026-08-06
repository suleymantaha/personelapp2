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
  int get schemaVersion => 4;

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
          final personnelTableExists = await customSelect(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' "
            "AND name = 'personel_table';",
          ).getSingleOrNull();
          if (personnelTableExists != null) {
            await m.addColumn(personelTable, personelTable.telefon);
          }
        }
      },
    );
  }

  Future<void> _validateMembershipHistoryMigration() async {
    final schemaObject = await customSelect(
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
  Future<void> ensureSeeded() async {
    final adminUser = await (select(
      kullaniciTable,
    )..where((tbl) => tbl.kullaniciAdi.equals('admin')))
        .getSingleOrNull();
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
      await (update(kullaniciTable)
            ..where((table) => table.id.equals(adminUser.id)))
          .write(const KullaniciTableCompanion(sifre: Value('')));
    }

    final existingSquads = await select(timTable).get();
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
    final toInsert = <TimTableCompanion>[];
    for (final name in defaultSquads) {
      if (!existingNames.contains(name)) {
        toInsert.add(
          TimTableCompanion.insert(
            timAdi: name,
            olusturmaTarihi: nowStr,
          ),
        );
      }
    }
    if (toInsert.isNotEmpty) {
      await batch((b) => b.insertAll(timTable, toInsert));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'jandarma_app.sqlite'));
    return NativeDatabase(file);
  });
}
