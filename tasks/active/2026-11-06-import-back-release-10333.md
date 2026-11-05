# Import result, confirmation and back behavior; local release10333

- State: RUNNING. Tier2 coordinated UI/typed-result/transaction behavior; preserve existing data/approval/authorization.
- Authorization: user approved proposed result visual + audited fixes, all changes, new localAPK/private Drive; CI forbidden. No main/remote push/tag/store release.
- Base87843dfe49ba4e67450b570678445d3d589dc72a, F:/personelapp2, branchrelease/local-1.0.16-10333. Fetch verified all existing local/remote branches already ancestors; max actual previousAPK10332.
- Current native version planned1.0.16+10333 (manifest/build consistent), same package/signer, Flutter arm64+x64 for Drive100MiB limit.
- Existing untracked .playwright-cli/.serena/output preserved. Production initially clean. Synced ChatGPT sources remain read-only.
- Roles/files: primary owns ledger/version/test migration/build/device/delivery; fix_import_repository owns data result/outcome helper/repo regression files; fix_import_result_ui owns import dialogs/result widgets/UI tests; fix_back_behavior owns back guards/matrix/personnel/archive/chain tests. No shared source writers.
- Native test runner owned by primary, sequential only; no Flutter tool concurrency. Independent review after workers finish.

## Approved design and contract
Result bottom sheet mirrors generated visual exec-91548528-4c42-4fb2-9578-2174f100fa43.png: headerAktarım sonucu, stateKısmen tamamlandı for partial, countsEklendi/Atlandı, Atlananlar/Eklenenler tabs, names/ranks and actual existing records, scrollable list and fixedTamam. Zero adds distinguished; no duplicate results toast. Final persistence action explicitlyOnayla ve Kaydet; preview does not persist. Date/task-team approval and commander pending-admin semantics retained.

Typed additive contract: ActivityImportStatus{added,alreadyAssigned,conflict}; ActivityImportOutcome has personnelId,name,rank,activityName,date,duty,status and nullableexistingDescription. Both batch result classes expose outcomes defaultconst[]. Existing API/counts/string consumers remain compatible.

Back: active modal first, then transient selection/reorder/search/local expanded card, then prior route. Dirty forms and in-flight saving stay protected. Mixed GoRouter/Navigator not globally replaced without evidence.

## Plan and evidence
- [x] Fresh behavioralRED: all-conflict import expected1existingcard actual2 (apk10333-empty-card-red.log).
- [x] Fresh behavioralRED: archive selection/reorder back goes/dashboard (apk10333-back-red.log).
- [ ] UI/transient/chain red and exact overflow source diagnosis.
- [ ] Repository fix preserves preexisting cards, removes only newly created zeroassignment card in same transaction; real typed outcomes.
- [ ] Shared result UI and clear final confirmation action; final result OK writes nothing.
- [ ] Consistent back guards, root/shell chain and layout regression.
- [ ] Fulltests/analyze/diff + independent source review on fixed revision.
- [ ] Local signedAPK; actual metadata/certificate/alignment/hash; upgrade10332→10333 preserves sentinel records/session/theme.
- [ ] Native result/back checks on separate nizam-nobet-test; no user's real device.
- [ ] Independent artifact/evidence acceptance; private Drive upload/readback, matching Downloads copy.
- [ ] Record unchanged Actions list; local commits only.

## Recovery and limits
No uninstall/clear/downgrade or DB reset. No migration, no historical empty-card cleanup, no data deletion from existing cards. Only in-memory synthetic DBs forhosttests. Exact user orphan-overlay report not reproduced in prioraudit; prove tested chains and disclose remaining untested native flows. Physicaldevice/realOCRcamera/printer/OSshare NOT_RUN unless separately measured.

## Checkpoint
Previous audit:49existing testsPASS;3targeted behavioralFAIL; additional chain49px overflow unresolved. These do not carry as new releasePASS. Freshfinal commands/results recorded below.

StartedUTC:2026-11-05T21:38:14.367392+00:00
