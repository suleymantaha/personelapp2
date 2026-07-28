import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('AppDatabase migration', () {
    test('upgrades schema version 1 by creating membership history', () async {
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

      final table = await db
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name = 'tim_uyelik_gecmisi_table';",
          )
          .getSingleOrNull();

      expect(table?.read<String>('name'), 'tim_uyelik_gecmisi_table');
      expect(sqliteDatabase.userVersion, 2);
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
