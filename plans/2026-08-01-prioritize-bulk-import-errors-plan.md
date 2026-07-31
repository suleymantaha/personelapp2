# Implementation Plan: Prioritize Critical Errors & Fix Problem Location Ordering

**Goal:** Ensure "Soruna Git" (Go to Problem) navigation prioritizes **critical blocking errors** (empty activity cards with 0 personnel, completely unmatched personnel) BEFORE secondary issues (duplicate personnel across time slots), and accurately displays problem counters.

---

## User Review Required

> [!IMPORTANT]
> **Key Architectural Enhancements:**
> 1. **Prioritized Problem Ordering:** `_getProblemLocations()` will sort problem locations by criticality:
>    - **Priority 1 (Critical Blocking):** Empty activity blocks (`0 personel`).
>    - **Priority 2 (High):** Personnel needing match review (`needsReview`).
>    - **Priority 3 (Secondary):** Duplicate personnel across shifts/time slots (`duplicates`).
> 2. **Accurate Counter Display:** Ensure `SmartSaveBar` displays the exact current problem position and total problem count (e.g. `1/5` instead of `1/1`).

---

## Proposed Changes

### Component: Navigation & Sorting Logic (`bulk_import_dialog.dart`)

#### [MODIFY] [bulk_import_dialog.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import_dialog.dart)
- Update `_getProblemLocations()`:
  - Collect empty blocks first.
  - Collect unmatched/needsReview personnel second.
  - Collect duplicate personnel third.
- Ensure `_scrollToProblemLocation()` scrolls to the highest priority issue immediately when "Soruna Git" is clicked.

---

## Tasks

- [ ] **Task 1: Re-order `_getProblemLocations()` by issue severity**
  - Sort empty cards (`0 personnel`) -> unmatched personnel (`needsReview`) -> duplicates.
- [ ] **Task 2: Verify with Unit & Widget Tests**
  - Run `flutter test test/features/activity/bulk_import_problem_filter_test.dart`.
  - Run full `flutter test`.

---

## Verification Plan

### Automated Tests
- Run `flutter test test/features/activity/bulk_import_problem_filter_test.dart`
- Run full `flutter test`

### Manual Verification
1. Paste multi-shift text containing duplicate personnel + an empty block (`1/B GÖREVLİ 0 personel`).
2. Click "Soruna Git" -> System MUST navigate directly to the empty block `1/B GÖREVLİ` FIRST.
3. Fix or delete the empty block -> Click "Soruna Git" -> System navigates to unmatched personnel next.
