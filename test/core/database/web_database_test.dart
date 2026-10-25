@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('browser database preserves records when connection reopens', () async {
    var db = AppDatabase();
    await db.ensureSeeded();
    final id = await db.into(db.timTable).insert(TimTableCompanion.insert(
          timAdi: 'WEB_SENTETIK_${DateTime.now().microsecondsSinceEpoch}',
          olusturmaTarihi: '2026-10-24',
        ));
    await db.close();
    db = AppDatabase();
    try {
      final saved = await (db.select(db.timTable)
            ..where((row) => row.id.equals(id)))
          .getSingle();
      expect(saved.timAdi, startsWith('WEB_SENTETIK_'));
      expect(db.schemaVersion, 6);
      expect(
          (await db.customSelect('PRAGMA foreign_keys').getSingle())
              .read<int>('foreign_keys'),
          1);
      await (db.delete(db.timTable)..where((row) => row.id.equals(id))).go();
    } finally {
      await db.close();
    }
  });
}
