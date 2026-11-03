# Main integration and local APK 10329

- Goal: include all committed audit/hardening work and shared activity display ordering in main; push without CI; build signed APK locally.
- Tier 2: branch integration and local packaging; no schema/API changes.
- Execution: native coordinator; independent read-only integration reviewer. Only coordinator writes ledger.
- Authorization: user requested main integration, Git push, local APK; CI/store/release/upload not authorized.
- Repository: F:/personelapp2; starting branch fix/audit-hardening-apk-2026-11-01; base 102b28144c0f8ae60bf583b06982b72a23706001.
- Initial changes: four activity ordering source/test files from current task; existing untracked .playwright-cli/, .serena/, output/ preserved.
- Other worktrees: main at F:/personelapp2-archive-flow (tracked clean; untracked output and old task preserved); safe-team-history already ancestor. No branch deletion.
- Contract: N/A, existing shared display ordering and package identity retained.
- State: RUNNING. Merge/push: PENDING.
- Plan: compare refs, review, bump version, commit with [skip ci], fast-forward main, local checks/build/upgrade, push main and verify no workflow run.
- Source ownership: coordinator only. Reviewer read-only. Max total agents 3; same-error limit 3; checkpoint 15 minutes.
- Version evidence: local/distributed APK actual 10328; latest successful Actions artifact actual 10327; candidate 10329 / 1.0.14.
- Checks: prior full suite 1028 PASS / 1 SKIP and analyze PASS; final ordering suite 12 PASS including search/filter. Final package/build/upgrade/review NOT_RUN.
- Recovery: preserve all existing refs/data; task commits reversible; no uninstall, clear-data or downgrade.
- Physical-device testing NOT_RUN; CI intentionally NOT_RUN.
