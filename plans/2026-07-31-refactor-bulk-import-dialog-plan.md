# Refactor Monolithic `bulk_import_dialog.dart` into Modular Components

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decompose the 2427-line monolithic `bulk_import_dialog.dart` into focused, reusable, and easy-to-maintain sub-widgets in a dedicated `bulk_import` directory.

**Architecture:** Create `lib/features/activity/presentation/dialogs/bulk_import/` containing modular widgets (`bulk_import_stepper.dart`, `compact_error_summary.dart`, `smart_save_bar.dart`, `personnel_match_card.dart`, `activity_block_card.dart`, `duplicate_personnel_dialog.dart`). Keep state management and coordinator logic in `bulk_import_dialog.dart` reduced to ~350 lines.

**Tech Stack:** Flutter, Dart, Riverpod, Drift ORM.

---

## Proposed Structure

```
lib/features/activity/presentation/dialogs/
├── bulk_import_dialog.dart                         # Main Container & Coordinator (~350 lines)
└── bulk_import/
    ├── bulk_import_stepper.dart                    # Stepper header bar
    ├── bulk_import_stat_cards.dart                 # Stat summary cards
    ├── compact_error_summary.dart                  # Error summary banner & dropdown drawer
    ├── smart_save_bar.dart                         # Bottom action bar & save button
    ├── personnel_match_card.dart                   # Individual personnel row with fuzzy match tags
    ├── activity_block_card.dart                    # Activity block card (title, date, time range, personnel list)
    └── duplicate_personnel_dialog.dart             # Duplicate personnel alert dialog
```

---

## Tasks

### Task 1: Create Dedicated `bulk_import` Sub-Widgets

- [ ] Extract `_BulkImportStepper` -> `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_stepper.dart`
- [ ] Extract `_StatCard` -> `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_stat_cards.dart`
- [ ] Extract `_CompactErrorSummary` -> `lib/features/activity/presentation/dialogs/bulk_import/compact_error_summary.dart`
- [ ] Extract `_SmartSaveBar` & `BulkImportSaveButton` -> `lib/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart`
- [ ] Extract `_PersonnelMatchCard` -> `lib/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart`
- [ ] Extract `_ActivityBlockCard` -> `lib/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart`
- [ ] Extract `_showDuplicatePersonnelDialog` -> `lib/features/activity/presentation/dialogs/bulk_import/duplicate_personnel_dialog.dart`

### Task 2: Simplify `bulk_import_dialog.dart` Coordinator

- [ ] Import modular sub-widgets into `bulk_import_dialog.dart`.
- [ ] Clean up redundant code and keep file concise (~350 lines).

### Task 3: Verify All Unit & Widget Test Suites

- [ ] Run `flutter test` to ensure 100% passing tests and zero regressions.

---

## Verification Plan

### Automated Tests
- `flutter test`
- `flutter test test/features/activity/bulk_import_problem_filter_test.dart`

### Manual Verification
- Verify bulk import dialog renders identically and functions cleanly.
