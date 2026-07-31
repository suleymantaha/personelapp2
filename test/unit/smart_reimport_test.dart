import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

void main() {
  late AppDatabase database;
  late ActivityRepository repository;
  late BulkImportLearningService learningService;
  late int personnelId1;
  late int personnelId2;
  const adminActor = UserSessionState(
    username: 'admin',
    role: UserRole.admin,
  );

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = ActivityRepository(database);
    learningService = BulkImportLearningService(database);

    final teamId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '9-B Timi',
            olusturmaTarihi: '2026-01-01',
          ),
        );
    personnelId1 = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ahmet TINAS',
            rutbe: 'J.Asb.Çvş.',
            birlik: '9/B',
            timId: Value(teamId),
            kayitTarihi: '2026-01-01',
          ),
        );
    personnelId2 = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ramazan BOSTAN',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '9/B',
            timId: Value(teamId),
            kayitTarihi: '2026-01-01',
          ),
        );
  });

  tearDown(() => database.close());

  ParsedActivityBlock createBlock(List<int> pIds) => ParsedActivityBlock(
        rawTitle: '9/B Gülüşkür',
        parsedTimName: '9/B',
        parsedActivityType: 'GÜLÜŞKÜR',
        parsedDate: '2026-07-30',
        personnelList: pIds
            .map(
              (id) => ParsedPersonnelItem(
                rawIndex: 1,
                rawRank: 'J.Uzm.Çvş.',
                rawName: 'Person #$id',
                matchedPersonnelId: id,
              ),
            )
            .toList(),
      );

  test('countActiveAssignments returns 0 after deleting activity', () async {
    final block = createBlock([personnelId1]);
    final request = ActivityCreateRequest(
      faaliyetAdi: 'Günlük Tüm Faaliyetler',
      tarih: '2026-07-30',
      olusturanKullanici: 'Admin',
      personnelAssignments: [
        PersonnelAssignmentInput(
          personnelId: personnelId1,
          duty: 'GÜLÜŞKÜR',
        ),
      ],
    );
    final batch = await repository.createActivitiesWithAssignments(
      [request],
      actor: adminActor,
    );

    expect(await learningService.countActiveAssignments([block]), 1);

    // Delete the activity
    await (database.delete(database.gunlukFaaliyetTable)
          ..where((tbl) => tbl.id.equals(batch.activityIds.first)))
        .go();

    expect(await learningService.countActiveAssignments([block]), 0);
  });

  test('smart merge adds missing personnel without duplicating existing ones', () async {
    // Import person 1
    final request1 = ActivityCreateRequest(
      faaliyetAdi: 'Günlük Tüm Faaliyetler',
      tarih: '2026-07-30',
      olusturanKullanici: 'Admin',
      personnelAssignments: [
        PersonnelAssignmentInput(
          personnelId: personnelId1,
          duty: 'GÜLÜŞKÜR',
        ),
      ],
    );
    await repository.createActivitiesWithAssignments([request1], actor: adminActor);

    // Import person 1 AND person 2 into existing activity
    final request2 = ActivityCreateRequest(
      faaliyetAdi: 'Günlük Tüm Faaliyetler',
      tarih: '2026-07-30',
      olusturanKullanici: 'Admin',
      personnelAssignments: [
        PersonnelAssignmentInput(
          personnelId: personnelId1,
          duty: 'GÜLÜŞKÜR',
        ),
        PersonnelAssignmentInput(
          personnelId: personnelId2,
          duty: 'GÜLÜŞKÜR',
        ),
      ],
    );
    final result = await repository.createActivitiesWithAssignments([request2], actor: adminActor);

    expect(result.addedAssignmentCount, 1);
    expect(result.alreadyAssignedCount, 1);
  });
}
