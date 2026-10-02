import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('AppDatabase migration', () {
    test('v4 migration preserves phone and derives task team from dated history', () async {
      final sqliteDatabase = sqlite3.openInMemory();
      for (final sql in [
        'CREATE TABLE tim_table (id INTEGER PRIMARY KEY, tim_adi TEXT NOT NULL, tim_komutani_id INTEGER, olusturma_tarihi TEXT NOT NULL)',
        'CREATE TABLE personel_table (id INTEGER PRIMARY KEY, ad_soyad TEXT NOT NULL, rutbe TEXT NOT NULL, birlik TEXT NOT NULL, telefon TEXT, tim_id INTEGER, kayit_tarihi TEXT NOT NULL)',
        'CREATE TABLE gunluk_faaliyet_table (id INTEGER PRIMARY KEY, faaliyet_adi TEXT NOT NULL, tarih TEXT NOT NULL, olusturan_kullanici TEXT NOT NULL, olusturma_tarihi TEXT NOT NULL)',
        'CREATE TABLE faaliyet_personel_atama_table (id INTEGER PRIMARY KEY, faaliyet_id INTEGER NOT NULL, personel_id INTEGER NOT NULL, gorev_veya_izin TEXT NOT NULL, durum TEXT NOT NULL, aciklama TEXT)',
        'CREATE TABLE tim_uyelik_gecmisi_table (id INTEGER PRIMARY KEY, personel_id INTEGER NOT NULL, tim_id INTEGER, tarih TEXT NOT NULL, islem TEXT NOT NULL)',
        "INSERT INTO tim_table VALUES (1, '1-B', NULL, '2026-01-01'), (2, '2-B', NULL, '2026-01-01')",
        "INSERT INTO personel_table VALUES (1, 'Ali', 'J.Er', 'Asayiş', '5321112233', 2, '2026-01-01'), (2, 'Veli', 'J.Er', 'Asayiş', NULL, 2, '2026-01-01')",
        "INSERT INTO gunluk_faaliyet_table VALUES (1, 'HEYBET', '2026-10-02', 'admin', '2026-10-02')",
        "INSERT INTO faaliyet_personel_atama_table VALUES (1, 1, 1, 'HEYBET', 'onaylandi', NULL), (2, 1, 2, 'HEYBET', 'onaylandi', NULL)",
        "INSERT INTO tim_uyelik_gecmisi_table VALUES (1, 1, 1, '2026-01-01', 'eklendi'), (2, 1, 2, '2026-10-03', 'eklendi')",
        'PRAGMA user_version = 4',
      ]) { sqliteDatabase.execute(sql); }
      final db = AppDatabase(NativeDatabase.opened(sqliteDatabase, closeUnderlyingOnClose: false));
      addTearDown(() async { await db.close(); sqliteDatabase.close(); });
      final columns = await db.customSelect('PRAGMA table_info(personel_table)').get();
      expect(columns.map((r) => r.read<String>('name')), containsAll(['aktif', 'is_demo']));
      final assignments = await db.select(db.faaliyetPersonelAtamaTable).get();
      expect(assignments, hasLength(2));
      final raw = await db.customSelect('SELECT gorev_tim_id FROM faaliyet_personel_atama_table ORDER BY id').get();
      expect(raw.first.read<int>('gorev_tim_id'), 1);
      expect(raw.last.data['gorev_tim_id'], null);
      expect((await db.select(db.personelTable).get()).first.telefon, '5321112233');
    });

    test('upgrades schema version 1 by creating import support tables',
        () async {
      final sqliteDatabase = sqlite3.openInMemory()
        ..execute('PRAGMA user_version = 1;');
      final db = AppDatabase(
        NativeDatabase.opened(
          sqliteDatabase,
          closeUnderlyingOnClose: false,
        ),
      );
      addTearDown(() async {
        await db.close();
        sqliteDatabase.close();
      });

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name IN "
            "('tim_uyelik_gecmisi_table', "
            "'personel_isim_takma_ad_table', "
            "'toplu_aktarim_gecmisi_table') ORDER BY name;",
          )
          .get();

      expect(
        tables.map((row) => row.read<String>('name')),
        [
          'personel_isim_takma_ad_table',
          'tim_uyelik_gecmisi_table',
          'toplu_aktarim_gecmisi_table',
        ],
      );
      expect(sqliteDatabase.userVersion, 4);
    });

    test('propagates migration failures instead of marking schema ready',
        () async {
      final sqliteDatabase = sqlite3.openInMemory()
        ..execute(
          'CREATE VIEW tim_uyelik_gecmisi_table AS SELECT 1 AS id;',
        )
        ..execute('PRAGMA user_version = 1;');
      final db = AppDatabase(
        NativeDatabase.opened(
          sqliteDatabase,
          closeUnderlyingOnClose: false,
        ),
      );
      addTearDown(() {
        sqliteDatabase.close();
      });

      await expectLater(
        db.customSelect('SELECT 1;').get(),
        throwsA(anything),
      );
      expect(sqliteDatabase.userVersion, 1);
    });

    test('upgrades version 3 personnel table with nullable phone column',
        () async {
      final sqliteDatabase = sqlite3.openInMemory()
        ..execute('''
          CREATE TABLE personel_table (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            ad_soyad TEXT NOT NULL,
            rutbe TEXT NOT NULL,
            birlik TEXT NOT NULL,
            tim_id INTEGER NULL,
            kayit_tarihi TEXT NOT NULL
          );
        ''')
        ..execute('PRAGMA user_version = 3;');
      final db = AppDatabase(NativeDatabase.opened(
        sqliteDatabase,
        closeUnderlyingOnClose: false,
      ));
      addTearDown(() async {
        await db.close();
        sqliteDatabase.close();
      });

      final columns =
          await db.customSelect('PRAGMA table_info(personel_table);').get();

      expect(
          columns.map((row) => row.read<String>('name')), contains('telefon'));
      expect(sqliteDatabase.userVersion, 4);
    });
  });
}
