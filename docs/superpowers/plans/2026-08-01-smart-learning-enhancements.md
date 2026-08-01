# Smart Learning Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a responsive Learned Aliases Management Dialog (`LearnedAliasesDialog`), visual memory badges in `PersonnelMatchCard`, and alias reset capabilities in `BulkImportDialog` and `PersonnelPicker`.

**Architecture:** Add `getAliasList` and `deleteAlias` queries to `BulkImportLearningService`, build `LearnedAliasesDialog` using Flutter Material 3 design and previews, show an `Icons.auto_awesome` badge for learned alias matches in `PersonnelMatchCard`, and link everything with unit & widget tests.

**Tech Stack:** Dart 3, Flutter, Drift SQLite, Flutter Widget Previews, flutter_test

---

### Task 1: Add Alias Query and Deletion Methods to `BulkImportLearningService`

**Files:**
- Modify: `lib/features/activity/domain/bulk_import_learning_service.dart`
- Test: `test/unit/bulk_import_learning_service_test.dart`

- [ ] **Step 1: Write failing unit test for `getAliasList` and `deleteAlias`**

Add test to `test/unit/bulk_import_learning_service_test.dart`:
```dart
test('getAliasList returns joined personnel details and deleteAlias removes entry', () async {
  final service = BulkImportLearningService(database);
  await service.rememberAlias(rawName: 'Hüseyin ORUCTUTAN', personnelId: personnelId);

  final list = await service.getAliasList();
  expect(list.length, 1);
  expect(list.first.gorunenTakmaAd, 'Hüseyin ORUCTUTAN');
  expect(list.first.personelAdSoyad, 'Hüseyin ORUÇTUTAN');

  await service.deleteAlias(list.first.id);
  final updatedList = await service.getAliasList();
  expect(updatedList.isEmpty, isTrue);
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/unit/bulk_import_learning_service_test.dart`
Expected: FAIL because `getAliasList` and `deleteAlias` do not exist.

- [ ] **Step 3: Implement `LearnedAliasItem`, `getAliasList`, and `deleteAlias`**

In `lib/features/activity/domain/bulk_import_learning_service.dart`:
```dart
class LearnedAliasItem {
  final int id;
  final String normalizeTakmaAd;
  final String gorunenTakmaAd;
  final int personnelId;
  final String personelAdSoyad;
  final String? personelRutbe;

  const LearnedAliasItem({
    required this.id,
    required this.normalizeTakmaAd,
    required this.gorunenTakmaAd,
    required this.personnelId,
    required this.personelAdSoyad,
    this.personelRutbe,
  });
}
```

Add methods to `BulkImportLearningService`:
```dart
  Future<List<LearnedAliasItem>> getAliasList() async {
    final query = database.select(database.personelIsimTakmaAdTable).join([
      innerJoin(
        database.personelTable,
        database.personelTable.id.equalsExp(
          database.personelIsimTakmaAdTable.personelId,
        ),
      ),
    ]);
    final rows = await query.get();
    return rows.map((row) {
      final alias = row.readTable(database.personelIsimTakmaAdTable);
      final person = row.readTable(database.personelTable);
      return LearnedAliasItem(
        id: alias.id,
        normalizeTakmaAd: alias.normalizeTakmaAd,
        gorunenTakmaAd: alias.gorunenTakmaAd,
        personnelId: alias.personelId,
        personelAdSoyad: person.adSoyad,
        personelRutbe: person.rutbe,
      );
    }).toList();
  }

  Future<void> deleteAlias(int aliasId) async {
    await (database.delete(database.personelIsimTakmaAdTable)
          ..where((table) => table.id.equals(aliasId)))
        .go();
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/bulk_import_learning_service_test.dart`
Expected: PASS

---

### Task 2: Create `LearnedAliasesDialog` Component with Widget Previews

**Files:**
- Create: `lib/features/activity/presentation/dialogs/bulk_import/learned_aliases_dialog.dart`

- [ ] **Step 1: Implement `LearnedAliasesDialog`**

Create `lib/features/activity/presentation/dialogs/bulk_import/learned_aliases_dialog.dart`:
A responsive dialog displaying learned aliases with search bar, count badge, delete confirmation, and empty state.

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze`
Expected: PASS

---

### Task 3: Add Memory Badge to `PersonnelMatchCard` & Link Dialog in Preview Section

**Files:**
- Modify: `lib/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart`
- Modify: `lib/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart`
- Modify: `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_preview_section.dart`
- Modify: `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart`

- [ ] **Step 1: Add learned alias badge in `PersonnelMatchCard`**

In `lib/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart`:
Display `Icons.auto_awesome` badge when `item.reviewConfirmed && item.matchConfidence == 1.0` with tooltip "Hafızadan otomatik eşleşti".

- [ ] **Step 2: Add Hafıza button in `BulkImportPreviewSection`**

Add `onOpenLearnedAliases` action button to open `LearnedAliasesDialog`.

- [ ] **Step 3: Run `flutter analyze`**

Run: `flutter analyze`
Expected: PASS

---

### Task 4: Create Widget Test for `LearnedAliasesDialog` and Final Verification

**Files:**
- Create: `test/unit/learned_aliases_dialog_test.dart`

- [ ] **Step 1: Create widget test `test/unit/learned_aliases_dialog_test.dart`**

Verify listing, searching, deleting, and empty state in `LearnedAliasesDialog`.

- [ ] **Step 2: Run all tests and static analysis**

Run: `flutter test`
Run: `flutter analyze`
Expected: ALL PASS, 0 static analysis errors.

- [ ] **Step 3: Auto Git Flow Commit and Push**

Commit and push to remote repository.
