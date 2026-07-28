import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/services/personnel_backup_service.dart';

void main() {
  late AppDatabase db;
  late PersonnelBackupService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = PersonnelBackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('PersonnelBackupService should export and restore personnel and squads correctly', () async {
    // 1. Insert test squad and personnel
    final squadId = await db.into(db.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '1/B Timi',
            olusturmaTarihi: '2026-07-26',
          ),
        );

    await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ahmet KAYA',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '1.J.KÖK.Tug.K.lığı',
            timId: Value(squadId),
            kayitTarihi: '2026-07-26',
          ),
        );

    // 2. Export backup JSON
    final jsonStr = await service.exportBackupJson();
    expect(jsonStr, contains('Ahmet KAYA'));
    expect(jsonStr, contains('1/B Timi'));

    // 3. Clear database
    await db.delete(db.personelTable).go();
    await db.delete(db.timTable).go();

    final clearedPersonnel = await db.select(db.personelTable).get();
    expect(clearedPersonnel.isEmpty, isTrue);

    // 4. Restore from backup
    final count = await service.importBackupJson(jsonStr);
    expect(count, equals(1));

    final restoredPersonnel = await db.select(db.personelTable).get();
    expect(restoredPersonnel.length, equals(1));
    expect(restoredPersonnel.first.adSoyad, equals('Ahmet KAYA'));

    final restoredSquads = await db.select(db.timTable).get();
    expect(restoredSquads.length, equals(1));
    expect(restoredSquads.first.timAdi, equals('1/B Timi'));
  });

  test('unsupported backup version is rejected without writes', () async {
    await expectLater(
      service.importBackupJson(
        '{"version":2,"squads":[],"personnel":[]}',
      ),
      throwsA(isA<FormatException>()),
    );
    expect(await db.select(db.personelTable).get(), isEmpty);
    expect(await db.select(db.timTable).get(), isEmpty);
  });

  test('malformed collection type is rejected', () async {
    await expectLater(
      service.importBackupJson(
        '{"version":1,"squads":{},"personnel":[]}',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('oversized backup is rejected before parsing', () async {
    final oversized = 'x' * (PersonnelBackupService.maxBackupBytes + 1);
    await expectLater(
      service.importBackupJson(oversized),
      throwsA(isA<FormatException>()),
    );
  });
}
