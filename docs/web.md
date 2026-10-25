# Nizam web

Yerel çalıştırma (repository kökünde):

```powershell
C:/DevMobile/flutter/bin/flutter.bat build web --no-web-resources-cdn
python tool/serve_web.py
```

Adres: http://127.0.0.1:8765. Bu sunucu yalnız yerel bilgisayara açıktır.
Derleme çıktısı `build/web`; bu görev internet yayını yapmaz.

## Kayıtlar ve uyumluluk

- Android mevcut `jandarma_app.sqlite` dosyasını ve schema v6'yı kullanır.
- Web, aynı schema ile Drift WASM üzerinden tarayıcıda kalıcı kayıt tutar.
  Android ile otomatik eşitleme yoktur. Tam yedek dosyası dışa/içe aktarılabilir.
- Web kayıtları adres/protokol/port ve tarayıcı profiline bağlıdır. Aynı adresi
  kullanın; site verilerini silmek kayıtları siler. Düzenli tam yedek alın.
- Kalıcılığı olmayan veya sekmeler arasında güvenli yazamayan tarayıcı depolaması
  reddedilir; başlangıçta açıklama gösterilir. Gizli pencere kullanmayın.
- Excel/PDF paylaşımları tarayıcının paylaşım veya indirme desteğini kullanır;
  tam yedek tarayıcıdan indirilir, geri yükleme dosya seçiciyle yapılır.
- OCR cihaz özelliğidir; Android/iOS ile sınırlı mevcut davranışı korunur.
- Paylaşımlı çok kullanıcılı sunucu/backend veya çevrimdışı PWA kurulumu bu
  değişikliğin kapsamı değildir. Yerel hesap ve veri modeli korunur.

## Barındırma koşulları

HTTPS (yerelde localhost), WASM dosyası için `application/wasm` MIME türü,
`Cross-Origin-Opener-Policy: same-origin` ve
`Cross-Origin-Embedder-Policy: require-corp` önerilir. Yerel sunucu bunları ekler.
Alt dizinde yayınlanacaksa `flutter build web --base-href /alt-dizin/` kullanın.
Yayın ayrıca yetki ve hedef ortam doğrulaması gerektirir.

## Sabit üçüncü taraf dosyalar

Kaynak: https://github.com/simolus3/drift/releases/tag/drift-2.35.1

| Dosya | SHA256 |
|---|---|
| drift_worker_2_35_1.js | fe5f13be0526f78293796aefb9a29d3823a2dbdbf1bccd3f0faeb90eaaafd72a |
| sqlite3_2_35_1.wasm | fbcd2e8214f9231ea961e1b7706a22dd1194cfbfe6f26f13841b5aa7a0be1a1f |

Web worker/WASM çifti, transaction sonrası IndexedDB yazılarının kaybolmasını
düzelten 2.35.1 sürümündendir (upstream #3864/#3869). İstemci drift 2.34.2 ile
v4 worker protokolü uyumluluğu kaynak karşılaştırması ve tarayıcı testleriyle
doğrulanır; mobil bağımlılıklar değişmez. Sürümlü URL eski SharedWorker kullanımını
önler. Paketler güncellenirken binary çifti ve bütünlük değerleri birlikte doğrulanmalı.
Platform rehberi: https://drift.simonbinder.eu/platforms/web/
