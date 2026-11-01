# Nizam kod tabanı incelemesi — 1 Kasım 2026

İncelenen base: `9517d9464b702a22407be7c515e38e418bdb7032`.
Yer: `F:/personelapp2`; dal: `audit/codebase-2026-11-01`.
`pubspec.yaml`: `1.0.12+10327`. Production kaynak, şema, dependency ve CI değiştirilmedi.

## Sonuç

Dört davranış riski sentetik verili testlerle yeniden üretildi. Bu testlerin
PASS olması kusurların **mevcut olduğunu** doğrular; güvenlik veya düzeltme başarısı değildir.
Beşinci bulgu native dosya okuma yolundaki kaynak riski; runtime stres testi yapılmadı.
İyileştirme önerileri uygulama davranışını değiştireceğinden yalnız bu raporda bırakıldı.

## Doğrulanmış davranış bulguları

| ID / önem | Tetikleyici ve etki | Kaynak | Kanıt / sonraki güvenli düzeltme |
|---|---|---|---|
| F01 / P2 | Tim eklerken komutan hesabı oluşturulursa `user.timId` boş kalıyor; timi kullanıcıya bağlayan sorgu `null` dönüyor. Komutanın kapsamı çözülemiyor. | `personnel_repository.dart:339-363`, `:18-41` | F01 testi: tim oluşturuldu, çift yönlü bağlantı yok. Oluşturmayı aynı transaction içinde iki bağlantıyı tamamlayacak şekilde düzelt; ardından login + kendi personeline atama testi. |
| F02 / P2 | DB rolü komutana düşürülmüş hesabın eski admin actor nesnesi atamayı onaylıyor. | `activity_repository.dart:49-55`, `activity_repository_conflicts.dart:199-206` | F02 testi gerçek repository ile `beklemede → onaylandi`. Yetkiyi her mutation transaction'ında kalıcı hesaptan doğrula. `deleteActivity` zaten daha güçlü kontrol kullanıyor. |
| F03 / P2 | Yedek tabloları ayrı okunurken faaliyet SELECT'inden sonra faaliyet+atama eklenirse yedek atamayı içerip faaliyeti içermeyebiliyor; kendi import kontrolü reddediyor. | `app_backup_service.dart:46-115`, `:298-302` | F03 testi sorgular arasına deterministik yazım enjekte ediyor; stabil yedek kabul, enjekte edilen yedek ilişki hatasıyla ret. Tutarlı snapshot önerilir. Gerçek ikinci connection testi yapılmadı; aşağıdaki sınır önemli. |
| F04 / P2 | Eski varsayılan admin parolası seed sırasında boşaltılıyor; kayıtlı username oturumu yine admin açılıyor, yeni parola kurulumu atlanabiliyor. | `database.dart:141-148`, `session_storage.dart:24-56`, `main.dart:19-27` | F04 testi `ensureSeeded` sonrası boş parola + aktif session gösteriyor. Parola kurulumu/iptalinde session geçerliliğini tekrar tasarla ve upgrade regression ekle. |
| F05 / P2, statik | Büyük veya yavaş dosya sağlayıcısından yedek açma, Android activity callback'inde sınırsız `readText()` yapıyor. Dart'taki 50 MiB kontrolünden önce allocation ve UI bloke riski var. | `android/app/src/main/kotlin/com/example/personelapp2/MainActivity.kt:151-170`; `app_backup_service.dart:456` | Native stream okumasını boyut sınırıyla ve UI thread dışında yap. NOT_RUN: büyük/yavaş sağlayıcı, iptal, tam limit ve limit+1 testi. Çökme gözlenmiş gibi yorumlanmamalı. |

F01 dosyası: `lib/features/personnel/data/personnel_repository.dart`.
F02 dosyaları: `lib/features/activity/data/`.
Diğer Dart kaynakları: `lib/core/database/` ve `lib/core/services/`.

