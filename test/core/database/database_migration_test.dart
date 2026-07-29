import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('AppDatabase migration', () {
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
      expect(sqliteDatabase.userVersion, 3);
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
  });
}
