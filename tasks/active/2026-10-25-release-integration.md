# Nizam 1.0.4 release integration

Status: COMPLETE for local release acceptance and private Drive delivery; user explicitly authorizes all pending changes into main and private Google Drive APK delivery.

## Ownership and acceptance
- Primary: staging, integration, final source/artifact evidence checks, Drive upload, Git push.
- Native Sol worker /root/release_worker: pubspec version, signed build, previous package/CI version comparison, test-emulator upgrade and data/settings/PNG save runtime evidence.
- Native Sol/high reviewer /root/release_review: independent full staged source and release data/security review. No edits.
- Worker source build freeze declared after setting 1.0.4+10310. No product edits during build.
- Existing product changes are authorized; local .serena project/cache metadata stays local.
- All native writes limited to revalidated nizam-nobet-test; never user device. No uninstall/clear/downgrade.

## Checks
- Before release: full Flutter suite730 passed/1 skipped, dart analyze0 issues, PNG/preview/menu regression11 passed, independent PNG review no findings.
- Optional role-bridge Python tests: first invocation missing required environment variables (configuration error); corrected documented ROLE_PROJECT_ROOT/ROLE_KIT_ROOT, all6 passed. Offline fixtures only, no model/provider call.
- Staged secret-pattern scan67 files: no private-key/token matches (bounded pattern check, not a universal secret guarantee).
- Staged git diff --check PASS.
- Pending: signed APK metadata/signer/zipalign/hash, actual upgrade data/settings preservation, Android PNG document save, full independent review, main integration verification, remote push, private Drive upload and metadata/hash-size readback.

## Integration
Base32c3671 equals fetched origin/main. Preserve existing dirty work; stage authorized product/docs/tests/tools and commit with Conventional Commits. Fast-forward local main, rerun required source checks on integrated revision, push normally after release acceptance; no force push or tag/release publication requested.


## Final acceptance
- Product source commits000ad29 and46c7e7e; source reviewed independently,280 current product hashes equal final APK build manifest.
- PASS accepted main: flutter test --no-pub --reporter expanded,732 passed/1 skipped (exit0); dart analyze,0 issues (exit0); scoped border tests7PASS; Python opt-in offline tests6PASS; git diff --check PASS.
- Real release build1.0.4/10310; same com.example.personelapp2 and certificate as10309; aapt/apksigner/16KBzipalign PASS independently checked. Final APK93,453,474 bytes, SHA256547d89e6cb1f94429c5a217cfbdcc0477cadfc82f596c7360491f16ee47aac25, MD5dc1926081b1dced7d5e360acc2fc0469.
- PASS original10309->10310 install-r data/settings preservation; final rebuilt10310 installed-r again, synthetic personnel/admin/dark retained. Only validated nizam-nobet-test touched; user device unchanged.
- Artifact review discovered merged summary right/bottom border loss after Excel decoding. Added two RED->GREEN regressions and anchor fallback. Preliminary/intermediate bytes retained under ignored build release folder; none uploaded. Final real Android PNG1692x500/64,961bytes has closed outer edges; actual document save success/file confirmed. Separate synthetic120row long PNG also checked.
- Final independent source/security/artifact review PASS; no open actionable findings. Runtime executed by worker, evidence verified read-only by reviewer and primary.
- Drive upload PASS private/nonshared file1ZMcoGSQJ9g0_E8ZxgIgzWaAm_istPPZx, Nizam-1.0.4-10310.apk. Metadata size93,453,474 agrees with actual final file; authenticated raw fetch succeeded and returned same full size, proving download access. Connector did not expose cloud MD5; no remote byte-hash comparison claimed. No public sharing permission added.
- Drive link: https://drive.google.com/file/d/1ZMcoGSQJ9g0_E8ZxgIgzWaAm_istPPZx/view
- Web release build PASS before border-only painter correction; no later web rebuild. Physical Android/iOS/desktop picker acceptance NOT_RUN; Android real document picker PASS on synthetic test AVD.
- Owned coordinator registry cleaned after both native agents completed. Local .serena files remain local assistant metadata, excluded from product commits.
- Final Git evidence note commit and ordinary main push follow this record; hosted CI outcome tracked separately, no CI success inferred from local results.
