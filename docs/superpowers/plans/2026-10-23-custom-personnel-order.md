# Custom personnel order implementation plan
Goal: Persist administrator-defined team and within-team personnel order.
Approved behavior: team and personnel drag ordering; matrix follows manual order;
rosters retain duty/unit grouping and rank priority, then manual order.
Architecture: nullable sortOrder on existing Drift rows (schema 6); null falls
after explicitly ordered records, with existing official/rank/name fallback.
New/moved personnel have null order. Historical duty team snapshots stay intact.
UI: labeled order editor opens full unfiltered lists, with drag and accessible
move buttons, Save/Cancel, atomic local repository validation.
- [x] Backend migration, authorization, full-set transaction and backup tests.
- [x] Shared comparator and matrix/roster integration regression tests.
- [x] Order dialog and management screen integration/widget tests.
- [x] Format, analyze, regression suite, independent review.
No deployment, push or release. Existing data and user changes preserved.
