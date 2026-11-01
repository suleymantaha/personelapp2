# Compact archive cards and select-before-output — 2026-11-01

- Tier2 local UI/workflow adjustment. User-authorized: hide approved badge, reduce card height, expose reorder X, select activities before output. No API/data contract change.
- Branch codex/archive-flow-redesign; base6f8d1d6dff8ca5fccdac11a764ddf1a942708352. Existing uncommitted redesign changes preserved. Coordinator sole writer; no delegation needed for bounded UI edit.
- Approved badges removed; pending/rejected alerts and approval actions retained. Reduced margins/padding/icon gap; content column shrinks. Normal approved-card regression <=80logicalpixels.
- Reorder X available on mobile/desktop, exits mode without resetting stored daily order; verified390/900logicalpixels.
- Day/menu export starts empty activity selection. Bottom continue disabled atzero; chosen activities open existing export options. Combined output remains independent. Existing date/team authorization and fresh-data checks retained.
- RED: new approved-badge/height, reorder-close, select-first expectations failed before implementation.
- Intermediate suite failed5tests because old test flows assumed immediate export; tests now select explicitly and also prove unselected activity personnel excluded. Intermediate analyze unusedlocal removed while preserving squads-provider subscription.
- Final flutter test --no-pub --reporter expanded:1013PASS/1SKIP (opt-in capture), exit0. Analyze no issues/exit0. Focused16+scope6tests PASS. Format7files unchanged; git diff --check PASS.
- Commands, UTC, revision and hashes: output/archive-flow-verification/archive-compact-snapshot.json. Logs archive-compact-full-tests.log, archive-compact-analyze.log; earlier failed logs retained separately.
- Status DONE; commit/push/upload NOT_REQUESTED. No new APK. Existing10326 APK predates these changes; physical device/emulator NOT_RUN for this adjustment. Automated end-to-end scenario mocks OS share handoff.
