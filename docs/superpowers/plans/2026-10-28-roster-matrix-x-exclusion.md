# Roster Matrix X Exclusion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize the combined output preview and add an optional rank-ordered output that excludes selected personnel with more than 20 visible monthly `X` days.

**Architecture:** Keep selected-card rows and existing normal/rank exports intact. Read the selected date's month through the existing authorized matrix repository; apply a pure filter to the selected rows and then the existing rank sorter. Revalidate both selected-card rows and matrix result before exporting the rule preview.

**Tech Stack:** Flutter, Riverpod, Drift, existing MatrixDayCell and roster exporters.

**Spec:** Approved visual mockup `C:/Users/baba/.codex/generated_images/01a16b3a-7e1c-7751-82b9-d7c2730c6e6a/exec-33bd1c34-260c-488d-bc8a-16f04723476d.png` and user clarification: 20 X stays, 21+ X is excluded; remaining people retain rank seniority.

## Global Constraints

- First selection screen, stored assignments, normal export and existing rank export remain unchanged.
- Count distinct matrix days with `displayCode == 'X'` in the month of the selected date; `B`, leave and other marks do not count.
- Rule output includes only selected-card personnel with at most 20 X days and orders them by existing rank weight, stable within equal ranks.
- Missing matrix authorization or load failure blocks the rule path; no silent inclusion.
- No APK, Drive upload, commit or push in this task.

## Review Focus

- Exactly 20 vs 21 X days and duplicate assignments on one day.
- Matrix scope for commander and selected month.
- Matrix changed between preview and export.
- Empty result after exclusions.
- Narrow mobile layout and existing export/signature interactions.

---

### Task 1: Rule service

- [x] Add failing unit tests for threshold, display code, stable rank, copying and empty result.
- [x] Implement pure selected-row filter in `lib/features/activity/services/roster_matrix_x_rule.dart`.
- [x] Run focused unit tests.

### Task 2: Screen and export flow

- [x] Add failing widget tests for the rule preview, Excel result, stale matrix block and unchanged normal/rank buttons.
- [x] Add authorized matrix loading and rule preview/export state to the combined preview screen.
- [x] Add the approved summary, selected-card summary, rule card and compact personnel list with localized copy.
- [x] Run focused widget and existing roster tests at normal and narrow viewports.

### Task 3: Acceptance

- [x] Generate localization, format, analyze, run relevant tests and inspect diff.
- [x] Capture Flutter screen where feasible and compare against the mockup. Test screenshot lacked text glyphs; layout and viewport tests passed.
- [x] Get independent read-only review of behavior, authorization and regressions. Reviewer found signer readiness gap; fixed and tested.
