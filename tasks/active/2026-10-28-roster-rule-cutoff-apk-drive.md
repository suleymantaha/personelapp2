# Kurallı çıktı tarih sınırı APK 10321 ve özel Drive

| Alan | Değer |
|---|---|
| Görev ID | 2026-10-28-roster-rule-cutoff-apk-drive |
| Amaç | Seçilen gün X sayımı düzeltmesini imzalı APK olarak üretip özel Drive'a yüklemek. |
| Tier / yürütme | Tier 3; tek yazarlı yerel build ve bağımsız release incelemesi. |
| Yetki | Kullanıcı APK'yı Drive'a yüklemeyi istedi. Önceki açık tercihe göre CI çalıştırılmayacak; commit/push yok. |
| Depo | `F:/personelapp2`, `main@0f3bd08` + önceki dirty çalışma ağacı. |
| Başlangıç | 1.0.7+10320 yerel ve Drive paketi; son başarılı CI artifact `personelapp2-1.0.7-10318`. |
| Hedef | 1.0.7+10321, `com.example.personelapp2`, önceki imza. |
| Durum | DONE, 2026-10-28 09:37 UTC. |

## Kabul ve kanıt

| Kontrol | Sonuç | Kanıt |
|---|---|---|
| Önceki sürüm ve özel Drive | PASS | Yerel 10320 APK paket kodu/imza SHA-256; Drive ID `183lsPNzAUq5UBuF1-pu25UM30kqqq5Lg`, özel klasör `0AHewT2Y5xPiHUk9PVA`, `shared=false`, owner only. |
| Yerel kaynak kontrolleri | PASS | `flutter pub get`, `dart analyze` 0 issue, `flutter test --no-pub --reporter compact` 769 PASS/1 skip; test log `build/roster-rule-cutoff-release/10321-tests.log`. |
| Build | PASS | `flutter build apk --release --target-platform android-arm64,android-x64 --build-name 1.0.7 --build-number 10321`; log `build/roster-rule-cutoff-release/10321-build.log`. |
| APK metadata | PASS | `com.example.personelapp2`, 1.0.7/code 10321, minSdk24/targetSdk36, arm64/armeabi-v7a/x86_64. `apksigner verify` PASS, aynı sertifika `afa692e51779950a263e6320220a7738d5c3fe5549c8c4b3eeda062a85ede63c`; `zipalign -c -P 16 4` exit 0. |
| APK hash | PASS | 93,535,622 byte, SHA-256 `33FDBD034E9329C322643257E7B0045ED1E13FEE971DBF88FEA6BCEB614D792D`; AVD'den çekilen kurulu APK aynı hash. |
| Test AVD güncellemesi | PASS | `nizam-rule-qa-10320`, `emulator-5570` cihaz adı doğrulandı; kurulu 10320 üzerine `adb install -r` 10321 Success. `firstInstallTime=2026-10-28 07:36:48` değişmedi. Sentetik `APK_QA_10320`/J.Yb./1-B Timi, admin oturumu ve Koyu tema önce/sonra XML'de korundu. 10321 kurallı ekranı `1–28 Ekim 2026`, `0 kişi hariç · 1 kişi çıktıda` gösteriyor; XML/PNG aynı klasörde. |
| Kaynak manifesti | PASS | 445 dosya `build/roster-rule-cutoff-release/source-hashes.json`, SHA-256 `472FAE4CAE85224E4145017765BCB86F23F4B804F884A77A464582A72F486DBF`; 10320 manifestine göre beklenen 8 kaynak değişti. |
| Diff | PASS | `git diff --check` exit 0; yalnız mevcut `tasks/ledger.md` LF/CRLF uyarısı. |
| Bağımsız inceleme | PASS | Reviewer APK metadata/imza/hizalama/hash, 445 kaynak, test/build logları ve AVD XML/PNG kanıtını inceledi; release blocker yok. Pre-install sürüm ve `install -r` çıktısı parent tool kaydında, diskte ham shell logu yok. |
| Drive upload ve readback | PASS | [Nizam-1.0.7-10321.apk](https://drive.google.com/file/d/1Vz8SAhdJE0kFXEoHlhdrJejQy7i86Fvu/view?usp=drivesdk), ID `1Vz8SAhdJE0kFXEoHlhdrJejQy7i86Fvu`; aynı özel parent, 93,535,622 byte, `shared=false`, yalnız sahip izni. Drive checksum sağlamadı. |
| CI | N/A | Kullanıcının önceki açık talimatı: çalıştırma. |

Fiziksel Honor 200 kabulü ve 21+ X release APK uçtan uca senaryosu NOT_RUN. İlgili davranış birim/widget/Excel testlerinde doğrulandı. Önceki APK, kullanıcı verileri ve ilgisiz çalışma ağacı değişiklikleri korunuyor.
