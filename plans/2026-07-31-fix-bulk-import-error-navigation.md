# Implementation Plan: Fix Bulk Import Error Navigation & Target Tracking

**Goal:** Ensure "Soruna Git" (Go to Problem) accurately navigates directly to unresolved error cards/personnel, dynamically handles resolved issues without getting stuck, and scrolls precisely regardless of filter state.

---

## User Review Required

> [!IMPORTANT]
> **Key Enhancements:**
> 1. **Dynamic Index Clamping:** When a user resolves or deletes a problematic personnel, the problem list updates and `_activeIssueFocusIndex` automatically clamps to the remaining active problems without skipping or repeating resolved cards.
> 2. **Filter-Aware Scroll Offsets:** Computes scroll offsets based on visible blocks (`visibleBlocks.indexWhere(...)`) rather than total raw blocks, guaranteeing accurate scrolling when "Yalnızca Sorunlular" (Only Problems) filter is active.
> 3. **Person-Level Highlighting:** Sets `_focusedPersonKey` so the specific problematic personnel card highlights with an attention ring.

---

## Proposed Changes

### Component: Bulk Import Navigation (`bulk_import_dialog.dart`)

#### [MODIFY] [bulk_import_dialog.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import_dialog.dart)
- Update `_focusNextProblem()` and `_focusPreviousProblem()` to validate and clamp `_activeIssueFocusIndex` against fresh `_getProblemLocations()`.
- Update `_scrollToProblemLocation(int blockIndex)`:
  - Find `visibleIndex` in `visibleBlocks` (the currently displayed cards in `CustomScrollView`).
  - Calculate `estimatedOffset` using `visibleIndex` instead of raw `blockIndex`.
  - After scrolling to estimate, trigger `Scrollable.ensureVisible` for smooth mounting.

---

## Tasks

- [ ] **Task 1: Fix dynamic problem index tracking and filter-aware scrolling in `bulk_import_dialog.dart`**
  - Clamp `_activeIssueFocusIndex` when problem locations shrink.
  - Calculate scroll offset using `visibleBlocks` index.
- [ ] **Task 2: Verify with Widget Tests**
  - Run `flutter test` across all 150 tests to verify full regression safety.

---

## Verification Plan

### Automated Tests
- Run `flutter test test/features/activity/bulk_import_problem_filter_test.dart`
- Run full `flutter test`

### Manual Verification
1. Paste text with 3 unknown personnel.
2. Click "Soruna Git" -> Navigates to Problem 1.
3. Match/resolve Problem 1 -> Click "Soruna Git" -> Smoothly navigates to Problem 2 (does NOT repeat Problem 1).
4. Filter by "Yalnızca Sorunlular" -> Click "Soruna Git" -> Correctly scrolls to visible problem card without over-scrolling.
