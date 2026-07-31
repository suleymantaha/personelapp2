# Smart Re-Import & Delta Activity Import Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable seamless re-importing of deleted or partially modified bulk duty lists by validating active database records against import fingerprints, offering an interactive "Complete Missing / Re-import" choice, and performing smart delta merges instead of hard blocking the user.

**Architecture:** Extend `BulkImportLearningService` with `countActiveAssignments()` to check if fingerprint assignments are still present in `faaliyetPersonelAtamaTable`. Upgrade `ActivityRepository.createActivitiesWithAssignments()` to support delta merging (adding missing personnel to existing activities and preserving active ones). Update `BulkImportDialog` UI to present "Eksikleri Tamamla / Yeniden Aktar" choices with clean summary stats.

**Tech Stack:** Dart, Drift ORM, Flutter, Riverpod, `personelapp2` features.

---

## User Review Required

> [!IMPORTANT]
> - Deleting an activity from the screen will no longer permanently block re-importing the same text. The system will detect that the assignments are missing from the database and allow re-importing smoothly.
> - Re-importing a list when some personnel are already assigned will perform a **Smart Delta Merge**: missing personnel are added, already assigned personnel are preserved without error, and a breakdown summary is displayed to the user.

---

## Proposed Changes

### Domain & Learning Service Layer

#### [MODIFY] [bulk_import_learning_service.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/domain/bulk_import_learning_service.dart)
- Add `countActiveAssignments(Iterable<ParsedActivityBlock> blocks)` to query Drift database and return how many assignments from `blocks` are currently active in `faaliyetPersonelAtamaTable`.
- Add `deleteImportRecord(String fingerprint)` to clean up stale import fingerprint records when needed.

### Repository Layer

#### [MODIFY] [activity_repository.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/data/activity_repository.dart)
- Add `alreadyAssignedCount` property to `ActivityBatchCreateResult`.
- Update `createActivitiesWithAssignments()`:
  - If a daily activity already exists for date `request.tarih`, merge new assignments into it instead of creating duplicates or failing.
  - Skip personnel already assigned to that exact duty silently while incrementing `alreadyAssignedCount`.
  - Insert personnel not yet in the activity into `faaliyetPersonelAtamaTable`.

### Presentation Layer

#### [MODIFY] [bulk_import_dialog.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import_dialog.dart)
- In `_saveAllToFaaliyet()`, when `existingImport != null`:
  - Check `activeCount = await learningService.countActiveAssignments(_parsedBlocks)`.
  - If `activeCount == 0` (activity was deleted): clean up stale fingerprint and proceed with import automatically.
  - If `activeCount > 0`: present a dialog with **[EKSİKLERİ TAMAMLA VE GÜNCELLE]** and **[İPTAL]**.
- Update completion summary dialog and SnackBar to display:
  - `${result.addedAssignmentCount} yeni personel eklendi.`
  - `${result.alreadyAssignedCount} personel zaten ekliydi.`
  - `${result.skippedAssignmentCount} çakışan kayıt atlandı.`

### Test Layer

#### [NEW] [smart_reimport_test.dart](file:///c:/Users/baba/personelapp2/test/unit/smart_reimport_test.dart)
- Unit tests for `countActiveAssignments()`, deleting activities and re-importing, and smart delta merging into existing daily activities.

---

## Tasks

### Task 1: Add Unit Tests for Active Import Status & Smart Merge

**Files:**
- Create: `test/unit/smart_reimport_test.dart`

- [ ] **Step 1: Write failing unit tests for active import detection and delta merge**

```dart
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
    userId: 1,
    username: 'admin',
    displayName: 'Admin User',
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
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/unit/smart_reimport_test.dart`
Expected: FAIL with missing methods `countActiveAssignments`, `alreadyAssignedCount`.

---

### Task 2: Implement Active Assignment Counting & Stale Import Clean up in Learning Service

**Files:**
- Modify: `lib/features/activity/domain/bulk_import_learning_service.dart`

- [ ] **Step 1: Implement `countActiveAssignments` and `deleteImportRecord`**

Add to `BulkImportLearningService`:
```dart
Future<int> countActiveAssignments(
  Iterable<ParsedActivityBlock> blocks,
) async {
  final query = database.select(database.faaliyetPersonelAtamaTable).join([
    innerJoin(
      database.gunlukFaaliyetTable,
      database.gunlukFaaliyetTable.id.equalsExp(
        database.faaliyetPersonelAtamaTable.faaliyetId,
      ),
    ),
  ]);
  final rows = await query.get();
  
  var activeCount = 0;
  for (final block in blocks) {
    for (final person in block.personnelList) {
      final pId = person.matchedPersonnelId;
      if (pId == null) continue;
      final match = rows.any((row) {
        final activity = row.readTable(database.gunlukFaaliyetTable);
        final assignment = row.readTable(database.faaliyetPersonelAtamaTable);
        return activity.tarih == block.parsedDate &&
            assignment.personelId == pId &&
            assignment.gorevVeyaIzin.trim().toUpperCase() ==
                block.parsedActivityType.trim().toUpperCase();
      });
      if (match) activeCount++;
    }
  }
  return activeCount;
}

Future<void> deleteImportRecord(String fingerprint) async {
  await (database.delete(database.topluAktarimGecmisiTable)
        ..where((table) => table.parmakIzi.equals(fingerprint)))
      .go();
}
```

- [ ] **Step 2: Run learning service tests to verify**

Run: `flutter test test/unit/bulk_import_learning_service_test.dart`

---

