import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

void main() {
  const admin = UserSessionState(
    username: 'admin',
    role: UserRole.admin,
  );
  late AppDatabase database;
  late ActivityRepository repository;
  late int personId;
  late UserSessionState commander;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = ActivityRepository(database);
    final teamId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: 'Test Takımı',
            olusturmaTarihi: '2026-07-28',
          ),
        );
    commander = UserSessionState(
      username: 'komutan',
      role: UserRole.teamCommander,
      timId: teamId,
    );
    personId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ali Deneme',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '6/B',
            timId: Value(teamId),
            kayitTarihi: '2026-07-28',
          ),
        );
  });

  tearDown(() => database.close());

  PersonnelAssignmentInput assignment(String duty) =>
      PersonnelAssignmentInput(personnelId: personId, duty: duty);

  test('aynı tarih ve isimde faaliyetler bağımsız kimliklerle saklanır',
      () async {
    final firstId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Görev',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      personnelAssignments: [assignment('GÖREVLİ')],
      actor: admin,
    );
    final secondId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Görev',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      personnelAssignments: [assignment('NÖBETÇİ')],
      actor: admin,
    );

    expect(secondId, isNot(firstId));
    final activities =
        await database.select(database.gunlukFaaliyetTable).get();
    expect(activities, hasLength(2));
    final assignments =
        await database.select(database.faaliyetPersonelAtamaTable).get();
    expect(assignments, hasLength(1));
    expect(assignments.single.faaliyetId, firstId);
    expect(assignments.single.durum, AssignmentStatus.onaylandi);
    expect(assignments.any((item) => item.faaliyetId == secondId), isFalse);
  });

  test('geceyi aşan görev ertesi gün ikinci kaydın yazılmasını engeller',
      () async {
    final firstId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Hazır Kıta',
      tarih: '2026-07-28',
      olusturanKullanici: 'komutan',
      personnelAssignments: [assignment('HAZIR KITA')],
      actor: commander,
    );
    final secondId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Devriye',
      tarih: '2026-07-29',
      olusturanKullanici: 'komutan',
      personnelAssignments: [assignment('GÖREVLİ')],
      actor: commander,
    );
    final rows =
        await database.select(database.faaliyetPersonelAtamaTable).get();
    final first = rows.singleWhere((item) => item.faaliyetId == firstId);
    expect(rows, hasLength(1));
    expect(rows.any((item) => item.faaliyetId == secondId), isFalse);

    final firstResult = await repository.approveAssignment(
      first.id,
      actor: admin,
    );

    expect(firstResult.approvedCount, 1);
  });

  test('tekil ekleme aynı gün mevcut kayıt varsa hata verir', () async {
    await repository.createActivityWithAssignments(
      faaliyetAdi: 'İzin',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      personnelAssignments: [assignment('İZİNLİ')],
      actor: admin,
    );
    final otherActivityId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Diğer',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      personnelAssignments: const [],
      actor: admin,
    );

    expect(
      () => repository.addSingleAssignment(
        faaliyetId: otherActivityId,
        personelId: personId,
        gorevVeyaIzin: 'SEVK',
        tarih: '2026-07-28',
        actor: admin,
      ),
      throwsA(isA<AssignmentConflictException>()),
    );
  });

  test('rapor mevcut görev gününe yazılmaz', () async {
    await repository.createActivityWithAssignments(
      faaliyetAdi: 'Görev',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      personnelAssignments: [assignment('GÖREVLİ')],
      actor: admin,
    );

    expect(
      () => repository.addMedicalReport(
        personelId: personId,
        raporBaslangic: '2026-07-27',
        raporBitis: '2026-07-29',
      ),
      throwsA(isA<AssignmentConflictException>()),
    );
  });

  test('toplu kayıtta çakışanı atlar ve personel adını bildirir', () async {
    final result = await repository.createActivitiesWithAssignments(
      [
        ActivityCreateRequest(
          faaliyetAdi: 'Birinci',
          tarih: '2026-07-28',
          olusturanKullanici: 'admin',
          personnelAssignments: [assignment('GÖREVLİ')],
        ),
        ActivityCreateRequest(
          faaliyetAdi: 'İkinci',
          tarih: '2026-07-28',
          olusturanKullanici: 'admin',
          personnelAssignments: [assignment('İZİNLİ')],
        ),
      ],
      actor: admin,
    );

    expect(result.activityIds, hasLength(2));
    expect(result.addedAssignmentCount, 1);
    expect(result.skippedAssignmentCount, 1);
    expect(result.conflictDescriptions.single, contains('Ali Deneme'));
    expect(
      await database.select(database.faaliyetPersonelAtamaTable).get(),
      hasLength(1),
    );
  });

  test('geçmiş çakışma denetimi kayıtları silmeden raporlar', () async {
    final firstActivity =
        await database.into(database.gunlukFaaliyetTable).insert(
              GunlukFaaliyetTableCompanion.insert(
                faaliyetAdi: 'Birinci',
                tarih: '2026-07-28',
                olusturanKullanici: 'admin',
                olusturmaTarihi: '2026-07-28T08:00:00',
              ),
            );
    final secondActivity =
        await database.into(database.gunlukFaaliyetTable).insert(
              GunlukFaaliyetTableCompanion.insert(
                faaliyetAdi: 'İkinci',
                tarih: '2026-07-28',
                olusturanKullanici: 'admin',
                olusturmaTarihi: '2026-07-28T09:00:00',
              ),
            );
    for (final activityId in [firstActivity, secondActivity]) {
      await database.into(database.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activityId,
              personelId: personId,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: AssignmentStatus.onaylandi,
            ),
          );
    }

    final conflicts = await repository.auditExistingDailyConflicts();

    expect(conflicts.single, contains('Ali Deneme'));
    expect(conflicts.single, contains('2026-07-28'));
    expect(
      await database.select(database.faaliyetPersonelAtamaTable).get(),
      hasLength(2),
    );
  });

  test('aynı tarih ve normalize ad eşleşmesini bulup yalnız yenileri ekler',
      () async {
    final secondPersonId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Veli Deneme',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '6/B',
            kayitTarihi: '2026-07-28',
          ),
        );
    final activityId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Hazır   Kıta',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      personnelAssignments: [assignment('HAZIR KITA')],
      actor: admin,
    );
    final payload = [
      assignment('HAZIR KITA'),
      PersonnelAssignmentInput(
        personnelId: secondPersonId,
        duty: 'HAZIR KITA',
      ),
    ];

    final matches = await repository.findMatchingActivities(
      faaliyetAdi: '  hazır kıta ',
      tarih: '2026-07-28',
      personnelAssignments: payload,
    );
    expect(matches, hasLength(1));
    expect(matches.single.activity.id, activityId);
    expect(matches.single.newPersonnelCount, 1);
    expect(matches.single.unchangedPersonnelCount, 1);

    final result = await repository.mergeAssignmentsIntoActivity(
      activityId: activityId,
      personnelAssignments: payload,
      updateDifferentAssignments: false,
      actor: admin,
    );
    expect(result.addedCount, 1);
    expect(result.skippedCount, 1);
    final activities =
        await database.select(database.gunlukFaaliyetTable).get();
    final assignments =
        await database.select(database.faaliyetPersonelAtamaTable).get();
    expect(activities, hasLength(1));
    expect(assignments, hasLength(2));
  });

  test('farklı görev ve not yalnız açık onayla güncellenir', () async {
    final activityId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Devriye',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      personnelAssignments: [assignment('GÖREVLİ')],
      actor: admin,
    );
    final changed = [
      PersonnelAssignmentInput(
        personnelId: personId,
        duty: 'NÖBETÇİ',
        note: 'Gece vardiyası',
      ),
    ];

    final skipped = await repository.mergeAssignmentsIntoActivity(
      activityId: activityId,
      personnelAssignments: changed,
      updateDifferentAssignments: false,
      actor: admin,
    );
    expect(skipped.skippedCount, 1);
    var row =
        await database.select(database.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevVeyaIzin, 'GÖREVLİ');

    final updated = await repository.mergeAssignmentsIntoActivity(
      activityId: activityId,
      personnelAssignments: changed,
      updateDifferentAssignments: true,
      actor: admin,
    );
    expect(updated.updatedCount, 1);
    row =
        await database.select(database.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevVeyaIzin, 'NÖBETÇİ');
    expect(row.aciklama, 'Gece vardiyası');
  });
}
