# Custom personnel order
Status: DONE
Base: main 68f84e7200222730dba40c65d139519ad851f0e6
Branch: feat/custom-personnel-order
Owner: coordinator

Implemented administrator team/personnel order editor with drag and move buttons.
Schema 6 persists nullable sortOrder; backup and restore retain positions.
Matrix and matrix Excel follow saved order. Activity exports retain duty/unit/rank
priority and use saved order for ties. Historical team snapshots remain intact.
Saves validate current role and complete ID sets in a transaction.
Coordinator applied all changes; researcher independently reviewed backend/order logic.
Unknown-team comparator transitivity finding fixed and covered by regression test.

Validation:
- flutter analyze --no-pub: PASS, no issues.
- flutter test --no-pub --reporter expanded: PASS, 686 tests.
- Full suite log: .dart_tool/custom-order-full-test.log (local ignored artifact).
- Tests cover widget reorder/save/cancel, filtered-screen full-list save,
  authorization, migration, atomic validation, backups, database reopen,
  historical assignments and decoded Excel row ordering.
- Dart formatting and generated Drift models completed.
- git diff --check: PASS before final documentation update.
- Physical device installation: NOT_RUN.

Git: no commit, push, merge, release or deployment performed.
Limit: concurrent editors use last successful save; no conflict versioning added.
