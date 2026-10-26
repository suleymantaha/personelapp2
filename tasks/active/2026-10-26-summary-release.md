# Summary width correction release

- Scope: version-only APK release candidate on accepted source `a6b45bd`.
- Authorization: parent carries prior explicit main/Drive delivery authorization;
  this worker owns version/build/test evidence, no Git or Drive writes.
- Baselines verified with actual aapt metadata: delivered APK 10310,
  GitHub run 40196061210 artifact 10310 (downloaded), test installation 10310.
- Selected version: `1.0.5+10311`, above all verified baselines.
- AVD: `nizam-nobet-test`, rediscovered `emulator-5560`; existing installation
  firstInstallTime 2026-10-23 23:25:29, lastUpdateTime 2026-10-25 13:00:22.
- Build: PASS. Acceptance: PASS, ready for independent artifact review. Evidence folder:
  `build/summary-width-validation/release/`.
- Required acceptance: same package/certificate, alignment, install -r without
  clear/uninstall, synthetic records/settings retained, native PNG exported.
- Candidate `Nizam-1.0.5-10311.apk`: 93,453,478 bytes; actual metadata
  `com.example.personelapp2` / `1.0.5` / `10311`; v2 signature matches prior
  certificate `afa692e51779950a263e6320220a7738d5c3fe5549c8c4b3eeda062a85ede63c`;
  `zipalign -c -P 16 4` PASS.
- SHA256 `709ce65d4d088d3b63fb304bfbf6d2b62487a9a98bbf851ebbe5be88a7657736`.
- Product revision `efe305452a6c4e26af38d6740a75173a08c2af63`, 280-file hash
  manifest `source-hashes.json` SHA256
  `e50d555abe559fc799d2069b7d099a808a3fe8b9cacfe1abdc9b0dda26221843`.
- Three emulator host crashes before any update: Windows Event1000,
  qemu-system-x86_64[-headless].exe, `0xc0000005`, unknown module. Headless
  default and swiftshader, then normal binary hidden with swiftshader all failed.
  Memory had 47 GB free. Settings before crash confirmed admin and dark selected.
  No upgrade, data wipe, uninstall, clear, or new APK launch has happened.
- Circuit breaker applied and parent notified; installed backup emulator
  37.1.11 discovered read-only; current 37.2.12 had also worked in prior run.
- Authorized recovery succeeded using actual installed backup 37.1.11 binary,
  same `nizam-nobet-test` userdata, hidden window, `-no-snapshot`, `-feature -Vulkan`.
  `backup-process-proof.json` records executed binary paths; no SDK/config edit.
  This does not establish the precise original host crash cause.
- Old 10310 navigation first verified `APK_SENTETIK` / `J.Alb.` / 1 person,
  admin account and dark selected. `adb install -r` 10311 succeeded.
  New 10311 launch retains all these values, appId 10230 and firstInstallTime.
  Pulled installed base APK SHA256 exactly matches the candidate.
- Native long-image action saved through Android DocumentsUI as
  `Nizam_SENTETIK_10311.png` (1584x500). Pixel border geometry: 507/506/507 px,
  maximum difference 1 px, main/summary left/right bounds 31.5/1551.5 equal.
  `verify_native.py` and `native-acceptance.json` contain reproducible assertions.
- Fresh native Excel export reaches chooser showing generated `.xlsx` file.
  No external share was sent; no spreadsheet viewer rendering was claimed.
- Final 280 product file hashes unchanged at revision `efe3054`.
  Commands with UTC and exit codes are in `commands.jsonl` / `ui-commands.jsonl`.
  Final APK MD5 `c61cb4c294296a450224b774a79abdbe`.
- Remaining limits: original emulator37.2.12 host crash cause unresolved;
  no physical ARM64 test; no desktop Excel rendering. Parent owns Git/Drive.
