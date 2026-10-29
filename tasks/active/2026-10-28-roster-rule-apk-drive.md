# Kurallı çıktı APK 10320 özel Drive teslimi

| Alan | Değer |
|---|---|
| Görev ID | 2026-10-28-roster-rule-apk-drive |
| Amaç | Yerel kurallı çıktı değişikliklerini 10320 imzalı APK olarak üretmek, veri koruyan güncellemeyi doğrulamak ve özel Google Drive'a yüklemek |
| Tier | 3; imzalı APK, kullanıcı verisi ve dış servis teslimi |
| Yürütme | Kök ajan tek yazıcı; bağımsız release incelemesi gerekli |
| Yetki | Kullanıcı sürümü 1 artırıp Drive'a yüklemeyi istedi; CI önceki talimat gereği çalıştırılmayacak; push/merge yok |
| Repo | F:/personelapp2, main@0f3bd08 + mevcut çalışma ağacı |
| Başlangıç değişiklikleri | Önceki turdaki kurallı çıktı/rütbe değişiklikleri ve ilgisiz .playwright-cli/, .serena/ korunur |
| Önceki APK | Yerel ve özel Drive 1.0.7+10319, aynı dosya adı/ebeveyn doğrulandı |
| Başlangıç UTC | 2026-10-28T07:22:00Z |
| Durum | DONE |

## Kabul

| Kontrol | Durum | Kanıt |
|---|---|---|
| Kaynak, sürüm ve CI tabanı | PASS | `pubspec.yaml` 10319; Drive 10319; son başarılı CI artifact 10318; hedef 10320 |
| Yerel analyze/test/build | PASS | `dart analyze` 0 issue; `flutter test --no-pub --reporter expanded` 767 PASS/1 skip; ilk `--no-pub` release build plugin kaydı nedeniyle FAIL, normal `flutter pub get` ardından `flutter build apk --release --target-platform android-arm64,android-x64 --build-name 1.0.7 --build-number 10320` PASS; loglar `build/roster-rule-release/` içinde |
| Paket kodu/imza/hizalama/hash | PASS | `com.example.personelapp2`, 1.0.7/10320; v2 imza öncekiyle aynı `afa692e51779950a263e6320220a7738d5c3fe5549c8c4b3eeda062a85ede63c`; zipalign 16K PASS; 93,535,622 byte; SHA-256 `D1C718EC5C90D1B21077B9F0B2C8B2B9274CC7B2C255576923FFCDAC8907E01B` |
| Ayrı AVD 10319→10320, veri/ayar koruma ve yeni ekran | PASS | İlk `nizam-nobet-test` AVD'de güncelleme/kurulum hash'i geçti fakat headless QEMU arşiv etkileşiminde 3 kez çöktü. Ayrı temiz `nizam-rule-qa-10320` AVD'de 10319→10320 `adb install -r` PASS; firstInstallTime sabit; sentetik `APK_QA_10320`/J.Yb./1-B Timi, admin oturumu, Koyu tema korundu; yeni Birleşik Çıktı ve kurallı önizleme XML/PNG ile açıldı; kurulu APK hash'i aynı. |
| Bağımsız inceleme | PASS | `release_security_audit_10320` paket/imza/hash ve temiz AVD'de eski-yeni sentetik kişi/ayar/yeni ekran XML/PNG kanıtını ayrı inceledi; blocker yok. Fiziksel Honor 200 ve 21+ X release runtime NOT_RUN. |
| Özel Drive upload ve metadata readback | PASS | [Nizam-1.0.7-10320.apk](https://drive.google.com/file/d/183lsPNzAUq5UBuF1-pu25UM30kqqq5Lg/view?usp=drivesdk), ID `183lsPNzAUq5UBuF1-pu25UM30kqqq5Lg`; aynı özel ebeveyn `0AHewT2Y5xPiHUk9PVA`; APK MIME, 93,535,622 byte, `shared=false`, yalnız sahip izni. Drive checksum sunmadı; dosya boyutu ve stream readback eşleşti. |
| CI | N/A | Kullanıcının önceki açık talimatı: çalıştırma |

Göreve ait emülatör süreci PID 45352, AVD `nizam-nobet-test`; seri çevrimiçi olduktan sonra yeniden doğrulanacak. Kaynak ve APK hash kanıtı `build/roster-rule-release/` altında tutulacak. Farklı kullanıcı dosyaları ve önceki APK korunacak.

2026-10-28T07:49:17Z güncellemesi: Kaynak hash manifesti 445 dosya, SHA-256 `AA519A18BD8F13AA326FF06BF8F8A48F06F184C27AD4958163F123A5AB888A03`, build sonrası 0 sapma. Headless QEMU host `APPCRASH c0000005` kaydı mevcut; bu uygulama crash kanıtı değildir. Temiz test AVD alternatifinde veri ve yeni ekran kabulü sağlandı. Bağımsız release denetiminin güncel kanıtı değerlendirmesi bekleniyor; Drive upload henüz yapılmadı.

Kapanış: Bağımsız denetim güncel temiz AVD kanıtını PASS saydı. Gerçek cihaz kurulumu ve ayda 21+ X olan kişiyle release APK uçtan uca denenmedi; bu eşik birim/widget ve Excel içerik testleriyle doğrulandı. Drive'da dosya özel; bağlantı tek başına genel erişim izni vermez. CI/commit/push yapılmadı. Önceki 10319 APK ve mevcut çalışma ağacı korundu.
