import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';

void main() {
  group('AppDatabase.ensureSeeded', () {
    test('seeds METİ Timi along with default squads on fresh database', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await db.ensureSeeded();

      final squads = await db.select(db.timTable).get();
      final squadNames = squads.map((s) => s.timAdi).toList();

      expect(squadNames, contains('METİ Timi'));
      expect(squadNames, contains('K.H'));
      expect(squadNames, contains('1-B Timi'));
      expect(squadNames, contains('12-B Timi'));
    });

    test('adds METİ Timi to existing database if missing', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      // Simulate existing database with some squads and admin user, but without METİ
      await db.into(db.kullaniciTable).insert(
            KullaniciTableCompanion.insert(
              kullaniciAdi: 'admin',
              sifre: const Value('password'),
              rol: 'yönetici',
            ),
          );
      await db.into(db.timTable).insert(
            TimTableCompanion.insert(
              timAdi: '1-B Timi',
              olusturmaTarihi: '2026-01-01',
            ),
          );

      await db.ensureSeeded();

      final squads = await db.select(db.timTable).get();
      final squadNames = squads.map((s) => s.timAdi).toList();

      expect(squadNames, contains('METİ Timi'));
      expect(squadNames, contains('1-B Timi'));
    });
  });
}
