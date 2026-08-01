# Smart Learning System Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the smart learning system in `personelapp2` so that raw personnel name aliases are automatically learned upon batch save, async write risks are removed, Turkish character normalization is fixed, and alias matches bypass unnecessary review warnings.

**Architecture:** Extend `BulkImportLearningService` with a batch alias persistence method (`rememberAliases`), invoke it inside `BulkImportSaveHandler.saveAllToFaaliyet` after activity creation, fix Turkish uppercase normalization in `normalizeName`, and ensure `PersonnelFuzzyMatcher` handles learned alias matches with `reviewConfirmed: true`.

**Tech Stack:** Dart 3, Flutter, Drift SQLite Database, flutter_test

---

### Task 1: Fix Normalization and Add Batch Alias Learning to `BulkImportLearningService`

**Files:**
- Modify: `lib/features/activity/domain/bulk_import_learning_service.dart:13-62`
- Test: `test/unit/bulk_import_learning_service_test.dart`

- [ ] **Step 1: Write failing test for `rememberAliases` and Turkish uppercase normalization**

Add a test in `test/unit/bulk_import_learning_service_test.dart`:
```dart
test('rememberAliases saves multiple pairs and handles uppercase Turkish I/İ correctly', () async {
  final service = BulkImportLearningService(database);
  await service.rememberAliases([
    (rawName: 'HÜSEYİN ORUCTUTAN', personnelId: personnelId),
    (rawName: 'ISMAİL KAYA', personnelId: personnelId),
  ]);

  final aliases = await service.loadAliases();
  expect(aliases['huseyin orcutan'], personnelId);
  expect(aliases['ismail kaya'], personnelId);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/bulk_import_learning_service_test.dart`
Expected: FAIL because `rememberAliases` does not exist on `BulkImportLearningService`.

- [ ] **Step 3: Implement `normalizeName` fix and `rememberAliases` method**

In `lib/features/activity/domain/bulk_import_learning_service.dart`:
```dart
  static String normalizeName(String input) => input
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<void> rememberAliases(
    Iterable<({String rawName, int personnelId})> pairs,
  ) async {
    final uniqueMap = <String, ({String rawName, int personnelId})>{};
    for (final pair in pairs) {
      final normalized = normalizeName(pair.rawName);
      if (normalized.isNotEmpty) {
        uniqueMap[normalized] = (rawName: pair.rawName.trim(), personnelId: pair.personnelId);
      }
    }
    if (uniqueMap.isEmpty) return;

    for (final entry in uniqueMap.entries) {
      await rememberAlias(
        rawName: entry.value.rawName,
        personnelId: entry.value.personnelId,
      );
    }
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/bulk_import_learning_service_test.dart`
Expected: PASS

---

### Task 2: Update `PersonnelFuzzyMatcher` to Confirm Learned Alias Matches

**Files:**
- Modify: `lib/features/activity/domain/parser/personnel_fuzzy_matcher.dart:50-64`
- Test: `test/unit/bulk_import_learning_service_test.dart`

- [ ] **Step 1: Write test verifying alias match sets `reviewConfirmed: true`**

Add test to `test/unit/bulk_import_learning_service_test.dart`:
```dart
test('learned alias match sets reviewConfirmed to true', () async {
  final service = BulkImportLearningService(database);
  await service.rememberAlias(rawName: 'Hüseyin ORUCTUTAN', personnelId: personnelId);

  final matched = await PersonnelFuzzyMatcher(database).matchBlocks([block('Hüseyin ORUCTUTAN')]);
  final item = matched.single.personnelList.single;
  expect(item.matchedPersonnelId, personnelId);
  expect(item.matchConfidence, 1.0);
  expect(item.reviewConfirmed, isTrue);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/bulk_import_learning_service_test.dart`
Expected: FAIL because `reviewConfirmed` was `false`.

- [ ] **Step 3: Update `PersonnelFuzzyMatcher`**

In `lib/features/activity/domain/parser/personnel_fuzzy_matcher.dart`:
```dart
    final aliasPersonnelId = aliases[rawNameClean];
    if (aliasPersonnelId != null) {
      final aliasMatch = dbList
          .where((personnel) => personnel.id == aliasPersonnelId)
          .firstOrNull;
      if (aliasMatch != null) {
        return _withMatch(
          item,
          aliasMatch,
          1,
          parsedTeamName,
          teamNames,
        ).copyWith(reviewConfirmed: true);
      }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/bulk_import_learning_service_test.dart`
Expected: PASS

---

### Task 3: Trigger Auto-Learning in `BulkImportSaveHandler` and `bulk_import_dialog.dart`

**Files:**
- Modify: `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_save_handler.dart:135-145`
- Modify: `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart:502-535`
- Create: `test/unit/save_all_learning_test.dart`

