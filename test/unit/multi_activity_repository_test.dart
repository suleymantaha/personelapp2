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
    expect(
      assignments.singleWhere((item) => item.faaliyetId == firstId).durum,
      AssignmentStatus.onaylandi,
    );
    expect(
      assignments.singleWhere((item) => item.faaliyetId == secondId).durum,
      AssignmentStatus.beklemede,
    );
  });

  test('iki bekleyen çakışmalı görevden yalnız ilki onaylanabilir', () async {
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
    final second = rows.singleWhere((item) => item.faaliyetId == secondId);

    final firstResult = await repository.approveAssignment(
      first.id,
      actor: admin,
    );
    final secondResult = await repository.approveAssignment(
      second.id,
      actor: admin,
    );

    expect(firstResult.approvedCount, 1);
    expect(secondResult.blockedCount, 1);
    final persisted = await (database.select(
      database.faaliyetPersonelAtamaTable,
    )..where((table) => table.id.equals(second.id)))
        .getSingle();
    expect(persisted.durum, AssignmentStatus.beklemede);
    expect(secondResult.conflictDescriptions, isNotEmpty);
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
