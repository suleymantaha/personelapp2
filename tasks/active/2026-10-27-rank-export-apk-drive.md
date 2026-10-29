# Rütbe sıralı çıktı APK teslimi

| Alan | Değer |
|---|---|
| Görev ID | 2026-10-27-rank-export-apk-drive |
| Amaç | Birleşik Çıktı Önizlemesi rütbe seçeneğini yerel imzalı APK ile özel Google Drive'a teslim etmek |
| Kapsam | CI yok; push/merge yok; kullanıcı cihazına dokunma yok |
| Tier | 3; imzalı APK ve dış servise yükleme |
| Koordinatör / tek yazıcı | Kök ajan |
| Repo / dal | F:/personelapp2 / main |
| Başlangıç değişiklikleri | Önceki turdaki rütbe özelliği ve testleri; ilgisiz .playwright-cli/ ile .serena/ korunur |
| Kaynak sürüm | 1.0.7+10319 adayı; önceki Drive APK 10318 |
| Durum | DONE |

## Kontroller

| Kontrol | Sonuç | Kanıt |
|---|---|---|
| CI | N/A | Kullanıcı açıkça çalıştırma dedi |
| İlgili testler, analyze, release build | PASS | `dart analyze` 0 issue; `flutter test --no-pub --reporter compact` 759 PASS / 1 skip; `flutter build apk --release --target-platform android-arm64,android-x64 --build-name 1.0.7 --build-number 10319` exit 0. Loglar `build/rank-export-release/` içinde, 2026-10-27 UTC 10:33. |
| Paket kodu, imza, hizalama, hash | PASS | `com.example.personelapp2`, 1.0.7/10319; v2 imza geçerli ve 10318 ile aynı sertifika `afa692e51779950a263e6320220a7738d5c3fe5549c8c4b3eeda062a85ede63c`; `zipalign -c -P 16 4` exit 0; 93,535,398 byte; SHA-256 `399865BB907E2B0F240A37D07C2E5160DEFD52465072B38BCF57594C4B348C74`. |
| Ayrı AVD üzerinde veri koruyan güncelleme | PASS | `emulator-5560=nizam-nobet-test`, eski 10318 üzerine `adb install -r`: Success; ilk kurulum zamanı `2026-10-23 23:25:29` sabit; kurulu APK hash'i adayla eşit. 25 Ekim Nöbet kartı 80 kişi, `APK_SENTETIK` / `J.Alb.` ve admin/Koyu ayarları korundu. Birleşik önizlemede iki düğme; rütbe menüsünde Excel var, TEMGÜNDRAP yok. UI XML/PNG `build/rank-export-release/` içinde. |
| Bağımsız inceleme | PASS | `apk_release_audit` son artifact, kaynak manifesti 9/9, imza, kurulu APK ve AVD XML kanıtlarını doğruladı; release blocker bulmadı. |
| Drive yükleme ve metadata okuma | PASS | [Nizam-1.0.7-10319.apk](https://drive.google.com/file/d/1NX7l_ZE3OGNCwINUnu4efu58NlHNhIlG/view?usp=drivesdk), dosya ID `1NX7l_ZE3OGNCwINUnu4efu58NlHNhIlG`; metadata: aynı klasör `0AHewT2Y5xPiHUk9PVA`, 93,535,398 byte, APK MIME, `shared=false`, yalnız sahip izni. Drive checksum sunmadı. |

Kaynak hash manifesti: `build/rank-export-release/source-hashes.json`, SHA-256 `36CEE099C3121CE77811C67176EB24A6D78CE4C5C7520EEFB1652D3267E8FC7F`. APK hash'i kurulu test AVD kopyasıyla eşleşti. Fiziksel Honor 200 ve gerçek yazıcı NOT_RUN. CI tetiklenmedi; commit/push yapılmadı.
