# Personnel UI Implementation Plan
Goal: implement approved compact same-page management and ordering UI.
Architecture: existing screen parts plus isolated draft editor; Drift transaction.
Tech Stack: Flutter, Riverpod, Drift; no new dependencies.
Spec: ../specs/2026-10-23-personnel-ui-design.md
- [x] Test-first atomic full-display save: stale membership, authorization, rollback.
- [x] Test-first hidden search, overflow actions and compact stable-colored cards.
- [x] Inline reorder editor: full list, drag, cancel/back, errors and safe footer.
- [x] Integration tests, narrow large-text checks, analyze, full suite, review.
No commit/push/deploy. Preserve working tree and existing ordering/export rules.
