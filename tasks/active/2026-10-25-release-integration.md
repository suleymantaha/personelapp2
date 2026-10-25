# Nizam 1.0.4 release integration

Status: IN_PROGRESS; user explicitly authorizes all pending changes into main and private Google Drive APK delivery.

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
