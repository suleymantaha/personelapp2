# Test ve doğrulama kaydı

Base: `9517d9464b702a22407be7c515e38e418bdb7032` + eklenen test dosyalarının
SHA-256 manifesti (`evidence/source-manifest.json`). Cwd: `F:/personelapp2`.
Log zamanları UTC'dir; kullanıcı tarihi 1 Kasım 2026, Europe/Istanbul.
Flutter 3.47.2 / framework `d3b14c8769`, Dart 3.13.2, Windows host.
Android: `nizam-nobet-test`, yeniden doğrulanan seri `emulator-5554`, API 37 / Android 17.

## Çalıştırılan komutlar

| Kontrol | Tam komut | Sonuç / exit | Log |
|---|---|---|---|
| Başlangıç tüm testler | `flutter test --reporter expanded --timeout 2m` | PASS, 1013 geçti / 1 skip, exit 0 | [unit-widget.txt](evidence/unit-widget.txt) |
| Son tüm host testleri | `flutter test --no-pub --reporter expanded --timeout 2m` | PASS, 1017 geçti / 1 skip, exit 0 | [final-unit-widget.txt](evidence/final-unit-widget.txt) |
| Dört risk testi | `flutter test test/audit/codebase_risk_characterization_test.dart --no-pub --reporter expanded` | PASS, dört mevcut kusur yeniden üretildi, exit 0; son tam pakette de var | [risks.txt](evidence/risks.txt) |
| Standart kök analiz | `flutter analyze` | FAIL, exit 1: önceden var olan `output/` içinde 3 error, 2 warning, 14 info | [analyze.txt](evidence/analyze.txt) |
| Uygulama ve test analizi | `dart analyze lib test integration_test test_driver` | PASS, no issues, exit 0 | [source-analyze.txt](evidence/source-analyze.txt) |
| Yeni dosyaların formatı | `dart format --output=none --set-exit-if-changed integration_test/codebase_audit_android_test.dart integration_test/audit_surfaces_android_test.dart test/audit/codebase_risk_characterization_test.dart test/support/audit_backup_interceptor.dart test_driver/codebase_audit.dart` | PASS, 5 dosya / 0 değişiklik, exit 0 | [format.txt](evidence/format.txt) |
| Android akış/risk | `flutter drive --driver=test_driver/codebase_audit.dart --target=integration_test/codebase_audit_android_test.dart -d emulator-5554 --no-pub` | PASS, 12 senaryo, exit 0 | [android.txt](evidence/android.txt) |
| Android route/ayarlar | `flutter drive --driver=test_driver/codebase_audit.dart --target=integration_test/audit_surfaces_android_test.dart -d emulator-5554 --no-pub` | PASS, 4 test / 22 ekran durumu, exit 0 | [android-surfaces.txt](evidence/android-surfaces.txt) |
| Kaynak envanteri | `python docs/audits/2026-11-01/inventory.py` | PASS, 291 dosya | [envanter](INVENTORY.md) |

Kök analiz başarısızlığı gizlenmedi ve mevcut `output/` dosyaları değiştirilmedi.
Dar analiz yalnız belirtilen uygulama/test kapsamını doğrular; kök komutun yerine PASS sayılmaz.
Skip: `dashboard_visual_capture_test.dart`, opt-in `CAPTURE_DASHBOARD` tanımlı olmadığı için.
Android reporter sayacındaki `(tearDownAll)` gerçek ürün senaryosu sayısına eklenmedi.
Toplam 38 PNG kaydedildi; 37'si adımların ekran kanıtı olarak kabul edildi,
yanlış isimli analitik matris karesi reddedildi. Log tamamlanma UTC zamanları ve
exit code'lar [verification.json](evidence/verification.json) içindedir.

## Android'de çalıştırılan assertion'lar

| Senaryo | Test dosyası / kabul |
|---|---|
| Arşiv → detay → tim seç → çıktı → gün çıktısı | Mevcut `test/support/archive_flow_scenario.dart`: seçili tim/onaylı kişi filtresi, saat aralığı, iki paylaşım payload'ı, atama satırlarının değişmezliği. OS share mock. |
| Dolu aylık analitik | Mevcut `monthly_visual_android_test.dart`: 185/178/2407, gün 148/148, semantics etiketleri, Timler listesi scroll, sabit header/metric konumu. Fixture; SQLite analitik hesabının Android performans testi değil. |
| Personel açık/koyu | Yeni audit entry: seed sonrası sentetik iki kişi; arama/boş sonuç; gerçek accessible reorder callback'iyle sıra taslağını değiştir; Vazgeç sonrası personel ve tüm tim satırları başlangıçla aynı. Fiziksel drag/TalkBack dispatch değil. |
| Dated history, dört test | `task_team_history_test.dart`: geçmiş/gelecek, aynı gün belirsizliği, geçersiz olay/tarih ve eksik/silinmiş tim. Android SQLite memory üzerinde. |
| F01–F04, dört test | Yeni `test/audit/codebase_risk_characterization_test.dart`: mevcut kusurların gözlenmesi. PASS, doğru güvenli davranış anlamına gelmez. |
| Route/ayarlar, dört test | Login + dokuz authenticated route, iki tema; dashboard ayarlarını aç/kapat. Her test dokuz Drift tablosunun JSON fingerprint'ini karşılaştırır; raw audit/sequence tabloları hariç. Gerçek auth yerine session override var. |

