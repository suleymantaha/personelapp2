# Implementation Plan: Modularize `bulk_import_dialog.dart`

**Goal:** Refactor `bulk_import_dialog.dart` by extracting large inline UI methods into modular, testable sub-widgets inside `lib/features/activity/presentation/dialogs/bulk_import/`.

---

## Proposed Changes

### Component: Sub-widgets Extraction (`lib/features/activity/presentation/dialogs/bulk_import/`)

#### [NEW] [activity_block_card.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart)
- Move `_buildPreviewCard` & `_MetadataLabel` (~250 lines) into `ActivityBlockCard`.

#### [NEW] [bulk_import_input_section.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import/bulk_import_input_section.dart)
- Move `_buildInputSection` (~110 lines) into `BulkImportInputSection`.

#### [NEW] [bulk_import_confirm_section.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import/bulk_import_confirm_section.dart)
- Move `_buildConfirmStep` (~80 lines) into `BulkImportConfirmSection`.

#### [NEW] [bulk_import_empty_state.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import/bulk_import_empty_state.dart)
- Move `_buildFilteredEmptyState` (~50 lines) into `BulkImportEmptyState`.

#### [MODIFY] [bulk_import_dialog.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import_dialog.dart)
- Replace inline UI methods with the new extracted modular sub-widgets.
- Reduces `bulk_import_dialog.dart` size from ~1576 lines down to under 500 lines.

---

## Tasks

- [ ] **Task 1: Create `activity_block_card.dart`**
- [ ] **Task 2: Create `bulk_import_input_section.dart`**
- [ ] **Task 3: Create `bulk_import_confirm_section.dart` & `bulk_import_empty_state.dart`**
- [ ] **Task 4: Clean up `bulk_import_dialog.dart` and verify all 150 tests pass**

---

## Verification Plan

### Automated Tests
- Run full `flutter test` across all 150 unit/widget tests to guarantee zero regressions.

### Manual Verification
- Test all 3 steps in `BulkImportDialog` (Paste -> Preview -> Confirm & Save).
