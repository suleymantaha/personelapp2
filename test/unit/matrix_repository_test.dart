import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository actRepo;
  late MatrixRepository matrixRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    actRepo = ActivityRepository(db);
    matrixRepo = MatrixRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Monthly matrix should map personnel duties to day numbers', () async {
    // Insert personnel
    final pId = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Hasan Uzun',
            rutbe: 'YÜZBAŞI',
            birlik: 'Birlik HQ',
            kayitTarihi: '2026-07-01',
          ),
        );

    // Insert activity with assignment on 2026-07-15
    await actRepo.createActivityWithAssignments(
      faaliyetAdi: 'Devriye 1',
      tarih: '2026-07-15',
      olusturanKullanici: 'admin',
      personnelAssignments: [
        {
          'personelId': pId,
          'gorevVeyaIzin': 'GÖREVLİ',
          'aciklama': null,
        }
      ],
    );

    final matrixMap = await matrixRepo.watchMonthlyMatrix('2026-07').first;

    expect(matrixMap.containsKey(pId), isTrue);
    expect(matrixMap[pId]?[15], equals('GÖREVLİ'));
  });
}