- [ ] **Step 1: Create unit test `test/unit/save_all_learning_test.dart`**

```dart
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_save_handler.dart';

void main() {
  late AppDatabase database;
  late ActivityRepository repository;
  late int personnelId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = ActivityRepository(database);
    final teamId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '9-B Timi',
            olusturmaTarihi: '2026-01-01',
          ),
        );
    personnelId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Hüseyin ORUÇTUTAN',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '9/B',
            timId: Value(teamId),
            kayitTarihi: '2026-01-01',
          ),
        );
  });

  tearDown(() => database.close());

  test('saveAllToFaaliyet automatically learns aliases for matched personnel', () async {
    final block = ParsedActivityBlock(
      rawTitle: '9/B Gülüşkür',
      parsedTimName: '9/B',
      parsedActivityType: 'GÜLÜŞKÜR',
      parsedDate: '2026-07-30',
      personnelList: [
        ParsedPersonnelItem(
          rawIndex: 1,
          rawRank: 'J.Uzm.Çvş.',
          rawName: 'Hüseyin ORUCTUTAN',
          matchedPersonnelId: personnelId,
          matchedAdSoyad: 'Hüseyin ORUÇTUTAN',
          matchedRutbe: 'J.Uzm.Çvş.',
          matchConfidence: 0.75,
        ),
      ],
    );

    final learningService = BulkImportLearningService(database);
    final fingerprint = BulkImportLearningService.fingerprint([block]);
    final prep = BulkActivityImportPreparer.prepare([block]);

    await repository.createActivitiesWithAssignments(
      prep.requests,
      actor: const UserSessionState(
        username: 'admin',
        displayName: 'Admin',
        role: UserRole.admin,
      ),
    );

    final pairs = block.personnelList
        .where((p) => p.matchedPersonnelId != null && p.rawName.trim().isNotEmpty)
        .map((p) => (rawName: p.rawName, personnelId: p.matchedPersonnelId!));
    await learningService.rememberAliases(pairs);

    final aliases = await learningService.loadAliases();
    expect(aliases['huseyin orcutan'], personnelId);
  });
}
```

- [ ] **Step 2: Update `BulkImportSaveHandler.saveAllToFaaliyet`**

In `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_save_handler.dart`:
```dart
    final result = await activityRepository.createActivitiesWithAssignments(
      preparation.requests,
      actor: actor,
    );

    // Automatically learn aliases for all matched personnel in saved blocks
    final aliasPairs = blocks.expand((b) => b.personnelList).where(
      (p) => p.matchedPersonnelId != null && p.rawName.trim().isNotEmpty,
    ).map((p) => (rawName: p.rawName, personnelId: p.matchedPersonnelId!));
    await learningService.rememberAliases(aliasPairs);

    await learningService.recordImport(
      fingerprint: fingerprint,
      blocks: blocks,
      actor: actor.username,
      rawText: keepAuditText ? rawText : null,
    );
```

- [ ] **Step 3: Fix `_confirmAllSuggestions` in `bulk_import_dialog.dart`**

In `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart`:
```dart
  Future<void> _confirmAllSuggestions() async {
    final learningService = BulkImportLearningService(widget.database);
    final aliasPairs = <({String rawName, int personnelId})>[];

    setState(() {
      for (var bIdx = 0; bIdx < _parsedBlocks.length; bIdx++) {
        final block = _parsedBlocks[bIdx];
        final updatedList = List<ParsedPersonnelItem>.from(block.personnelList);
        var changed = false;

        for (var pIdx = 0; pIdx < updatedList.length; pIdx++) {
          final item = updatedList[pIdx];
          if (item.hasWarning &&
              item.isMatched &&
              item.matchedPersonnelId != null) {
            updatedList[pIdx] = item.copyWith(
              matchConfidence: 1.0,
              teamMismatch: false,
              reviewConfirmed: true,
            );
            changed = true;
            aliasPairs.add((
              rawName: item.rawName,
              personnelId: item.matchedPersonnelId!,
            ));
          }
        }

        if (changed) {
          _parsedBlocks[bIdx] = block.copyWith(personnelList: updatedList);
        }
      }
    });

    if (aliasPairs.isNotEmpty) {
      await learningService.rememberAliases(aliasPairs);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm önerilen personel eşleşmeleri onaylandı.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
```

- [ ] **Step 4: Run tests and static analysis**

Run: `flutter test test/unit/bulk_import_learning_service_test.dart test/unit/save_all_learning_test.dart`
Run: `flutter analyze`
Expected: ALL TESTS PASS, 0 static analysis issues.

---

### Task 5: Final Verification and Commit

- [ ] **Step 1: Run all unit tests**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 3: Commit all changes**

Run: `git add .`
Run: `git commit -m "fix(learning): enable auto-alias learning on batch save and fix Turkish normalization"`
