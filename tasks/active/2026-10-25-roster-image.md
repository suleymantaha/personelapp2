# Long roster image

Status: COMPLETE (source implementation and local verification)
Base: 32c3671, F:/personelapp2, codex/nizam-responsive-design (pre-existing dirty workspace).
Acceptance: existing Excel workbook styles/data rendered as one readable PNG; local save from all roster export options; refreshed data; no new permissions/dependency.
Ruling: use current authorized working checkout to preserve existing uncommitted export/web work. Repeated design approval is unnecessary: the user explicitly approved the complete appearance and behavior in this chat.
Checks: focused Flutter tests; dart analyze changed files; flutter test; synthetic PNG visual inspection; git diff --check. Physical device/APK/release NOT_RUN, outside request.


## Final evidence
- Cwd F:/personelapp2; HEAD 32c3671; existing branch codex/nizam-responsive-design preserved. No commit/push/release.
- RED: new menu test failed because option absent; new renderer tests could not load missing implementation. Alignment assertion later reproduced excel 4.0.6 parent/child parsing bug; restoration now tested.
- PASS: focused existing export regressions 17; final image/menu/preview tests 11; complete suite 730 passed, 1 skipped (exit 0).
- PASS: full dart analyze, no issues (exit 0); dart format new modules/tests unchanged (exit 0); scoped and full git diff --check (exit 0).
- PASS: visual inspection of synthetic 1692x7003 PNG, full 120 rows/last row/signatures/summaries. Only synthetic personnel names used.
- Independent reviewer /root/roster_image_review found no actionable findings; primary verified material evidence. Explorer /root/excel_image_research read installed package APIs. Models requested through pinned explorer/reviewer roles; host did not return execution model metadata, so models are not independently confirmed.
- NOT_RUN: actual Android document picker, desktop save dialog, iOS/iPad share panel, browser download, device memory performance, APK/build/deployment.
- Ruling: PNG uses bundled Roboto in place of Excel's system Calibri for portable Turkish glyphs. Preserve layout/colors/merges; allow cell height growth to keep long text readable.
- Ruling: use existing Android document save channel with image/png bytes, desktop file_selector and iOS share sheet; no permission or native code changes. Cancellation never reports save success.
- Oversized images are rejected without truncation (32760 px dimension / 32M pixels raster budget). No list splitting or silent row omission.
- Coordination: owned Ruflo swarm terminated after both native agents completed; remaining owned registry entries removed, final agent_list empty.
- Logs and visual: build/roster-image-validation/{full-tests-final.log,final-image-tests.log,analysis-final.log,daily-list.png} (ignored build artifacts).

Release follow-up2026-10-25: merged outer-border decode loss found by actual Android PNG inspection, corrected in46c7e7e with two regression tests. Release integration record supersedes original NOT_RUN Android/APK fields; final accepted suite732pass/1skip and real native PNG save PASS.
