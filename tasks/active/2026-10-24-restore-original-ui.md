# Restore pre-redesign screen — 2026-10-24

- Explicit user request: restore screen from before today's changes, not just compact card revision.
- Baseline HEAD32c3671 verified against original nizam-responsive-design task record. Restored10 tracked UI/theme/localization/test files byte-for-byte. Archived8 new UI files and3 design-specific tests under ignored build/ui-before-restore-20261024. No Git reset/clean.
- Web persistence, startup errors, exports/backup, contact web guard preserved. User source changes outside UI untouched. No database migration/clear/uninstall.
- PASS 18 dashboard/theme tests incl rendered light/dark mobile/desktop; analyze PASS, diff check PASS. Mobile original two-column crescent-card design visually inspected.
- Version10309 for safe update over prior delivered10308. APK acceptance/delivery pending. No commit/push/deployment.

- Final runtime:10308->10309 install-r PASS, synthetic team/admin/dark retained. Original2column grid verified on isolated emulator. APK signature matches previous; zipalign PASS; SHA25619dde813c30ea0294e28542ea03a2d185591cda0dbfe2a74b521bed204b9823a. Web build PASS. Evidence10309-evidence.json. Physical device NOT_RUN.

- DONE: independent artifact review PASS; private Drive upload10309 succeeded id1o-_qGy6tLOLSiEwPsg1iVOb_b5VAyJ-R. No commit/push.
