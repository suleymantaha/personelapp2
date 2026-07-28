import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

void main() {
  late AppDatabase database;
  late ActivityRepository repository;
  late int personId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = ActivityRepository(database);
    personId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ali Deneme',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '6/B',
            kayitTarihi: '2026-07-28',
          ),
        );
  });

  tearDown(() => database.close());

  Map<String, dynamic> assignment(String duty) => {
        'personelId': personId,
        'gorevVeyaIzin': duty,
        'aciklama': null,
      };

  test('aynı tarih ve isimde faaliyetler bağımsız kimliklerle saklanır',
      () async {
    final firstId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Görev',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      personnelAssignments: [assignment('GÖREVLİ')],
    );
    final secondId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Görev',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      personnelAssignments: [assignment('NÖBETÇİ')],
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
      isCommander: true,
    );
    final secondId = await repository.createActivityWithAssignments(
      faaliyetAdi: 'Devriye',
      tarih: '2026-07-29',
      olusturanKullanici: 'komutan',
      personnelAssignments: [assignment('GÖREVLİ')],
      isCommander: true,
    );
    final rows =
        await database.select(database.faaliyetPersonelAtamaTable).get();
    final first = rows.singleWhere((item) => item.faaliyetId == firstId);
    final second = rows.singleWhere((item) => item.faaliyetId == secondId);

    final firstResult = await repository.approveAssignment(first.id);
    final secondResult = await repository.approveAssignment(second.id);

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
    );
    final payload = [
      assignment('HAZIR KITA'),
      {
        'personelId': secondPersonId,
        'gorevVeyaIzin': 'HAZIR KITA',
        'aciklama': null,
      },
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
    );
    final changed = [
      {
        'personelId': personId,
        'gorevVeyaIzin': 'NÖBETÇİ',
        'aciklama': 'Gece vardiyası',
      },
    ];

    final skipped = await repository.mergeAssignmentsIntoActivity(
      activityId: activityId,
      personnelAssignments: changed,
      updateDifferentAssignments: false,
    );
    expect(skipped.skippedCount, 1);
    var row =
        await database.select(database.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevVeyaIzin, 'GÖREVLİ');

    final updated = await repository.mergeAssignmentsIntoActivity(
      activityId: activityId,
      personnelAssignments: changed,
      updateDifferentAssignments: true,
    );
    expect(updated.updatedCount, 1);
    row =
        await database.select(database.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevVeyaIzin, 'NÖBETÇİ');
    expect(row.aciklama, 'Gece vardiyası');
  });
}
