import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

void main() {
  const admin = UserSessionState(
    username: 'admin',
    role: UserRole.admin,
  );
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

    PersonnelAssignmentInput assignment(int id) =>
        PersonnelAssignmentInput(personnelId: id, duty: 'GÖREVLİ');

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
      ], actor: admin),
      throwsA(anything),
    );

    expect(await database.select(database.gunlukFaaliyetTable).get(), isEmpty);
    expect(
      await database.select(database.faaliyetPersonelAtamaTable).get(),
      isEmpty,
    );
  });

  test('batch creation keeps same-day duty requests as separate cards',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ActivityRepository(database);
    final firstPersonId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ali Deneme',
            rutbe: 'J.Utgm.',
            birlik: '7-B',
            kayitTarihi: '2026-07-28',
          ),
        );
    final secondPersonId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Veli Deneme',
            rutbe: 'J.Asb.',
            birlik: '7-B',
            kayitTarihi: '2026-07-28',
          ),
        );

    await repository.createActivitiesWithAssignments([
      ActivityCreateRequest(
        faaliyetAdi: 'HAZIR KITA',
        tarih: '2026-07-28',
        olusturanKullanici: 'admin',
        personnelAssignments: [
          PersonnelAssignmentInput(
            personnelId: firstPersonId,
            duty: 'HAZIR KITA',
          ),
        ],
      ),
      ActivityCreateRequest(
        faaliyetAdi: 'GULUSKUR',
        tarih: '2026-07-28',
        olusturanKullanici: 'admin',
        personnelAssignments: [
          PersonnelAssignmentInput(
            personnelId: secondPersonId,
            duty: 'GULUSKUR',
          ),
        ],
      ),
    ], actor: admin);

    final activities = await database.select(database.gunlukFaaliyetTable).get();
    expect(activities.map((activity) => activity.faaliyetAdi).toSet(), {
      'HAZIR KITA',
      'GULUSKUR',
    });
    expect(activities.map((activity) => activity.tarih).toSet(), {
      '2026-07-28',
    });
  });

  test('batch creation merges normalized same-day activity names', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ActivityRepository(database);
    final firstPersonId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ali Deneme',
            rutbe: 'J.Utgm.',
            birlik: '7-B',
            kayitTarihi: '2026-07-28',
          ),
        );
    final secondPersonId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Veli Deneme',
            rutbe: 'J.Asb.',
            birlik: '7-B',
            kayitTarihi: '2026-07-28',
          ),
        );

    await repository.createActivitiesWithAssignments([
      ActivityCreateRequest(
        faaliyetAdi: 'Hazir  Kita',
        tarih: '2026-07-28',
        olusturanKullanici: 'admin',
        personnelAssignments: [
          PersonnelAssignmentInput(
            personnelId: firstPersonId,
            duty: 'HAZIR KITA',
          ),
        ],
      ),
      ActivityCreateRequest(
        faaliyetAdi: ' hazir kita ',
        tarih: '2026-07-28',
        olusturanKullanici: 'admin',
        personnelAssignments: [
          PersonnelAssignmentInput(
            personnelId: secondPersonId,
            duty: 'HAZIR KITA',
          ),
        ],
      ),
    ], actor: admin);

    final activities = await database.select(database.gunlukFaaliyetTable).get();
    final assignments =
        await database.select(database.faaliyetPersonelAtamaTable).get();

    expect(activities, hasLength(1));
    expect(assignments, hasLength(2));
  });
}
