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
}
