# Implementation Plan: Personnel Name Visibility & Error Navigation Fix

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance personnel name visibility, typography, and layout in the bulk import preview cards so names are prominent and easy to scan, while fixing the "Soruna Git" (error navigation) feature so clicking it accurately scrolls to and highlights problem cards.

**Architecture:** 
1. **Name & Card Typography Redesign (`personnel_match_card.dart`):** Refactor `PersonnelMatchCard` into a clean, high-contrast, compact 2-row layout. Render rütbe (rank) in a styled badge, raw name in bold 16px typography, and matched DB personnel prominently with clear green/orange/red status indicators.
2. **Error Navigation & Scroll Fix (`bulk_import_dialog.dart`):** Bind `GlobalKey`s to `_cardKeys` for every `_buildPreviewCard` and calculate reliable scroll offsets using card indices and `Scrollable.ensureVisible` after expanding cards if needed. Include parse issues in the problem location list.

**Tech Stack:** Flutter / Dart, Riverpod, Material 3 Design

---

## Proposed Changes

### Component 1: Personnel Name Visibility & Typography
#### [MODIFY] [personnel_match_card.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart)
- Upgrade `PersonnelMatchCard` layout to prioritize personnel name legibility.
- Show Rank in a styled chip/badge (e.g. `J.Bçvş.`) and Raw Name in bold 16px text (`AHMET TINAS`).
- Show Matched DB Person directly on the main card body in bold dark text with team badge and match status (`✓ Eşleşti: J.Bçvş. Ahmet TINAS`).
- Reduce excessive vertical padding and remove redundant dividers so 3-4 personnel cards fit on a single mobile screen height.

### Component 2: Error Navigation & Scroll System
#### [MODIFY] [bulk_import_dialog.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import_dialog.dart)
- Pass `key: _cardKeys.putIfAbsent(originalBlockIndex, () => GlobalKey())` to `_buildPreviewCard` so card keys are properly attached to the widget tree.
- In `_scrollToProblemLocation(int blockIndex)`, handle lazy list bounds by scrolling `_previewScrollController` to the estimated item position if the item key context is off-screen, then calling `Scrollable.ensureVisible`.
- Enhance `_getProblemLocations()` to correctly incorporate parse issues, unmatched personnel, and duplicate warnings.

---

## Tasks

### Task 1: Redesign PersonnelMatchCard for High Legibility & Compact Scanning

**Files:**
- Modify: `c/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart`
- Test: `c/Users/baba/personelapp2/test/features/activity/bulk_import_wizard_test.dart`

- [ ] **Step 1: Update PersonnelMatchCard layout for prominent names and compact vertical height**
- [ ] **Step 2: Run widget tests to verify PersonnelMatchCard renders correctly**
- [ ] **Step 3: Commit changes**

---

### Task 2: Fix Error Navigation ("Soruna Git") Keys and Scroll Mechanism

**Files:**
- Modify: `c/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import_dialog.dart`
- Test: `c/Users/baba/personelapp2/test/features/activity/bulk_import_wizard_test.dart`

- [ ] **Step 1: Attach GlobalKey to preview cards in ListView.builder**
- [ ] **Step 2: Fix _scrollToProblemLocation to handle off-screen items cleanly**
- [ ] **Step 3: Run widget tests to verify "Soruna Git" scrolls and focuses the problem card**
- [ ] **Step 4: Commit changes**

---

## Verification Plan

### Automated Tests
- Run `flutter test` across all unit and widget tests to ensure 100% pass rate.

### Manual Verification
- Test text import with 19 cards / 150 personnel:
  1. Verify personnel names are large, clear, bold, and easy to read.
  2. Verify multiple personnel fit on screen simultaneously.
  3. Tap "Soruna Git" and verify it smoothly scrolls to and highlights the target problem card.
