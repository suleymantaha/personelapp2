# Personnel management UI redesign
Status: DONE
Base: 68f84e7200222730dba40c65d139519ad851f0e6
Branch: feat/custom-personnel-order
Scope: approved same-page team cards, hidden search and inline full-list reorder.
Existing uncommitted custom ordering work preserved. No schema/export rule changes.
Coordinator applied writes; worker supplied UI package; researcher independent review.
Independent review: no new critical access/data integrity findings. Search default
50-result cap fixed and covered with 55-person test. Nested drag edge auto-scroll
added and exercised with 37 members. Atomic save rejects changed memberships.

Evidence (all commands from repo root):
- flutter analyze --no-pub: PASS, no issues.
- flutter test --no-pub test/features/personnel --reporter expanded: PASS, 31.
- flutter test integration_test/personnel_ui_android_test.dart -d emulator-5556
  --dart-define=CAPTURE_UI=true --reporter expanded: PASS, 1.
- Android screenshots captured and visually inspected: .dart_tool/personnel-ui-previews/.
- Full suite: PASS, 696 tests, exit 0; .dart_tool/personnel-ui-full-test.log.
- Source SHA256 manifest: .dart_tool/personnel-ui-source-hashes.json.
- Tests validate full names at 320px/1.3 text, search/restore, complete filtered-list
  reorder, team/member drags, cancel, atomic stale-membership rejection and role.
Physical Honor 200 validation pending. Commit/push/merge/deployment not performed.

Updated UTC: 2026-10-23T16:27:20.400827+00:00

Release APK: PASS, version 1.0.2+10295, ARM64, release signer matches previous working 10294.
APK SHA256: 88f2769f9c662033cf7573b830c386f4017edf442d438f3559813cb534682b33
apksigner verify and zipalign 16KB check: PASS.
Drive upload verified: 1L88ACWgrQChzyJJ1FIUUwfZUQWastS2t
APK link: https://drive.google.com/file/d/1L88ACWgrQChzyJJ1FIUUwfZUQWastS2t/view
Git diff --check PASS. No commit/push/merge. Local ignored signing files not tracked.
Existing KGP plugin migration warnings remain; Android build completed successfully.
