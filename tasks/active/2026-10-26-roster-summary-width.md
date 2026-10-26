# Equal roster summary widths

Status: COMPLETE for correction and verified private APK delivery
Base: main789f5eb, clean product tree; local .serena metadata preserved.
User: bottom HazÄ±r KÄ±ta/GÃ¼lÃ¼ÅŸkÃ¼r/DiÄŸer TÃ¼m Personel boxes must have equal width and align to the main table in Excel, PNG and PDF.
Root cause: Excel summary spans A:B/C:D/E:F while main table/title ends E. F=7 adds width outside table; the three column-pair widths also differ. PNG faithfully reproduces that workbook.
Acceptance: equal actual physical box widths, full main-table boundary alignment, complete labels/counts/borders, preserve existing five visible personnel columns, ordering/groups/signatures. Both mergeCells modes and master export included; PDF audited/rendered as well.
Plan: add failing geometry regressions; minimally correct shared layout; format/focused tests and full suite/analyze; inspect synthetic XLSX-rendered/PNG/PDF artifacts; independent review. No database changes or dependencies.
Coordination: Ruflo tools currently unavailable (not present in live ALL_TOOLS); native Sol worker for implementation, native reviewer for bounded independent acceptance. No service installation/reconfiguration. Primary integrates evidence.
Git/APK delivery: previous user authorization for main and Drive APK remains context; decide delivery after verified correction, with higher actual versionCode and existing signing/update safeguards if APK is prepared.


## Verified correction
- Source committeda6b45bd after independent Sol/medium read-only review; no actionable findings.
- Shared late XLSX grid maps5logical fields onto7physicalcolumns, preserving original widths. Summary3cells span equal thirds; OOXML rounded253.35/253.32/253.32px, within0.03px, total759.99px matchingmain. No extraFoutside main; print right boundE->G, same row cutoff/scale/repeatedheaders.
- mergeCells=false retains no verticalpersonnelmerges; horizontalfieldstructuralmerges required byfinegrid. No change toPDF orPNG renderer productioncode.
- RED reproduced54px overflow (summaryright830vs main776). Focused47PASS, full739PASS/1skip, dart analyze0issues, diffcheckPASS. RawPNG border check widths<=1pixel difference at2x; actual120row1584x9696PNG andPDFfinalpage viewed byprimary+reviewer.
- Mainrecord/data/signatures/order/counts kept acrosssigned/unsigned/bothmergeflags/masterexport. DesktopExcel/physicalprinter NOT_RUN; OOXML/appPNG/PDFgeometry verified.
- No Ruflo tool was exposed; nativefallback used without service/config change. Models requested via pinned roles; no execution-model metadata surfaced, no measuredsavings claim.
- Following previous explicit main+DriveAPK authorization, worker preparinghigher1.0.5+10311 onceactualversion comparison passes; releaseacceptance/delivery remainsPENDING.


## Final release and delivery
- Version1.0.5+10311 committedefe3054, higher than actual prior delivered/local/installed and freshly downloaded CI40196061210 APK10310. Candidateactualversion/package/signature/16KBzipalignPASS independently verified.
- APK93,453,478bytes; SHA256709ce65d4d088d3b63fb304bfbf6d2b62487a9a98bbf851ebbe5be88a7657736; MD5c61cb4c294296a450224b774a79abdbe. Installed APK pulled and hash equals candidate. 280current product hashes match release manifest.
- RuntimePASS10310->10311 install-r without uninstall/clear/downgrade. Actual synthetic APK_SENTETIK/J.Alb./1person, admin/dark retained; firstInstallTime2026-10-23 23:25:29 and appId10230 unchanged.
- Windows qemu37.2.12 host0xc0000005 crashes were captured and3attemptcircuitbreaker applied. One alternate recovery with already installed backup37.1.11 regularqemu/no-snapshot/-Vulkan honoringAVDgpuoff succeeded. No SDK/global config edit, no wipe, no userdevice/AVDbaba mutation. Exact versionregression/rootcause not proven; this is recovery evidence only.
- NativePNG actual1584x500 saved via AndroidDocumentsUI. Independent rastermeasures main+summary bounds31.5..1551.5; summary507/506/507px, maxdifference1px. Fresh nativeExcel chooser shows currentXLSX; no externalshare/desktopExcel rendering claim.
- Independent final source/artifact/runtime reviewPASS, no actionablefinding. PhysicalARM64/desktopExcel/physicalprinter NOT_RUN.
- PrivateDrive uploadPASS: Nizam-1.0.5-10311.apk id1mEkEy8Mhh1VQOo0qjF2vcb0f94heaTjo, metadata93,453,478bytes and shared=false. Authenticated rawfetch succeeded same size; no cloudchecksum exposed, no remote bytehashcomparison claimed. Link https://drive.google.com/file/d/1mEkEy8Mhh1VQOo0qjF2vcb0f94heaTjo/view
- Last product revisionefe3054, sourcecorrectiona6b45bd. Final evidence-notecommit and ordinary mainpush follow; hostedCI result remains separate until actually observed.