F02 için dosya değiştiren saldırgan varsayımı gerekmiyor: mevcut komutan atama
akışı aynı kullanıcı adını komutan rolüne çevirebiliyor (`personnel_repository.dart:482-487`).
F03 normal export modalında aynı ekrandan ikinci yazım yaptığını kanıtlamaz.
Task-team repair preview dış transaction kullanıyor; bu akış aynı riskle etiketlenmedi.
F03 interceptor aynı executor üzerinden çalışır: gelecekte transaction düzeltmesini
doğrulamak için gerçek ikinci connection/barrier fixture'ı gerekir. Yalnız assertion'ı
ters çevirmek yeterli değildir.

## Güvenlik ve veri saklama gözlemleri

- `connection/connection_native.dart:10` standart `NativeDatabase(File(...))` açıyor.
  Uygulama düzeyinde DB encryption görülmedi; PROJECT.md'nin “şifreli depolama”
  iddiası kaynakla desteklenmiyor. OS disk encryption ve fiziksel cihaz doğrulanmadı.
- JSON yedek şifrelenmiyor; canonical checksum bozulmayı algılar, gizlilik veya
  kötü niyetli düzenlemeye karşı authentication sağlamaz (`app_backup_service.dart:116-126`).
  Parola hash'leri ve personel verisinin yer aldığı dosyanın korunması ayrıca ele alınmalı.
- SharedPreferences'taki username'i değiştirme senaryosu yerel app verisine yazma
  erişimi gerektirir; remote exploit kanıtı yok. F04'ün normal upgrade durumu daha somut.
- Argon2id parola hash'i ve legacy doğrulama yolu mevcut; yeni hash mekanizması önerilmedi.
- Secret değerleri, gerçek kişi verisi ve gerçek yedek dosyaları bu incelemeye alınmadı.

## Kod kalitesi ve tasarım tutarlılığı

Tekrarlanabilir [envanter](INVENTORY.md) 291 el yazımı `lib` Dart dosyasını kapsar.
57 dosya 300 satırdan uzun; 16 dosya en az 500 satır. Boş satırlar dahildir.
En uzunlar bulk import dialog (713), backup service (710), archive screen (673).
Uzunluk hata kanıtı değil; ileride sorumluluklara göre, dar regression testleriyle bölünmeli.
300 satır hedefi için toplu refactor bu görevde yapılmadı.

| Alan | Kanıt ve yorum | Öneri |
|---|---|---|
| Renk | 216 lexical `Color(0x...)`, 80 `Colors.*` kullanımı; merkezi tema da sayıya dahil. `analytics_charts.dart:10,400` ve `analytics_details.dart:195` aynı paleti tekrar ediyor. | Merkezi semantic/categorical token kullan. PDF/Excel sabit baskı rengini ekran temasıyla otomatik değiştirme. Her literal yanlış değildir. |
| Metin | 279 literal ile başlayan `Text(...)` adayı. Watch roster `watch_roster_screen.dart:45,75,80`, details `:66`, days `:86`; mevcut `commonCancel/commonSelect` yerine doğrudan metin. | Ortak UI metinlerini mevcut ARB'ye taşı; görev kodları, METİ adı, Excel `X` ve veri sözleşmesi sabitlerini çeviriyle karıştırma. Şu an uygulama yalnız Türkçe locale bildiriyor. |
| Ölü kod | Kaynak/test/router referansları ve analyzer değerlendirildi; silinebilir olduğu kanıtlanmış bir production sembolü bulunmadı. | Kullanılmayan public API/paket için reference/reachability kanıtı olmadan silme. Temiz analyzer tüm dead code'un yokluğunu kanıtlamaz. |
| TODO/debug | Handwritten Dart için lexical tarama; native kodda `Log.d` var (`MainActivity.kt:141,163` URI yazar). | Dosya URI'si kullanıcı belgesini tanımlayabilir; native logging ayrıca gözden geçirilmeli. |
| Doküman | README shopping/debt ve mevcut olmayan CI dosyasını anlatıyor. PROJECT sürümü `1.0.2+3`; CHECKS test sayısı 652. Gerçekte sekiz feature ve `android-release.yml` var. | Ayrı docs düzeltmesi; rapordaki yeni sonuçları eski belge iddialarıyla karıştırma. |
| Test runner | `scripts/test_runner.bat:14` yalnız `test/unit test/widget` çalıştırır; `test/core`, `test/features` ve yeni `test/audit` kapsam dışı kalır. `%95+` metni ölçülen/enforce edilen bir eşik değildir. | Tam `flutter test` komutunu esas al. Bu görevde runner çalıştırılmadı; CI'nin tam test adımı ayrı değerlendirildi. |
| CI | `max(pubspecCode,10000+runNumber)` pubspec baskınken tekrar aynı versionCode üretebilir (`android-release.yml:146-147`). Stable Flutter sabit revision'a pinli değil. | Dağıtılmış en büyük code ve signer kontrolüyle monoton sürüm politikası; sabit toolchain değerlendirmesi. Canlı release/Actions envanteri bu görevde sorgulanmadı. |
| Dependency | Mevcut lock korundu. Android build KGP/SDK metadata uyumsuzluğu uyarıları verdi. | Hemen yükseltme yerine ayrı uyumluluk işi; bu uyarılar mevcut build'i durdurmadı. CVE/dependency güvenlik taraması yapılmadı. |
| Performans | Büyük yedek/import/Excel akışları, tam tablo okumaları ve native UI-thread I/O incelendi. | F05 somut kaynak riski. Büyük gerçek veri, CPU/bellek ve frame profiling yapılmadı; genel hızlanma iddiası yok. |

