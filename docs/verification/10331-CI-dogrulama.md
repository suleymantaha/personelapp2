# Kazancı APK 10331 — CI doğrulaması

Kontrol zamanı UTC: 2026-11-03T15:30:53.901612+00:00

## Kaynak ve CI

- Kaynak commit: `fe39071eef81e56a9c9316a9e5454be1ed0c9635`.
- Kaynak ağacı: `112bfa20419d9d59d458783041ca95b4edd6171e`; yerel `a686f0f` ile birebir aynı.
- Kazancı seçilen gün ve ertesi gün matriste X; nöbet heyeti grubunda. Önceki OCR ve tarih onayı düzeltmeleri korunur.
- PR: https://github.com/suleymantaha/personelapp2/pull/48 (taslak).
- CI: https://github.com/suleymantaha/personelapp2/actions/runs/41660807597.
- CI PASS: analiz, regresyonlar, tam testler, yazdırma kontrolü ve release APK üretimi başarılı.
- Tam testler: **1072 PASS, 1 opt-in görsel SKIP**; CI: `04:00 +1072 ~1: All tests passed!`.
- Analiz: `No issues found!`.
- Derleme: `flutter build apk --release --build-name=1.0.14 --build-number=10331`.
- Artifact: `13244036235`, `personelapp2-1.0.14-10331`.
- ZIP SHA-256: `938d6e0d2434a1299b4e2f040872a35d7ab90fd7d1d324922469145fe90f3512`; GitHub digest ile aynı.

## Gerçek APK

- Dosya: `Nizam-1.0.14-10331.apk`.
- Paket: `com.example.personelapp2`.
- versionName: `1.0.14`; versionCode: **10331**.
- Boyut: 119078499 byte.
- SHA-256: `d11c2b441f80e3b4403a038095dd5ae9866dccc27fc2454a1078de22e9561229`.
- Sertifika SHA-256: `afa692e51779950a263e6320220a7738d5c3fe5549c8c4b3eeda062a85ede63c`.
- Resmî Android build-tools35 `apksigner verify --verbose --print-certs`: PASS, exit0; APK v2 doğrulandı.
- Resmî `zipalign -c -P 16 4`: PASS, exit0.
- Paket ve sürüm resmî `aapt dump badging` ile okundu.
- Üç ABI libapp.so dosyası da 10330 paketinden farklı; yeni dosyalarda KAZANCI sabiti var, önceki dosyalarda yok. Aynı toplam boyut aynı içerik demek değildir.
- Bağımsız ikinci kontrol metadata, hash, imza ve hizalama için PASS verdi.

## Önceki paket

- Gerçek10330 dosyası alındı; aynı paket/versionName, versionCode10330.
- Önceki SHA-256: `1b014bee863f89818aaead8510412a0fe29df9c1501a64fab947914d8fa943e8`.
- Eski ve yeni sertifikalar aynı;10331 >10330. Daha eski bilinen10329/10327 de küçüktür.
- Main merge, tag, GitHub Release veya mağaza dağıtımı yapılmadı.

## Cihaz üstü kabul

**CI_BUILD PASS / STATIC_ARTIFACT PASS / UPDATE_ACCEPTANCE BLOCKED.** Bu dosya CI derleme çıktısıdır; veri koruyan cihaz üstü güncelleme doğrulanmış kabul edilmez.

Ayrı ve boş nizam-nobet-test AVD API29 x86_64 ile oluşturuldu; emulator-5580 kimliği her yazma denemesinden önce kontrol edildi. KVM yoktu. Yaklaşık8dk yazılım boot sonunda system_server signal9 ile sonlandı; package servisi öldü ve boot tamamlanmadı.10330 kurulumu başarılı olmadı. Sentetik kayıt/tema oluşturulamadı;10331 kurulumu denenmedi.

-10330→10331 `adb install -r`: **NOT_RUN**.
- Yeni APK açılışı ve kayıt/tema koruması: **NOT_RUN**.
- Gerçek cihaz/kamera/MLKit: **NOT_RUN**.
- Gerçek kullanıcı cihazı/verisi kullanılmadı; uninstall, clear-data veya downgrade yapılmadı.
- Yalnız göreve ait emülatör kimliği doğrulanarak kapatıldı; kanıtlar korundu.

Yerel kanıtlar: android-qa/evidence/environment-status.txt, boot-failure-logcat.txt, final-device-state.txt, independent-apk10331-validation.json.
