# Orkestrasyon ve görev sahipliği — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026.

## 1. Başlangıç

Koordinatör kullanıcı hedefini, kabul koşullarını, mevcut yetkiyi, başlangıç revizyonunu ve çalışma ağacı değişikliklerini kaydeder. [Tier kılavuzu](risk.md) ile risk; native/delegated kararıyla yürütme biçimi ayrı seçilir.

Native modda ana ajan uygulama yapabilir. Delegated modda ana sorumluluğu kapsam, ortak sözleşmeler, entegrasyon ve son rapordur. Ana ajan da dosya yazacaksa sahipliği kaydeder; aynı dosyaya iki yazıcı atanmaz.

## 2. İş bölme

- Görev birimi, kendi kabul testiyle değerlendirilebilen sonuçtur.
- İşler bağımlılıklarına göre sıralanır; bekleyen sözleşmeyi tüketen iş “bağımsız” sayılmaz.
- Backend/frontend gibi etiketler tek başına izolasyon sağlamaz; dosya/path listesi gereklidir.
- Ortak schema, lockfile, migration dizisi ve tasarım tokenları tek yazarlı olur.
- Sözleşme üreticisi sonuç vermeden tüketiciler kendi uyumsuz şemasını uydurmaz.

## 3. Alt görev zarfı

Her görevlendirme şunları içerir:

| Alan | İçerik |
|---|---|
| Kimlik | Görev ID, amaç, Tier |
| Bağlam | Plan, gerekli kurallar, ilgili dosyalar |
| Girdi | Base revision ve sözleşme sürümü |
| Yazma kapsamı | Kesin izinli yollar; ortak dosya sahibi |
| Yetki | Araçlar, ortam ve yasak yan etkiler |
| Teslim | Test edilebilir çıktı, rapor yeri |
| Kabul | Test ID'leri, komutlar, beklenen sonuç |
| Bütçe | İşlem/süre/deneme limiti ve kontrol noktası |
| Süreç | Worktree/cwd, dal, süreç kimlikleri, entegrasyon sahibi |

Alt ajan kendi kendine kapsam veya yetki genişletmez; koordinatöre neden ve öneri iletir. Koordinatör kullanıcı talebi içinde kalan rutin kapsam düzeltmesini kaydederek yapabilir.

## 4. Eşzamanlılık ve bütçe

Varsayılan toplam aktif ajan sınırı ana ajan dahil 3. Örnek: 1 koordinatör + 2 işçi veya 1 koordinatör + 1 işçi + 1 denetçi. Bekleyen işçi hâlâ aktif çalışma yapıyorsa sayılır; işi tamamlanmış/kapalı ajan sayılmaz. Ortamın daha düşük sınırı önceliklidir.

Alt ajan yeni ajan başlatmaz. Model seçimi varsayılanı miras alır; fiyat/kalite varsayımıyla gizlice farklı modele geçilmez.

Varsayılan alt görev kontrol noktası 30 araç işlemi veya 15 dakika. Bir toplu çağrıdaki her gerçek araç çalıştırması bir işlemdir. Uzun araç çalışması süreye dahildir; bekleme aktif işlem sayısını artırmaz. Ortam sayımı göstermiyorsa yaklaşık sayım işaretlenir.

Üç başarısız düzeltme girişimi aynı hata parmak izi için devre keser. İlk kırmızı TDD testi, keşif komutu ve ilgisiz başlangıç hatası sayılmaz. Yenileme eski sayacı gizlemez; gerekçe ve yeni yaklaşım kayıtlı olur.

## 5. Görev defteri

Tier 2/3 için `tasks/active/<task-id>.md` tutulur; tasks/ledger.md yalnız görev indeksidir. Tek yazıcı koordinatördür; diğer ajanlar rapor gönderir. Tek yazıcı bir veritabanı transaction garantisi değildir. Dosya atomik yazma olanağı varsa geçici dosya + aynı dosya sisteminde rename kullanılır; yoksa seri yazılır ve revizyon çakışması kontrol edilir.

Görev durumları: PLANNED, READY, RUNNING, BLOCKED, IN_REVIEW, DONE, FAILED, STOPPED.
Kontrol sonuçları: NOT_RUN, PASS, FAIL, BLOCKED, N/A.
Bunlar birbirinin yerine kullanılmaz. DONE için kabul koşulları ve gerekli inceleme tamamlanmış olmalıdır; dış yayın istenmediyse DONE “yayımlandı” anlamına gelmez.

## 6. Entegrasyon ve doğrulama

1. İşçi kendi değişikliğini ve davranış testlerini tamamlar.
2. Kapsamlı checkpoint commit'i veya değiştirilemez patch/dosya hash manifesti teslim eder.
3. Risk/kabul koşulları bağımsız inceleme gerektiriyorsa denetçi aynı sabit revizyonu inceler; gerektirmiyorsa uygun öz denetim kaydedilir. “Dalın en son hâli” yeterli değildir.
4. Koordinatör gerekli kontrolleri geçen diff'i entegrasyon alanına alır.
5. Birleşim sonucu yeni revizyonda ilgili entegrasyon testleri çalışır.
6. Merge/yayın yalnız görev yetkisi ve gerekli kapılarla yapılır.

Yerel commit serbest çalışma kaydıdır; ana dala merge veya üretime yayın değildir. Bir dosyanın onaydan sonra değişmesi etkilenen onayı geçersizleştirir.

## 7. İlerleme ve engeller

En geç 60 saniyede anlamlı durum, yeni bulgu veya belirsizlik bildirilir. Uzun araç beklemeleri uygun yield/poll ile bölünür; araç kontrolü elde değilse ilk fırsatta güncelleme verilir.

Araç yoksa native yürütmeye geçilebilir; bağımsız denetim şartı kendiliğinden tamamlanmış sayılmaz. Yüksek riskli yayın kapısı BLOCKED kalır. Düşük riskli dokümanda bağlantı/şema/tutarlılık kontrolü yeterli olabilir.

Ayrıntı: [kanıt kapısı](quality.md), [devre kesici](../workflows/recovery.md), [rapor şablonu](../templates/report.md).

Ortak varsayılanlar [framework.json](../framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
