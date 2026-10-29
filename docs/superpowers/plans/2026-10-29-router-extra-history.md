# Router extra history recovery implementation plan

Goal: keep callback-bearing route extras usable during browser back/forward; recover expired history without a cast crash; release preparation UI before route completion.
Architecture: router-owned bounded SessionExtraCodec (64 payload identities, opaque session tokens); builder-level missing-extra recovery for restored imperative matches. No DB/schema/dependency changes.
Scope: app_router.dart + new codec/recovery widgets; roster_output_screen.dart; focused tests.

- [x] Reproduce browser back/forward null cast and pending preparation state.
- [x] Add history round-trip and expired-token tests; observe failures before implementation.
- [x] Implement codec, missing payload recovery and independent row reload callback.
- [x] Run focused regression tests, full flutter test, dart analyze and diff checks.
- [x] Reload web app and verify browser navigation, missing token recovery and repeat preview.
- [x] Independent review and report.

Risk: Tier 2 (navigation/shared async UI). Existing user files preserved. No commit/push/deploy authorized.
