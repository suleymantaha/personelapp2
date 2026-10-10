# Ortak sınırlar için sözleşme tasarımı — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026.

Sözleşme, bağımsız geliştirilen bileşenlerin aynı davranışı beklemesini sağlar. Entegrasyonun hatasız olacağını garanti etmez; uygulama ve sözleşme testleri gerekir.

## Ne zaman?

API, olay/kuyruk mesajı, ortak veri şeması, depolama biçimi, motor adaptörü veya birden fazla tüketicinin kullandığı davranış değişiyorsa. Yazım, yerel stil veya iç implementasyon düzeltmesi için gereksiz endpoint/DB sözleşmesi üretilmez.

## Sözleşme alanları

| Alan | İçerik |
|---|---|
| Kimlik | ID, sürüm, sahibi, durum, kaynak revision |
| Tüketiciler | Etkilenen modüller ve sahipleri |
| Giriş/çıkış | Tip, alan, zorunluluk, null/missing ayrımı |
| Davranış | Başarı, hata, timeout, iptal, retry |
| Yetki | AuthN, AuthZ, kaynak sahipliği, tenant sınırı |
| Tekilleştirme | Idempotency anahtarı, kapsamı, süre ve çatışma |
| Kaynak sınırı | Byte, adet, süre, sayfa/piksel, eşzamanlılık |
| Veri ömrü | TTL, silme, günlük, sır ve yedek politikası |
| Uyumluluk | Sürümleme, geçiş, eski istemci/iş davranışı |
| Kanıt | Pozitif/negatif/sınır testleri ve tüketici doğrulaması |

HTTP, kuyruk ve motor sözleşmeleri aynı ayrıntıları taşımaz; uygulanmayan alan gerekçeli N/A olur. Kanıtlanmamış bir gereksinim sessiz varsayım olmaz.

## Durum ve değişim

DRAFT → REVIEWED → ACCEPTED → SUPERSEDED.

Şablon DRAFT başlar. ACCEPTED için gerçek kabul kaydı, tarih ve revizyon gerekir. “Dondurma” değişmezlik anlamına gelmez; değişiklik sürümü ve tüketici etkisi görünür olur.

Breaking değişiklikte: etkilenen tüketicileri belirle; ilgili paralel işleri durdur veya mevcut sürümde sabitle; migration/uyumluluk yolu tasarla; sözleşme ve testleri güncelle; yeni revizyonu incelet. Önceki PASS yeni sözleşmeye otomatik taşınmaz.

## Şema ve uygulama

Makinece doğrulanabilir JSON Schema/OpenAPI gibi tek kaynak tercih edilir. Üretilen modeller elle ayrı ayrı değiştirilmez. Şema doğruluğu iş kuralı ve kaynak sahipliğinin yerini tutmaz.

Hata zarfı code, messageKey, retryable ve correlationId gibi açık alanları tanımlar. HTTP status, null/missing, tarih saat, encoding ve boyut birimi belirsiz bırakılmaz. İç hata ve secret istemciye dönmez.

Başlangıç şablonu: [contract.md](../templates/contract.md).

Projeye özgü bağlam ve ek kabul ölçütleri kökteki PROJECT.md içinde tanımlanır.

Ortak varsayılanlar [framework.json](../framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
