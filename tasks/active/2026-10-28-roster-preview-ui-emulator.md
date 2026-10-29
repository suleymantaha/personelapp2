# Birleşik Çıktı UI ve emülatör onayı

| Alan | Değer |
|---|---|
| Görev ID | 2026-10-28-roster-preview-ui-emulator |
| Amaç | Onaylanan sade tasarımı, iş kurallarını koruyarak uygulamak; önce test, sonra izole emülatör incelemesi. |
| Tier / yürütme | Tier 2; tek yazarlı uygulama ve bağımsız read-only review. Ruflo koordinasyon araçları bu oturumda yok; native ajan kullanıldı. |
| Yetki | Yerel uygulama, test ve emülatör kurulumu. Kullanıcı emülatörü onaylayınca canlı/Drive adımı değerlendirilecek. CI çalıştırılmayacak. |
| Depo | `F:/personelapp2`, `main@0f3bd08` ve önceki görevlerden kalan dirty çalışma ağacı. |
| Durum | DONE; kullanıcı kompakt UI'ı onayladı, APK özel Drive'a yüklendi ve `main` güncellendi. |

## Kabul ve kanıt

| Kontrol | Sonuç | Kanıt |
|---|---|---|
| Test first | PASS | Yeni footer/liste/imza senaryoları ilk denemede kırmızı, uygulama sonrası yeşil. |
| Davranış | PASS | Seçilen kartlar, personel ve imzalar kapalı başlıyor; özet/matris kompakt. Çıktıda/hariç sayaçları ayrı kişi listelerini açıyor; hariç listesi X gün sayısını gösteriyor. Alt iki eylem, kurallı ihracat, rütbe sırası ve seçilen gün X kesimi korunuyor. |
| Tam test | PASS | `flutter test --no-pub --reporter expanded`, 775 PASS / 1 skip, exit 0; `build/roster-10322-compact-tests.log`. Sonrasında yalnız kişi sayısına göre sheet yüksekliği değişti; ilgili 3 test tekrar PASS. |
| Statik analiz | PASS | `flutter analyze --no-pub`, 0 issue, exit 0. |
| Bağımsız inceleme | PASS | İki ayrı reviewer: imza yükleme retry kaybı ve başarısız kural yenilemesindeki stale sayaçlar bulundu; ikisi regression testleriyle düzeltildi. Başka somut regresyon raporlanmadı. |
| Yerel APK | PASS | `flutter build apk --release --no-pub --target-platform android-arm64,android-x64 --build-name 1.0.7 --build-number 10322`; `build/app/outputs/flutter-apk/app-release.apk`, code 10322. Önceki 10321 ile sertifika SHA-256 eşleşti. |
| Emülatör | PASS | `nizam-rule-qa-10320` / `emulator-5570`; 10321 üzerine `adb install -r` ile 10322 kuruldu, `firstInstallTime` değişmedi. Son kod aynı test AVD'sinde `install -r` ile yenilendi; sentetik kişi korundu. Kompakt normal/kurallı ekran ve dahil/hariç sheet XML/PNG ile gözlendi: `docs/design/roster-10322-compact-emulator.png`, `docs/design/roster-10322-rule-compact-emulator.png`, `docs/design/roster-10322-included-sheet-emulator.png`. İzole AVD'de hariç sayısı 0; 21 X kişi senaryosu widget/Excel testinde PASS. |
| Diff | PASS | `git diff --check`, exit 0. Önceden dirty dosyalar korundu. |
| Kullanıcı görsel onayı | PASS | Kullanıcı kompakt düzeni ve iki sayaçtan kişi listelerini açma davranışını onayladı. |
| Drive | PASS | `Nizam-1.0.7-10322.apk`, dosya ID `1QoXMqQNU4GIyt4Cibaj4wZZmFzAvgDJP`; 93,535,750 bayt, yalnız sahip erişimi metadata ile doğrulandı. |
| Git | PASS | `ac3cf74b82d54a01a2a46e9babb4a04b1657b9e3` commit'i `main` ve `origin/main` üzerinde. `[skip ci]` ile gönderildi. |
| CI | NOT_RUN | Kullanıcı talimatı gereği tetiklenmedi; bu commit için `gh run list` boş döndü. |

Final yerel APK SHA-256: `A24594276B799848854EF1D6DCB8F2595D0E94C9A5BDDD2E57DEC18C341701AE`. Drive: https://drive.google.com/file/d/1QoXMqQNU4GIyt4Cibaj4wZZmFzAvgDJP/view?usp=drivesdk. İzole AVD'deki sentetik Nöbet kaydı önizlemede 1 kişi ve 1 kart olarak görüldü. Gerçek Honor 200 cihazında bu yeni UI henüz sınanmadı. Görev kaydı ve özel Drive bağlantısı public repoya commit edilmedi.
