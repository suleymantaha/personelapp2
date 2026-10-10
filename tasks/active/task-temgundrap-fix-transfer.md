# Görev: TEMGÜNDRAP düzeltmelerini çalışma deposuna aktarma

| Alan | Değer |
|---|---|
| Görev ID | task-temgundrap-fix-transfer |
| Amaç | İzole dalda doğrulanan type, duplicate, overflow ve çıktı üretimi düzeltmelerini mevcut yerel değişiklikleri koruyarak F:/personelapp2 deposuna uygulama |
| Tier | 2; birden fazla ekran ve çıktı üretimi, şema değişikliği yok |
| Yürütme | native; alt ajan yok |
| Yetki | Kullanıcının açık talebi: düzeltmeleri F:/personelapp2 çalışma deposuna uygula |
| Kapsam dışı | Commit, push, merge, bağımlılık yükseltme, üretim/veri değişikliği |
| Başlangıç revision | 05d55bfa8dab874345a728baaf7d2259a820b172 |
| Kaynak dal | fix/temgundrap-import-export-stability; personelapp2-fix çalışma kopyası |
| Yöntem | local-baseline.patch ile ilk yerel durum yeniden kuruldu; mevcut/kaynak/baseline üç yönlü birleştirme; tüm dosyalar çatışmasız hazırlandıktan sonra yazıldı |
| Korunan yerel durum | Aktarım öncesi 7 modified dosya, before-transfer-personelapp2.patch ile yedeklendi |
| Sonuç | 11 dosya aktarıldı; activity_archive_screen ve PDF testi zaten kaynakla aynıydı |
| UTC | 2026-10-10T20:30–20:31Z |
| Durum | DONE |
| Yayın | NOT_REQUESTED |

Kanıt kökü: `C:/Users/baba/.codex/.chatgpt-projects/g-p-6abd0db596b08191842d71e4484d6cd2`.
Aktarılan dosyaların SHA256 listesi `transfer-manifest.json` içinde; hedefte tüm hashler tekrar doğrulandı.
Yedek SHA256: `BE44DD444E58D5B0CD92BB6E2F45428559D66A3FD2E27320AE39E51A88051FB4`.

| Kontrol (cwd: F:/personelapp2) | Sonuç | Exit | Kanıt |
|---|---|---|---|
| flutter analyze --no-pub | PASS, no issues | 0 | transfer-analyze.log |
| flutter test --no-pub | PASS, 604 test | 0 | transfer-tests.log |
| flutter test --no-pub integration_test/temgundrap_export_android_test.dart -d emulator-5554 | PASS, 1 test; debug APK derlendi ve yüklendi | 0 | transfer-android.log |
| git diff --check | PASS | 0 | terminal |
| dart format --output=none --set-exit-if-changed integration_test/temgundrap_export_android_test.dart test/features/temgundrap/temgundrap_output_workers_test.dart | PASS, 0 değişiklik | 0 | terminal |

Ortam: Flutter 3.47.2, Dart 3.13.2; Android 17 API 37 emulator-5554.

## Değişiklik ve sınırlar

TemgundrapOperation model importu düzeltildi. Description tabanlı hatalı Set<String> zinciri yerine kaynak faaliyet kimliği kullanılıyor; tekrar import aynı kartı çoğaltmıyor, eski kimlikler tanınıyor. Uzun kartlar içerik kadar büyüyor; dar dialog başlıkları uyarlanıyor. Çıktı üretiminde ikinci işlem engelleniyor ve PDF/Excel encode işlemleri compute isolate'a aktarılıyor. MIME ve sharePositionOrigin tanımlı.

Android testi sentetik 15 operasyonlu PDF ve Excel'i iki kez üretir, PDF imzasını ve decode edilen Excel'deki son operasyonu kontrol eder. Native paylaşım/yazdırma arayüzü ve fiziksel cihaz frame profili test edilmedi. Kotlin plugin derleme uyarıları mevcut; Android testi başarılıdır. Veritabanı şeması ve yerel kayıtlar değiştirilmedi.
