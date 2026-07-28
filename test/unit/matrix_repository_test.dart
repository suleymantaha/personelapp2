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
        },
      ],
    );

    final matrixMap = await matrixRepo.watchMonthlyMatrix('2026-07').first;

    expect(matrixMap.containsKey(pId), isTrue);
    expect(matrixMap[pId]?[15]?.displayCode, equals('X'));
    expect(matrixMap[pId]?[15]?.entries.single.duty, equals('GÖREVLİ'));
  });

  test(
    'Monthly matrix should reactively update when new assignments are added',
    () async {
      final pId = await db.into(db.personelTable).insert(
            PersonelTableCompanion.insert(
              adSoyad: 'Ali Kaya',
              rutbe: 'TEĞMEN',
              birlik: 'Birlik HQ',
              kayitTarihi: '2026-07-01',
            ),
          );

      final stream = matrixRepo.watchMonthlyMatrix('2026-07');

      // Add activity for 2026-07-20
      await actRepo.createActivityWithAssignments(
        faaliyetAdi: 'Nöbet 1',
        tarih: '2026-07-20',
        olusturanKullanici: 'admin',
        personnelAssignments: [
          {
            'personelId': pId,
            'gorevVeyaIzin': 'NÖBETÇİ',
            'aciklama': null,
          },
        ],
      );

      final updatedMap = await stream.first;
      expect(updatedMap[pId]?[20]?.displayCode, equals('X'));
      expect(updatedMap[pId]?[21], isNull);
    },
  );

  test('24 saatlik görev sonraki ayın ilk gününe devam eder', () async {
    final pId = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ay Sonu Personeli',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '6/B',
            kayitTarihi: '2026-07-01',
          ),
        );
    await actRepo.createActivityWithAssignments(
      faaliyetAdi: 'Hazır Kıta',
      tarih: '2026-07-31',
      olusturanKullanici: 'admin',
      personnelAssignments: [
        {
          'personelId': pId,
          'gorevVeyaIzin': 'HAZIR KITA',
          'aciklama': null,
        },
      ],
    );

    final july = await matrixRepo.watchMonthlyMatrix('2026-07').first;
    final august = await matrixRepo.watchMonthlyMatrix('2026-08').first;

    expect(july[pId]?[31]?.displayCode, 'X');
    expect(august[pId]?[1]?.displayCode, 'X');
    expect(august[pId]?[1]?.entries.single.isContinuationDay, isTrue);
  });
}
