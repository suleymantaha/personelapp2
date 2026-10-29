# Monthly analytics

Risk: Tier 2 (shared calculations and local Excel export). Approved in chat. No publication authorized.
Plan: docs/superpowers/plans/2026-10-29-monthly-analytics.md
Baseline: main, existing unrelated dirty files preserved.
Ownership: primary domain/report; UI worker monthly presentation/screen; exporter worker monthly service/test.
Checks: flutter test test/features/analytics; dart analyze; flutter test (full suite); read-only real-backup reconciliation, exported XLSX structure/readback and UI render.
Status: COMPLETE (local implementation; no release).
Verification: focused analytics 54 PASS; full suite 797 PASS, 1 skipped, exit 0; analyze lib/test/tool no issues; diff whitespace check PASS. Final logs in output/monthly-*.log.
Real-data check: all four backup months reconciled; openpyxl readback of four generated XLSX files PASS. Ekim: 2407 assignments,178 unique people,30 source-date record days,2305 known-team assignments,102 unknown.
Independent source review: no open findings after chart label correction; manifest and verification report in docs/verification/monthly-analytics-2026-10-29.md.
Not run: physical device, Excel GUI, APK/install; no commit/push/release. Native share dialog not driven; injected export flow and generated workbook tested.
Ruling: authorized implementation proceeds without another design/plan approval; prior monthly view remains accessible as detail.
