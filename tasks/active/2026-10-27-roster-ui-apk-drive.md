# Çıktı Hazırla UI APK teslimi

| Alan | Değer |
|---|---|
| Görev ID | 2026-10-27-roster-ui-apk-drive |
| Amaç | Onaylanan iki günlük UI tasarımını, mevcut çıktı mantığını koruyarak main'e almak; imzalı güncelleme APK'sını doğrulayıp Drive'a yüklemek |
| Tier | 3: kişisel veri tutan Android uygulamasının dağıtımı |
| Yürütme | Native uygulama ve release; bağımsız salt-okunur güvenlik/veri bütünlüğü denetimi |
| Yetki | Kullanıcı main ve Google Drive teslimini açıkça istedi; kullanıcı verisini silme, uninstall/clear, herkese açık paylaşım yok |
| Repo/base | F:/personelapp2, main, 4958cdd503d604dfa762f4ea6ea6cad6adf642f7 |
| Başlangıç değişiklikleri | Önceki turdaki üç UI/test dosyası; ilgisiz .playwright-cli/ ve .serena/ korunur |
| Başlangıç UTC | 2026-10-27T08:08:48Z |
| Durum | DONE |
| Yayın | COMPLETED |

## İş paketleri

| ID | Hedef | Sahip | Durum |
|---|---|---|---|
| UI | UI diff ve kişi sayısı yarışını tamamla, test et | Kök ajan | DONE |
| AUDIT | Veri bütünlüğü, yetki ve release kapılarını bağımsız incele | release_security_audit | DONE |
| APK | 10316'ya göre daha yüksek kod, aynı imza, test AVD'de veri koruyan güncelleme | Kök ajan | DONE |
| DRIVE | APK metadata ve yükleme okuma doğrulaması; mevcut özel paylaşımı koru | Kök ajan | DONE |

## Kabul kanıtı

| Kontrol | Beklenen | Durum |
|---|---|---|
| Source | analyze, tam test, diff ve bağımsız denetim | PASS: 756 test, 1 skip, 0 analyze issue; denetçi final diff PASS |
| Build | Paket, versionCode, signer, hash, alignment | PASS: 10318, v2 signer ve zipalign eşleşti; bağımsız denetçi PASS |
| Update | nizam-nobet-test üzerinde adb install -r; kayıt/ayar ve firstInstallTime korunur | PASS: 10316→10317→10318, kurulum zamanı aynı; 80 kişi/admin/koyu tema |
| Main | Yalnız görev dosyaları için commit ve normal push | PASS: 8f2cdb341c5fb4bad9588c18ab04d284b938e118 main'e gönderildi |
| Drive | Eski Nizam APK ile aynı özel Drive alanında yeni dosya ve metadata okuma | PASS: 1YTvS4zUthcrnnZrfRM7OI-5ahiQ4_6W7, shared=false, 93,469,830 byte |

Aktif emülatör: kullanıcıya ait `baba` AVD'si dokunulmadan bırakılır. Göreve ait `nizam-nobet-test` açılışı PID 42616, port 5560. Önceki dağıtılan Drive APK 10316, dosya kimliği `13W9UxhETZwOas1VqmRy7ftOdwzl9vxbH`, SHA-256 yerel eşdeğeri `A5105F808C54E20260CD5C2CCA38402A7B5C4A6914B9EA16823FDAFD7441F2A6`; yeniden kontrol edildi.

Ara aday `1.0.7+10317` imza/metadata/alignment kontrolünü ve 10316 üzerine `adb install -r` güncellemesini geçti; 80 kişilik sentetik faaliyet, ilk kurulum zamanı, admin hesabı ve koyu tema korundu. Gerçek ekranda önizleme düğmesi yazı kontrastı düşük görüldüğü için kaynak düzeltildi. Son aday `10318` olacak; 10317→10318 güncellemesi ayrıca doğrulanacak. Bu ara aday Drive'a yüklenmedi.

## Son aday ve çalışma kanıtı

- `dart analyze`: exit 0. `flutter test --no-pub --reporter compact`: exit 0, 756 PASS / 1 skip (2026-10-27 UTC 08:16 civarı); log `build/roster-ui-release/10318-tests.log`.
- `flutter build apk --release --target-platform android-arm64,android-x64 --build-name 1.0.7 --build-number 10318`: exit 0; `build/roster-ui-release/10318-build.log`.
- Son dosya: `build/roster-ui-release/Nizam-1.0.7-10318.apk`, 93,469,830 byte, SHA-256 `D23055F5E2B6A1B5DCE2424C5BAD106A5293E0EC166E23F26A654C4C6E8499A3`.
- `aapt`: `com.example.personelapp2`, `1.0.7` / `10318`; `apksigner verify`: v2 geçerli ve eski 10316 ile aynı sertifika SHA-256 `afa692e51779950a263e6320220a7738d5c3fe5549c8c4b3eeda062a85ede63c`; `zipalign -c -P 16 4`: exit 0.
- `emulator-5560` yeniden `nizam-nobet-test` olarak doğrulandı. 10317→10318 `adb install -r`: Success; ilk kurulum zamanı `2026-10-23 23:25:29` sabit. Cihazdan çekilen kurulu APK hash'i aday ile eşleşti. Ekranda Oct 25 Nöbet kartı 80 kişi, eski `APK_SENTETIK` / `J.Alb.`, hesap `admin`, tema `Koyu` korundu. Yeni seçim ekranı 80 kişiyi canlı gösterdi; önizleme 80 kişi ve eski ilk satırı gösterdi. Kanıt PNG'ler aynı `build/roster-ui-release/` içindedir.
- Bağımsız `release_security_audit` final kaynak, imza, sürüm, alignment ve hash kontrolünü PASS buldu. Gerçek Honor 200 kurulumu ve fiziksel yazıcı NOT_RUN.
- Main commit `8f2cdb341c5fb4bad9588c18ab04d284b938e118` normal push ile gönderildi. [Android Release CI 40472818576](https://github.com/suleymantaha/personelapp2/actions/runs/40472818576) aynı commit üzerinde success: odaklı ve tam testler, analyze, baskı düzeni doğrulaması ve imzalı APK artifact adımları geçti. CI artifact adı `personelapp2-1.0.7-10318`.
- Kullanıcının yönlendirmesiyle yerelde test edilmiş APK doğrudan Google Drive'a yüklendi: [Nizam-1.0.7-10318.apk](https://drive.google.com/file/d/1YTvS4zUthcrnnZrfRM7OI-5ahiQ4_6W7/view?usp=drivesdk). Metadata tekrar okundu: `application/vnd.android.package-archive`, 93,469,830 byte, eski APK ile aynı klasör `0AHewT2Y5xPiHUk9PVA`, `shared=false`. Drive servisi checksum döndürmedi; yerel dosyanın ve cihazdan çekilen kurulu APK'nın SHA-256 değerleri eşleşti.
