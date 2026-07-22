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