F03 bir concurrency schedule'ın **aynı executor'da sorgular arası enjeksiyonudur**;
iki bağımsız connection veya timing stress kanıtı değildir. İlişki hata mesajı kontrol edilir.
F01/F02/F04 düzeltildiğinde karakterizasyon assertion'ları ters çevrilmelidir;
F03 için ayrıca fixture yeniden tasarlanmalıdır.

## İlk başarısızlıklar ve ortam kararları

1. Android Gradle, Flutter'ın artık mevcut olmayan JDK 21.0.12 yolunda durdu.
   `flutter config --jdk-dir='C:/Program Files/Microsoft/jdk-21.0.13.21-hotspot'`
   ile gerçekten kurulu JDK seçildi. Bu host Flutter ayarıdır; repo/uygulama değişikliği değil.
2. İlk Android yüklemesinde aynı test AVD'sindeki eski imzalı paketle debug signer
   eşleşmedi. Flutter CLI eski test paketini otomatik kaldırıp debug paketi kurdu.
   Bu bir **temiz test kurulumu**; release upgrade veya veri koruma kanıtı değildir.
   Gerçek kullanıcı cihazı/AVD'si kullanılmadı; hedef her yüklemeden önce doğrulandı.
   Yeni target Gradle'daki özel `.qa` koşulunu kullanmadığından applicationId izolasyonu yok;
   güvenlik ayrı test AVD'sine dayanır. Paket `com.example.personelapp2`.
3. Capture conversion her test sonunda sıfırlandığı için ilk yeni testte screenshot
   helper hata verdi; per-test capture flag reset eklendi. [İlk kayıt](evidence/android-initial-failure.txt).
4. İlk fixture seed'den önce tim fingerprint'i aldığı için ekranın normal METİ seed'i
   değişiklik gibi göründü. Başlangıç DB'si önce normal şekilde seed edildi.
   [Kayıt](evidence/android-fixture-failure.txt).
5. Seed sonrası en sona eklenen tim lazy order listesinde oluşmadığı için fixture,
   ilk hazır timi kullanacak şekilde düzeltildi. [Kayıt](evidence/android-lazy-list-failure.txt).
6. Hızlı ve kademeli drag sıra değiştirmedi; assertion doğru biçimde FAIL verdi.
   Gesture test harness'i mi yoksa platform etkileşimi mi olduğu ayrıştırılmadı.
   Deterministik taslak değişikliği için gerçek accessible reorder callback'i kullanıldı;
   bu değişiklik fiziksel drag başarısı olarak sunulmadı.
   [Kayıt](evidence/android-gesture-failure.txt).
7. Risk fixture'ın ilk compile denemesinde `ApplyInterceptor` import'u eksikti;
   yalnız test import'u düzeltildi. Dört test sonra gerçekten çalıştı.
8. Bağımsız inceleyicinin dar test denemesi native sqlite DLL kilidi nedeniyle
   hazırlıkta durdu; bunu PASS saymadık. Ana ajan tam host paketini başarıyla çalıştırdı.
9. Ayarlar bottom sheet'inde AppBar back düğmesi bulunmadığı için `pageBack()`
   helper'ı hata verdi; gerçek system back yolunu çağıran `handlePopRoute()` kullanıldı.

Ham mobil loglardaki geçici VM service URL tokenları commit öncesi maskelendi.
Commit edilen metin kanıtlarında satır sonu boşlukları da normalize edildi.
Ekranlar ve loglar sentetiktir. Üretim yedeği veya gerçek kişi bilgisi kullanılmadı.

## Çalıştırılmayan kontroller

NOT_RUN: fiziksel cihaz; imzalı release build/upgrade; gerçek OS paylaşım/yazdırma;
OCR sağlayıcı uçtan uca; native büyük/yavaş dosya stresi; büyük veri profiling;
TalkBack/klavye; iOS/macOS/Linux runtime; web browser runtime; canlı CI ve release envanteri;
dependency/CVE taraması; iki bağlantılı gerçek backup concurrency testi.

Host tam paketi migration/backup/restore/authorization/exports/responsive testlerini içerir;
bu testlerin geçtiği ortam Windows test runner'dır. Her birinin Android/fiziksel cihazda
çalıştırıldığı iddia edilmez. Mevcut kodda düzeltme/refactor yapılmadı.
