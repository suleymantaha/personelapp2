# Monthly Analytics Implementation Plan

> For agentic workers: implement the approved monthly design with bounded native workers and one independent final review. Preserve all pre-existing changes; no commit, push, migration or release.

**Goal:** Monthly summary, daily assignments, team-duty matrix and editable XLSX charts share one immutable report.
**Architecture:** Build MonthlyAnalyticsReport from the already authorized TeamAnalytics snapshot. Include authorized unknown-team entries in overall counts, never infer historical teams from current membership. Count assignments by sourceDate, not derived two-day coverage. Legacy team participation metrics remain unchanged.
**Tech Stack:** Flutter, Riverpod, existing excel/archive packages; native OOXML chart parts, no new runtime dependencies.
**Spec:** User-approved monthly concept and implementation request in this chat (2026-10-29).

## Global Constraints
- Real backup is read-only; no personal data committed or used as test fixtures.
- Summary and export use the identical report and asOf date.
- Future source dates are planned; past dates do not prove completion. Empty days mean no records.
- Deduplicate by activity/person/team/normalized duty; only explicit HAZIRKITA alias normalization; retain other raw labels with review warnings.
- Actor/status/team/duty scope from repository must be retained; no actor may recover unknown historical teams using current personnel membership.
- No data-schema changes; no modification of unrelated dirty files.

## Report contract (owned by primary)
`MonthlyAnalyticsReport({required TeamAnalytics data, required DateTime asOf})`
Fields/getters: `String start, end, teamLabel, dutyLabel, status; DateTime asOf; int assignmentCount, uniquePersonnel, recordedDays, totalDays, knownTeamAssignments, unknownTeamAssignments, unclassifiedAssignments; double teamCoverage; List<MonthlyAnalyticsDay> days; List<MonthlyDutyCount> duties; List<MonthlyTeamRow> teams`.
`MonthlyAnalyticsDay`: `String date; int assignments; bool isPlanned; List<MonthlyDutyCount> duties; List<MonthlyTeamRow> teams`.
`MonthlyDutyCount`: `String duty; int count`.
`MonthlyTeamRow`: `int teamId; String name; Map<String,int> duties; int get total`.
teamCoverage is fraction 0..1, not percent; immutable lists/maps; teams follow existing sortTeamIds; duties descending count then name.

## Tasks
- [x] Primary: synthetic failing tests, report implementation, raw read-only backup reconciliation. Validate leap days, source-date boundaries, unknown teams, aliases, dedup, future dates, empty report and totals.
- [x] UI worker: monthly dashboard and export button using report, month arrows preserving scope, daily drilldown, responsive heatmap. Own only new monthly UI files plus analytics screen integration. Retain old monthly detail as expandable section. Widget tests at narrow widths and large text.
- [x] Export worker: `MonthlyAnalyticsExcelExporter.generate(MonthlyAnalyticsReport report) -> List<int>`; summary/daily/duty/team/quality sheets, native cell-linked charts; tests inspect ZIP/chart relationships and worksheet values. Own services/monthly_* and exporter test only.
- [x] Primary: integration, focused tests, analyze, complete suite if feasible, XLSX external read and UI capture; independent review and corrections.

## Review Focus
- Mixed months and partial selected periods must not imply full-month records.
- Unknown-team records must obey existing actor and filters.
- Chart caches and formulas must agree with report and worksheet ranges, including empty data.
- Text labels beginning =,+,-,@ remain literal text in XLSX.
- Midnight/date boundaries, zero coverage and overflow must not produce misleading values or errors.

## Evidence

## Approved follow-up: personnel counts (2026-10-29)
- Add nullable currentHeadcount/headcountAsOf to TeamAnalytics and MonthlyAnalyticsReport. Repository counts active non-demo personnel in authorized current team scope, independent of period/duty/status. No actor => unavailable. Missing snapshot => unknown.
- Add uniquePersonnel and uniquePersonnelByDuty to MonthlyTeamRow. Same person across multiple duties remains one team-person total; assignment counts stay additive.
- Separate current roster, period people and assignments in UI/XLSX with units and dated definitions. Eliminate labels implying one assigned person means full team; no full-team count inferred.
- Preserve prior tests/contracts except expanded team XLSX columns and clarified wording; regressions cover authorization, inactive/demo, zero/unknown headcount and one person across several duties.
Completed locally: 54 focused tests, 797 full-suite tests passed (1 skipped); scoped analyze clean; four real-backup months reconciled and four XLSX files independently read by openpyxl. Independent source review clear. See docs/verification/monthly-analytics-2026-10-29.md. Existing main checkout remains dirty in unrelated navigation/roster modules; those changes were preserved. No commit/push/release or device/Excel GUI verification.
