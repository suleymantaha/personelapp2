# Readable roster title and duplex defaults

Status: VALIDATED_WITH_DOCUMENTED_LIMITATIONS
Base: main7ccc3d0, clean product tree; .serena local metadata preserved.
User: title needs readable breathing room, and actual2+page print jobs should default to double-sided printing.
Root evidence: military/master Excel14pt wrapped title row fixed30pt; screenshot shows actualExcelviewer with title clipped at top. Existing Android printing5.14.3 layoutPdf has no duplex argument, native plugin only sets paper size.
Plan: deterministic title height with vertical room for actualformattedlong/time title, retaincontent and accountnewtitleheight in signedpagination; PNG inherits workbook. Minimal AndroidnativePrintAttributes duplexdefaultlongedge for2+actualPDFpages/singlepagesimplex, preservevectorPDF andOSprintercapability/useroverride. No fakecheckbox/unsupportedparameter. Otherplatforms retainexistingprintpath.
Acceptance: title geometry/renders military/master andlong/timerange; originaltable/summary/signature/pagebreakcontracts; actualPDFpagecount1vs2+ delegation; nativecallbacks/ranges/cancellation/errors handled; focusedtests/fullsuite/analyze/build andindependentreview. Physicalduplexprinter behavior must not be claimed without device.
Coordination: original Sol6.1 worker hit modelcapacity twice before editing. Stopretrying that failed model; bounded native default workers use exposed gpt-6-sol/medium fallback for independent title/print packages. No primary/provider/global setting change; requestedmodels notconfirmed unless runtime metadata exists. Ruflo tools rediscovered in current livecatalog; owned mesh swarm initialized with omitted maxAgents, returned registrycapacity15. Actual nativeworkers limited to2 useful packages underhost4slots; no installs/reconfiguration.
Ownership: titleworker XLSX title/header+signedpagebudget/tests; printworker PDFprintdelegation andAndroidnativegateway/tests; primarytaskrecord/Git/release; oneindependentread-onlyreview afterintegration. Preserve userfiles and attachments; onlysynthetic testpersonnel.

## Runtime acceptance hold
- Title tests/render passed; full Flutter suite755 PASS/1 skipped and analyzer0issues. Actual desktop Excel A4render blocked by unresponsive own COM instance; no PDF proof.
- Native initial defaults:1page simplex,4page longedge duplex requested; SavePDF overrides unsupportedduplex. Full4pagePDF saved. Physical printer NOT_RUN.
- Selectedpage native path regressed against working share-to-Print baseline.10312ALL_PAGES,10313explicitwrittenrange,10314UNKNOWNcount attempted; no selectedpagePDF accepted.10314 range2 Save becomes enabled but finalSave then stalls Preparingpreview. All candidates HOLD, no upload/push.
- After three hypotheses stopped functional patches and audited Android17 contracts. FullPDFcopy, falsechanged and callbackbackgroundthread supported by AOSP; no unproven blame.10315 metadataonlytrace authorized on guardedtestAVD to locate layout/write/finalcallback boundary. NoPDF/personnel/name/pathcontent logs.

## Trace and repeated selected-page acceptance
10315 diagnostic-only logging, same functional code as10314, saved4A4pages then selectedpage2 as1A4page with identicaltext andrender to fullpage2. Fresh All->2->All->2 repeat also saved correct1page. No extra functionalpatch. Earlier observed Preparingpreview stalls remain unproven/transient; logging is NOT credited asfix. Android17 supports fullPDFcopy/backgroundcallback/changedfalse; spooler DocumentTransformer removes unselectedpages. Finalclean10316 needs exactAPK upgrade/data/defaults/subset acceptance beforeupload.

## Final acceptance and delivery
- Productsource83f1d4e42a6222c5b52541109fd8a83f6870691a, main;1.0.6+10316. APK93469858bytes SHA256 A5105F808C54E20260CD5C2CCA38402A7B5C4A6914B9EA16823FDAFD7441F2A6. Samepackage/certificate;16KBalign; installedcopyequalscandidate; sourcepre/posthashunchanged.
- GuardedAndroid17testAVD upgrade10315->10316 preserved originalsyntheticpersonnel,80personteam,admin,selecteddark andfirstInstallTime. No userdevice/data touched. Full4A4PDF andselectedpage2as1A4PDF passed; selectedtextandrenderexactmatchsourcepage2. Initial4pagePrintAttributesduplex2; SavePDFtargetoverridesunsupportedduplex1.
- Exact10316onepage runtime NOT_RUN afterconflictwarning, no newactivitysaved. Actual10312onepage/simplexpassed; branchunchanged. Physicalprinter/ARM64 NOT_RUN; desktopExcelA4COMrender BLOCKED. Previousrange-stallcauseunproven despite3latersuccesses; residualintermittentriskretained. IndependentSolmediumreviewfoundnonewmaterialissue, artifact/runtimecorroborated.
- Drive uploadedandmetadatareadback/downloadaccessPASS: https://drive.google.com/file/d/13W9UxhETZwOas1VqmRy7ftOdwzl9vxbH/view?usp=drivesdk ; exact93469858bytes, storedAPKmime, shared=false. Authrawdownloadreferenceavailable, remotechecksumNOTEXPOSED.
- OwnedRufloswarm swarm-1792997082872-g08z8t gracefullyterminated; fourownedidleentriesremovedforcefalse; registryreadbackempty. Nativeworkers/review/diagnosiscompleted; titlecompletionpreservedfrompriorcontext. No registry stateusedasmodel/executionproof.
- Main integrationauthorized; finalnormalpushafterthisrecord. NewCIrunstatusmustbereportedfromlivecheck, notpriorrun.
