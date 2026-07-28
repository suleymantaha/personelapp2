import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

void main() {
  test('batch creation rolls back all dates when one request fails', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ActivityRepository(database);
    final personId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ali Deneme',
            rutbe: 'J.Ütğm.',
            birlik: '7-B',
            kayitTarihi: '2026-07-28',
          ),
        );

    Map<String, dynamic> assignment(int id) => {
          'personelId': id,
          'gorevVeyaIzin': 'GÖREVLİ',
          'aciklama': null,
        };

    await expectLater(
      repository.createActivitiesWithAssignments([
        ActivityCreateRequest(
          faaliyetAdi: 'Günlük Tüm Faaliyetler',
          tarih: '2026-07-28',
          olusturanKullanici: 'admin',
          personnelAssignments: [assignment(personId)],
        ),
        ActivityCreateRequest(
          faaliyetAdi: 'Günlük Tüm Faaliyetler',
          tarih: '2026-07-29',
          olusturanKullanici: 'admin',
          personnelAssignments: [assignment(999999)],
        ),
      ]),
      throwsA(anything),
    );

    expect(await database.select(database.gunlukFaaliyetTable).get(), isEmpty);
    expect(
      await database.select(database.faaliyetPersonelAtamaTable).get(),
      isEmpty,
    );
  });
}
