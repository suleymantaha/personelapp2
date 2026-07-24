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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
        final m = Migrator(this);
        try {
          await m.createTable(timUyelikGecmisiTable);
        } on Object catch (_) {
          // Table already exists
        }

        final adminUser = await (select(
          kullaniciTable,
        )..where((tbl) => tbl.kullaniciAdi.equals('admin'))).getSingleOrNull();
        if (adminUser == null) {
          await into(kullaniciTable).insert(
            KullaniciTableCompanion.insert(
              kullaniciAdi: 'admin',
              sifre: const Value('123456'),
              rol: 'yönetici',
            ),
          );
        }

        // Seed 12 default squads matching modTekTimSecim.bas structure
        final existingSquads = await select(timTable).get();
        if (existingSquads.isEmpty) {
          final defaultSquads = [
            'K.H',
            '1\'inci Bl. K.H',
            '1-B Timi',
            '2-B Timi',
            '3-B Timi',
            '4-B Timi',
            '2\'nci Bl. K.H',
            '5-B Timi',
            '6-B Timi',
            '7-B Timi',
            '8-B Timi',
            '3\'üncü Bl. K.H',
            '9-B Timi',
            '10-B Timi',
            '11-B Timi',
            '12-B Timi',
          ];
          for (final name in defaultSquads) {
            await into(timTable).insert(
              TimTableCompanion.insert(
                timAdi: name,
                olusturmaTarihi: DateTime.now().toIso8601String(),
              ),
            );
          }
        }
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          try {
            await m.createTable(timUyelikGecmisiTable);
          } on Object catch (_) {}
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'jandarma_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
