# Implementation Plan: Optimize Outer Layout to Maximize Personnel Viewport

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Maximize the vertical viewport area for personnel cards on the bulk import preview screen by converting top fixed header widgets (stat cards, title, error banner) into scrollable slivers/header items and condensing stat cards into a slim, space-efficient layout.

**Architecture:** 
1. **Compact Summary Header (`bulk_import_stat_cards.dart`):** Create a slim 1-line summary chip option (`📋 19 Kart  •  👥 150 Personel  •  📅 5 Gün`) while keeping full stat cards responsive and compact.
2. **Scrollable Header Integration (`bulk_import_dialog.dart`):** Refactor `_buildPreviewSection` to include top header elements (Title, Stat Bar, Error Summary) inside a unified `CustomScrollView` (or `ListView` header). When the user scrolls the list, top header elements scroll up and out of view, freeing **100% of screen height for personnel cards**.

**Tech Stack:** Flutter / Dart, CustomScrollView / Slivers, Material 3 Design

---

## Proposed Changes

### Component 1: Compact Summary Header & Stat Cards
#### [MODIFY] [bulk_import_stat_cards.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import/bulk_import_stat_cards.dart)
- Add a compact 1-line `BulkImportCompactStatBar` widget (`📋 19 Kart  •  👥 150 Personel  •  📅 5 Gün`) to replace tall 90px vertical cards on smaller screens or scrollable headers.

### Component 2: Unified Scrollable Layout
#### [MODIFY] [bulk_import_dialog.dart](file:///c:/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import_dialog.dart)
- Move header widgets (Title row, Stat cards, Error summary) into the scrollable body so they scroll away when scrolling through personnel cards.
- Give `ListView` / `CustomScrollView` full vertical screen height when scrolling down.

---

## Tasks

### Task 1: Create Compact Stat Header Bar

**Files:**
- Modify: `c/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import/bulk_import_stat_cards.dart`
- Test: `c/Users/baba/personelapp2/test/features/activity/bulk_import_wizard_test.dart`

- [ ] **Step 1: Implement BulkImportCompactStatBar widget**
- [ ] **Step 2: Verify compilation and tests**
- [ ] **Step 3: Commit changes**

---

### Task 2: Integrate Headers into Scrollable Viewport

**Files:**
- Modify: `c/Users/baba/personelapp2/lib/features/activity/presentation/dialogs/bulk_import_dialog.dart`
- Test: `c/Users/baba/personelapp2/test/features/activity/bulk_import_wizard_test.dart`

- [ ] **Step 1: Refactor _buildPreviewSection to use CustomScrollView with Slivers or Header ListView**
- [ ] **Step 2: Run all widget tests to ensure scrolling, navigation, and error drawer work**
- [ ] **Step 3: Commit changes**

---

## Verification Plan

### Automated Tests
- Run `flutter test` across all unit and widget tests.

### Manual Verification
- Test bulk import preview with 19 cards / 150 personnel:
  1. Verify top headers scroll away when scrolling down the personnel list.
  2. Verify 5-7 personnel items are visible at once when scrolled.
  3. Verify "Soruna Git" error navigation still scrolls accurately to target problem card.
