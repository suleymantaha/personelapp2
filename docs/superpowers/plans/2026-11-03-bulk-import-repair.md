# Bulk Import Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Preserve roster workflow while eliminating OCR person loss and requiring explicit confirmation for past or more-than-three-day future imports.

**Architecture:** Keep parser, matching, staged persistence and transaction boundaries. Add one shared date-consent dialog to both save paths, retaining original source dates until the user accepts an existing target date. Team confirmation stays assignment-only.

**Tech Stack:** Flutter/Dart, Riverpod, Drift SQLite, existing MLKit.

**Spec:** `docs/superpowers/specs/2026-11-03-bulk-import-repair-design.md`

## Global Constraints

- No schema, role, conflict, membership or duty-duration changes.
- No uploaded real personnel data in tests, logs or commits.
- Past and >today+3 require explicit consent; today through +3 do not.
- Cancel is read-only; selected/confirmed date is the persisted date.
- No APK, production publish or main merge.

## Review Focus

- Date-only boundary at month/year changes and late local hours.
- Existing target date differs from one or many source dates.
- Cancel/dismiss/retry and session changes while dialogs await input.
- Split surnames versus standalone activity cells and rank-only noise.
- Partial/all-conflicting batches, existing card merges and inferred team labels.

### Task 1: OCR and person/header repair

**Files:** OCR extractor, personnel parser, new synthetic regression tests.
**Interfaces:** Existing `extract(String)` and `BulkTextParser.parse` unchanged.
- [x] Write tests for synthetic people, METİ column, rank-only and header noise, split surname preservation.
- [x] Run failing tests; apply local parser repair; rerun OCR/parser regressions.

### Task 2: Date consent and target visibility

**Files:** new date policy/dialog tests, import dialog actions, confirmation section/save handler.
**Interfaces:** `confirmImportDates(context, dates, targetDate?, now?) -> Future<bool>`; no persisted consent or database mutation.
- [x] Write boundary/cancel/approve tests and target-date discrepancy regression.
- [x] Run failing tests; implement shared confirmation before staging writes in both paths.
- [x] Make destination and partial/no-write outcome explicit, preserving grouping/merge semantics.
- [x] Run import/save/date regressions and full project suite when environment supports it.

### Task 3: Explicit team UX

**Files:** task team confirmation and edit block dialogs, focused tests.
**Interfaces:** Existing assignment snapshots and dialog return types unchanged.
- [x] Write inferred-team explicit-confirmation and bulk-team-apply tests.
- [x] Implement deliberate team confirmation and apply-all control without membership writes.
- [x] Run provenance/history/authority regressions.

### Task 4: Review and handoff

- [x] Review final diff independently and address substantive findings.
- [x] Run format, analyze, targeted/full tests; record real outcomes and environment limits.
- [x] Commit and push feature branch; do not merge or publish APK.
