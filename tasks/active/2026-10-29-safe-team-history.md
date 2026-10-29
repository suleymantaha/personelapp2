# 2026-10-29-safe-team-history

- Status: DONE (source implementation and local validation). Tier 3: historical data integrity, additive schema and backup contract.
- Authorized: implement safe repair and prevention; synthetic validation. Not authorized/requested: production repair, push, publication.
- Base: ac3cf74b82d54a01a2a46e9babb4a04b1657b9e3, branch codex/safe-team-history, isolated worktree under this chat's work/.
- Original F:/personelapp2 dirty tree preserved (navigation, roster, analytics and associated tests/docs); no copying of private backups into repository.
- Native worktree creation unavailable for sourceRoot outside app workspace; standard git worktree used in chat workspace.
- Spec/plan: docs/superpowers/specs/2026-10-29-safe-team-history-design.md and docs/superpowers/plans/2026-10-29-safe-team-history.md.
- Owners: backend worker core DB/services/tests; UI worker settings + new repair dialog/tests; primary activity/personnel prevention + records; reviewer read-only.
- Contract task-team-repair/v1 described in plan; additive schema and optional backup audit field maintain older backups.
- Checks: targeted flutter tests (NOT_RUN); dart analyze (NOT_RUN); flutter test (NOT_RUN); independent review (NOT_RUN). No device writes.
- Ruling: user scope approval authorizes implementation without another approval pause. No auto commit/push. Worktree retained until deliverable integration.
- Preflight: UI consumes backend preview/apply; primary consumes TaskTeamHistory resolver. Null resolver means unknown, never automatic current-team fallback on a past date.

## Final acceptance
- Original five prevention cases reproduced RED, then corrected. Independent review found and closed four historical/backup issues; web compile exposed a numeric-limit portability bug, fixed with RED/GREEN boundary test.
- Worktree full suite: PASS 830, skipped 1; source analyze PASS, zero issues.
- Main integration preserves existing isActive route guard, monthly analytics work, navigation/roster changes and all other existing edits. Task patch applied except form manually merged. Main full final suite: PASS 853, skipped 1 (CAPTURE_DASHBOARD optional visual capture). Exit 0.
- Main dart analyze lib test: PASS, zero issues. Root dart analyze: exit 0 with 14 existing info-only avoid_print findings under untracked output/roster*. Not a clean root analysis claim.
- Independent Sol reviewer: no open P1/P2; reviewed main merged form/analytics and final JS safe counter boundary separately. Byte hash manifest in output verification record.
- Web JavaScript release build isolated worktree PASS. Main web JavaScript release build PASS, exit 0, output build/web-team-history (existing served build/web untouched).
- No real database, browser storage, device data or backup restore/repair was executed. No APK, push, publication, commit or Git merge. Patch is locally integrated into main without staging user's files.
- Ruling: safe JSON integer counter max 9007199254740991 on all platforms; larger counters reject before writes to avoid JS rounding. Optional Wasm dry run warns about existing image dependency; normal JS build is the target.
- Ruling: restore never automatically fills history; only user-triggered preview/save/reopen/verify/apply repair. Verified removals count separately and are preserved; filled snapshots are preserved.
- Remaining validation: native file-picker/device E2E and physical data-retaining APK upgrade NOT_RUN (no APK requested). Browser real-data execution NOT_RUN by design. Local isolated worktree retained for reproducible patch.

Updated UTC: 2026-10-29T20:00:24.705619+00:00
