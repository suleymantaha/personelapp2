# Long roster image implementation plan

**Goal:** Save the complete daily/activity roster as one PNG beside PDF and Excel.
**Spec:** User approved Excel appearance, all rows, a single long image, local save.
**Architecture:** Decode the existing XLSX and paint its cells, spans, colors and borders using Flutter Canvas. Reuse existing platform save gateway. No new dependencies, database changes, release or push.
**Decision:** Preserve Excel styling; use bundled Roboto for portable Turkish glyphs. Increase row heights only where required to avoid clipped text. Cap raster memory and dimensions; report oversized lists without truncation.

## Tasks
- [x] Add regression tests for menu selection/time, PNG output, long rows, merged cells, signatures, summaries, save MIME and immutable filenames; observe failures.
- [x] Implement spreadsheet layout/painter and roster image save service.
- [x] Add localized menu option and wire all roster export entry points using current row reload validation.
- [x] Run focused tests, analysis, full suite, inspect synthetic PNG and task diff; independent read-only review.

## Review focus
Long/multiline Turkish text, merged groups, signed exports, blank/styled summary cells, oversized lists, repeated saves and stale data.

## Workspace
Existing `codex/nizam-responsive-design` contains user changes. Preserve them; no checkout/reset/stash/commit/push. Sources mirror is read-only. Primary owns code; explorer reads package API, reviewer independently inspects final changes. Ruflo coordination: owned swarm recorded in task ledger.