Renk/metin regex'leri yorumları ve bazı teknik metinleri sayabilir; tam AST/l10n
kapsam ölçümü değildir. Dosya bazlı sayılar ve SHA-256: [inventory.json](inventory.json).
CI ayrıca signing secret yoksa unsigned APK üretip artifact/tag release'e ekleyebiliyor
(`android-release.yml:153-172,194-201`). Bu bir yapılandırma gözlemidir; canlı secret,
artifact veya dağıtılmış sürümün unsigned olduğu iddia edilmez. Yayın öncesi signer kapısı önerilir.
Platform runner/manifest'leri ve script/tool wiring de salt okunur tarandı; native
build warning'leri ve F05 dışında yeni yüksek önem düzeyinde doğrulanmış bulgu çıkarılmadı.
Desteklenmeyen OCR platformları kaynakta kapılanıyor; fiziksel iOS/desktop entegrasyonu test edilmedi.

## Korunan iş kuralları ve test sınırı

- Bugün/gelecek görev timi snapshot'ı, geçmişe ait belirsizlik, arşiv filtreleri,
  tarih değişikliği, conflict/cancel rollback yollarının mevcut testleri çalıştırıldı.
- Android'de dört dated-history testi de çalıştı: tarih sınırı, aynı gün belirsizliği,
  hatalı olaylar ve silinmiş/eksik tim referansı.
- Arşivden seçili tim/gün çıktısı yalnız onaylı kişileri içerdi; atama satırları değişmedi.
- Aylık analiz 185 mevcut kişi, 178 farklı görevli kişi, 2407 atama ayrımını korudu;
  günlük detay başlığı/sayaçları sabitken liste kaydırılabildi.
- Açık/koyu personel araması, boş sonuç ve sıralamadan vazgeçme mevcut satırları korudu.

[Test komutları ve gerçek sonuçlar](TESTLER.md) · [Ekran kanıtları ve UX değerlendirmesi](UX.md).
Tüm dosyaların her satırı veya her kombinasyon için hatasızlık garantisi verilmez:
envanter repo geneli, derin doğrulama yukarıdaki riskli yollar ve mevcut test kapsamıdır.
Fiziksel cihaz, gerçek veri, üretim, imzalı release/upgrade, gerçek OS paylaşımı/yazdırma,
TalkBack/klavye, bütün locale/font-scale kombinasyonları ve büyük veri stresi NOT_RUN.

## Önceliklendirilmiş sonraki işler

1. F01/F02/F04 için ayrı minimal patch + negatif yetki/upgrade regression testleri.
2. F03 için tutarlı snapshot ve iki bağlantılı yarış testi; F05 için native bounded I/O.
3. Görsel kesilmeler ve ortak l10n/renk tokenları; ekran karşılaştırmasıyla tek tek.
4. Doküman/CI sürüm politikasını güncelle; sonra gerekçeli küçük dosya bölmeleri.

Bu sıralama öneridir; kullanıcı düzeltme yetkisi vermediğinden uygulanmadı.
