# Personnel counts and team meaning

User-approved follow-up: distinguish current personnel headcount, unique people assigned in period, and total assignments in UI and XLSX. One assigned person is not a full-team assignment.

Decisions: current active non-demo roster from authorized current membership is a separate snapshot with its own date. No historical headcount inferred and no headcount/period participation ratio. Unknown headcount remains unknown. Historical assignment teams stay unchanged. Team/duty cells show distinct people plus assignment counts; team unique-person totals are not sums of distinct people per duty.

Scope/ownership: primary domain/repository/tool and domain/repository tests; UI worker presentation/own tests; Excel worker exporter/own tests. Other chat's safe-team-history changes preserved. No commit/push/release.

Checks: RED/GREEN regressions, analytics tests, lib/test/tool analyze, real-backup summary/matrix reconciliation and independent XLSX readback, final independent source review, full suite.
Status: COMPLETE (local only).
Verification: analytics 62 PASS; full suite 860 PASS + 1 skipped, exit 0; lib/test/tool analyze clean; independent source review clear. Four newer real-backup months reconciled and XLSX readback including chart caches PASS. Explicit-outside/unknown/known synthetic CLI parity PASS. Synthetic UI render PASS.
Evidence: docs/verification/personnel-count-clarity-2026-10-29.md; output/personnel-count-*.log; output/personnel-count-verification/.
Not run: physical-device/native share/Excel GUI, APK/install. No commit/push/release.
