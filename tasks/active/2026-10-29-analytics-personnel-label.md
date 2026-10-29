# Analytics personnel label correction

- State: IMPLEMENTED; scoped acceptance, broader visual QA still in progress. Tier 2, read-only report projection, no database/schema writes.
- Authorization: user confirmed malformed heading occurs in Tim Analizi; fix grouping/heading while preserving duty data.
- Existing main dirty tree and all earlier tasks preserved. Work continues in same local main checkout with a minimal disjoint patch; no reset/stash/commit/push/deployment.
- Evidence: supplied backup checksum verified; no bogus squad exists. Five assignment duty values contain a different registered person's rank/name/specialty. Parent activity is exact Heybet and stored team is already correct. Earlier squad-field-only scan did not catch this; full duty-field audit located the actual cause.
- Plan: RED synthetic repository tests; shared conservative resolver recognizes registered personnel text only when parent duty is classified; integrate before analytics filters/dedup so daily/monthly/UI/XLSX agree; GREEN targeted then full tests/analyze; independent read-only review; final evidence in chat outputs.
- Invariants: raw assignment/personnel/activity/team/history rows unchanged; no current-membership fallback, no reassignment, recognized task overrides and ambiguous custom labels preserved. No real backup used as regression test input.
- Owners: primary implementation; reviewer read-only acceptance.
- Tests: NOT_RUN. Source review: NOT_RUN. Local UI/deployment: NOT_REQUESTED.

## Verification and limits
- TDD: 2 intended failures (raw person label in duty/unknown-team analytics), then 5 PASS. Expanded to 11 new tests PASS including exact-name/no-fuzzy/word-prefix boundaries, valid overrides, unknown teams, source row immutability, monthly widget and XLSX headers.
- `dart analyze lib test`: PASS (0 issues, exit 0).
- `flutter build web --release --no-pub --output=build/web-analytics-label`: PASS, exit 0. Normal JavaScript release built; optional existing image dependency Wasm dry-run warnings remain. No publication.
- Full suite attempt: 872 PASS / 1 opt-in visual skip / 5 FAIL in concurrent monthly visual/Excel work. Independent reviewer verified these tests bypass the new repository/resolver and instantiate synthetic reports/day objects directly.
- After concurrent test/source updates, latest analytics suite: 76 PASS / 3 FAIL (day detail semantics/status expectations). The 2 Excel failures no longer reproduced. Do not claim project-wide green.
- Scoped independent review: no actionable finding; source hashes unchanged since acceptance. Existing task `2026-10-29-monthly-visual-qa.md` owns outstanding UI work; its files were not repaired here.
- Actual supplied backup and current application data remain unchanged. No source assignment, personnel, team, date, history, status or note was rewritten; no tasks were added or deleted. Legacy name text is preserved in storage.
- Main branch local edits only, no staging/commit/push/deployment. Source patch and verification record saved in this chat outputs/team-label-audit/.

Verified UTC: 2026-10-29T20:38:25.026554+00:00
