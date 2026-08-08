# Tim Kartı Çözümleme ve Veri Bütünlüğü (Team Card Resolution) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the team card identity resolution issue by propagating team IDs through the DTO pipeline, creating a `TeamActivityCard` aggregate root with invariant enforcement, and updating database mappings.

**Architecture:** Domain-Driven Design (DDD) Aggregate Root with Factory Methods for `TeamActivityCard`, updated `PersonnelAssignmentInput` DTO carrying `teamId`, and updated `BulkActivityImportPreparer` & `PersonnelFuzzyMatcher` logic.

**Tech Stack:** Dart, Flutter, Drift (SQLite database), `package:test`.

---

## Tasks

### Task 1: Update DTOs to carry `teamId`

**Files:**
- Modify: `lib/features/activity/domain/models/activity_create_request.dart`

- [ ] **Step 1: Add `teamId` field to `PersonnelAssignmentInput`**

```dart
class PersonnelAssignmentInput {
  const PersonnelAssignmentInput({
    required this.personnelId,
    required this.duty,
    this.note,
    this.teamId,
  });

  final int personnelId;
  final String duty;
  final String? note;
  final int? teamId;
}
```

- [ ] **Step 2: Run static analysis**

Run: `dart analyze lib/features/activity/domain/models/activity_create_request.dart`
Expected: No errors.

- [ ] **Step 3: Commit DTO changes**

```bash
git add lib/features/activity/domain/models/activity_create_request.dart
git commit -m "feat: add teamId field to PersonnelAssignmentInput DTO"
```

---

### Task 2: Implement `TeamActivityCard` Aggregate Root with Factory Method

**Files:**
- Create: `lib/features/activity/domain/models/team_activity_card.dart`
- Create: `test/features/activity/team_activity_card_test.dart`

- [ ] **Step 1: Write failing test for `TeamActivityCard` domain invariant**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/models/team_activity_card.dart';

void main() {
  group('TeamActivityCard Aggregate Root', () {
    test('should reject creation when teamId or teamName is empty', () {
      final result = TeamActivityCard.create(
        teamId: null,
        teamName: '',
        date: '2026-08-09',
        activityType: 'Nöbet',
        assignments: [],
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Tim kimliği ve adı zorunludur'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity/team_activity_card_test.dart`
Expected: FAIL (File/class does not exist yet)

- [ ] **Step 3: Implement `TeamActivityCard` with Factory Method**

```dart
class TeamActivityCardResult<T> {
  final T? value;
  final String? error;
  final bool isSuccess;

  const TeamActivityCardResult.success(this.value)
      : error = null,
        isSuccess = true;

  const TeamActivityCardResult.failure(this.error)
      : value = null,
        isSuccess = false;
}

class TeamActivityCard {
  final String id;
  final int teamId;
  final String teamName;
  final String date;
  final String activityType;

  TeamActivityCard._({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.date,
    required this.activityType,
  });

  static TeamActivityCardResult<TeamActivityCard> create({
    required int? teamId,
    required String teamName,
    required String date,
    required String activityType,
    required List<dynamic> assignments,
  }) {
    if (teamId == null || teamName.trim().isEmpty) {
      return const TeamActivityCardResult.failure(
        'Tim kimliği ve adı zorunludur',
      );
    }
    return TeamActivityCardResult.success(
      TeamActivityCard._(
        id: '${date}_$teamId',
        teamId: teamId,
        teamName: teamName,
        date: date,
        activityType: activityType,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity/team_activity_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit `TeamActivityCard` implementation**

```bash
git add lib/features/activity/domain/models/team_activity_card.dart test/features/activity/team_activity_card_test.dart
git commit -m "feat: add TeamActivityCard aggregate root with factory method invariants"
```

---

### Task 3: Update `BulkActivityImportPreparer` to propagate `teamId`

**Files:**
- Modify: `lib/features/activity/domain/bulk_activity_import_preparer.dart`
- Modify: `test/features/activity/bulk_activity_import_preparer_test.dart`

- [ ] **Step 1: Update `BulkActivityImportPreparer.prepare` to set `teamId`**

In `lib/features/activity/domain/bulk_activity_import_preparer.dart`:

```dart
payload.add(
  PersonnelAssignmentInput(
    personnelId: item.person.matchedPersonnelId!,
    duty: item.block.parsedActivityType,
    note: note,
    teamId: item.person.matchedTimId,
  ),
);
```

- [ ] **Step 2: Run unit test to verify preparation**

Run: `flutter test test/features/activity/bulk_activity_import_preparer_test.dart`
Expected: PASS

- [ ] **Step 3: Commit preparer changes**

```bash
git add lib/features/activity/domain/bulk_activity_import_preparer.dart
git commit -m "feat: propagate matchedTimId into PersonnelAssignmentInput in BulkActivityImportPreparer"
```

---

### Task 4: Enhance `PersonnelFuzzyMatcher` team inference & fallback

**Files:**
- Modify: `lib/features/activity/domain/parser/personnel_fuzzy_matcher.dart`
- Test: `test/features/activity/bulk_import_team_fallback_test.dart`

- [ ] **Step 1: Add robust fallback when inferring team names from personnel**

In `lib/features/activity/domain/parser/personnel_fuzzy_matcher.dart` (lines 35-47): Ensure that if personnel match to a team, the block's `parsedTimName` is consistently assigned or defaulted cleanly without leaving invalid state.

- [ ] **Step 2: Run fallback test**

Run: `flutter test test/features/activity/bulk_import_team_fallback_test.dart`
Expected: PASS

- [ ] **Step 3: Commit matcher changes**

```bash
git add lib/features/activity/domain/parser/personnel_fuzzy_matcher.dart
git commit -m "fix: improve team name inference and fallback resolution in PersonnelFuzzyMatcher"
```

---

### Task 5: Run full test suite to verify overall integrity

**Files:**
- Test: All files in `test/features/activity/`

- [ ] **Step 1: Execute all activity tests**

Run: `flutter test test/features/activity/`
Expected: All tests PASS.

- [ ] **Step 2: Commit final verification checkpoint**

```bash
git commit --allow-empty -m "chore: verify all activity domain tests pass"
```