### Task 3: Upgrade `ActivityBatchCreateResult` & Smart Delta Import in Repository

**Files:**
- Modify: `lib/features/activity/data/activity_repository.dart`

- [ ] **Step 1: Update `ActivityBatchCreateResult` and `createActivitiesWithAssignments()`**

Update `ActivityBatchCreateResult`:
```dart
class ActivityBatchCreateResult {
  const ActivityBatchCreateResult({
    required this.activityIds,
    required this.addedAssignmentCount,
    required this.alreadyAssignedCount,
    required this.skippedAssignmentCount,
    this.conflictDescriptions = const [],
  });

  final List<int> activityIds;
  final int addedAssignmentCount;
  final int alreadyAssignedCount;
  final int skippedAssignmentCount;
  final List<String> conflictDescriptions;
}
```

Update `createActivitiesWithAssignments()` in `activity_repository.dart`:
```dart
  Future<ActivityBatchCreateResult> createActivitiesWithAssignments(
    List<ActivityCreateRequest> requests, {
    required UserSessionState actor,
  }) {
    return db.transaction(() async {
      if (!actor.isAdmin) {
        throw const AuthorizationException(
          'Toplu faaliyet içe aktarma yalnızca yöneticilere açıktır.',
        );
      }
      final ids = <int>[];
      final skipped = <({int personelId, String date, String activity})>[];
      var addedCount = 0;
      var alreadyAssignedCount = 0;

      for (final request in requests) {
        // Check if an activity already exists for request.tarih
        final existingActivity = await (db.select(db.gunlukFaaliyetTable)
              ..where((tbl) => tbl.tarih.equals(request.tarih)))
            .getSingleOrNull();

        int activityId;
        if (existingActivity != null) {
          activityId = existingActivity.id;
        } else {
          activityId = await db.into(db.gunlukFaaliyetTable).insert(
                GunlukFaaliyetTableCompanion.insert(
                  faaliyetAdi: request.faaliyetAdi,
                  tarih: request.tarih,
                  olusturmaTarihi: DateTime.now().toIso8601String(),
                  olusturanKullanici: request.olusturanKullanici,
                ),
              );
        }
        ids.add(activityId);

        final mergeResult = await mergePersonnelAssignmentsToActivity(
          activityId: activityId,
          personnelAssignments: request.personnelAssignments,
          actor: actor,
          updateDifferentAssignments: false,
        );

        addedCount += mergeResult.addedCount;
        alreadyAssignedCount += mergeResult.skippedCount;
      }

      return ActivityBatchCreateResult(
        activityIds: ids,
        addedAssignmentCount: addedCount,
        alreadyAssignedCount: alreadyAssignedCount,
        skippedAssignmentCount: skipped.length,
      );
    });
  }
```

- [ ] **Step 2: Run test to verify smart re-import tests pass**

Run: `flutter test test/unit/smart_reimport_test.dart`

---

### Task 4: Update `BulkImportDialog` for Smart Re-Import & Delta Feedback

**Files:**
- Modify: `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart`

- [ ] **Step 1: Update import fingerprint check and dialog UI in `_saveAllToFaaliyet()`**

In `_saveAllToFaaliyet()`:
```dart
final learningService = BulkImportLearningService(widget.database);
final fingerprint = BulkImportLearningService.fingerprint(_parsedBlocks);
final existingImport = await learningService.findImport(fingerprint);

if (existingImport != null) {
  final activeCount = await learningService.countActiveAssignments(_parsedBlocks);
  if (activeCount == 0) {
    // Stale import record (activities were deleted), clean it up and proceed smoothly
    await learningService.deleteImportRecord(fingerprint);
  } else {
    if (!mounted) return;
    final userChoice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bu Liste Daha Önce Aktarıldı'),
        content: Text(
          '${existingImport.tarihler} tarihli bu içerik '
          '${existingImport.kayitTarihi} tarihinde '
          '${existingImport.aktaranKullanici} tarafından kaydedilmiş.\n\n'
          'Veritabanında $activeCount personel kaydı hala aktif duruyor. '
          'Eksik olanları tamamlamak veya yeniden güncellemek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('EKSİKLERİ TAMAMLA / YENİDEN AKTAR'),
          ),
        ],
      ),
    );
    if (userChoice != true) return;
  }
}
```

Update completion summary dialog content:
```dart
content: Text(
  '${preparation.requests.length} günlük faaliyet işlendi.\n'
  '${result.addedAssignmentCount} yeni personel eklendi.\n'
  '${result.alreadyAssignedCount} personel zaten o görevde ekliydi.\n'
  '$_deduplicatedPersonnelCount tekrar tekilleştirildi.\n'
  '${result.skippedAssignmentCount} çakışan kayıt atlandı.',
)
```

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: ALL tests pass with 0 errors.

---

## Verification Plan

### Automated Tests
- `flutter test test/unit/smart_reimport_test.dart`
- `flutter test test/unit/bulk_import_learning_service_test.dart`
- `flutter test test/features/activity/bulk_import_save_button_test.dart`
- `flutter test`

### Manual Verification
- In the app, bulk import a duty list (e.g. 9/B Gülüşkür).
- Delete the created activity from the Faaliyetler screen.
- Re-paste the exact same text in **Metinden Toplu Aktarım** and click Save.
- Verify that it imports cleanly without blocking error.
- Partially delete 2 personnel from an activity, re-paste the text, click **[EKSİKLERİ TAMAMLA / YENİDEN AKTAR]**, and verify only the missing 2 personnel are added while existing ones are preserved.
