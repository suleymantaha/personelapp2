# Ortak sınır sözleşmesi şablonu — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026 · Başlangıç durumu: DRAFT.

Şablonun bulunması kabul veya uygulama kanıtı değildir. Etkilenen arayüz için doldur; HTTP/DB alanı gerekmiyorsa gerekçeli N/A yaz.

Gerçek sözleşmeyi `docs/contracts/<contract-id>.md` konumuna kopyala; göreli ayar bağlantısı bu yerleşimle uyumludur.

## 1. Kimlik ve kapsam

| Alan | Değer |
|---|---|
| Sözleşme ID / sürüm | [doldur] |
| Amaç | [doldur] |
| Üretici / tüketiciler / sahipler | [doldur] |
| Kaynak revision | [doldur] |
| Makine şeması yolu | [OpenAPI/JSON Schema veya eşdeğeri] |
| Durum | DRAFT |
| İnceleme / kabul kaydı | Henüz yok |
| Kapsam dışı | [doldur] |

## 2. Arayüz tanımı

- Tür: [HTTP / kuyruk / fonksiyon / dosya / depolama]
- Yol/metot/isim: [tam değer]
- AuthN ve sahiplik: [istek sahibi hangi kaynağa nasıl erişir]
- Girdi alanları: [ad, tip, required, null/missing, min/max, encoding]
- Bilinmeyen alan politikası: [reddet veya açıkça tanımlı uyumluluk davranışı]
- Çıktı: [tipler, sıra, zaman/boyut birimi, kaynak ilişkisi]
- Hata zarfı/status: [alanlar, kodlar, retryable; iç hata sızmaz]
- Hız/eşzamanlılık/kota: [kapsam, pencere, atomiklik, tüketim]
- Timeout/iptal/retry: [durum geçişleri ve kaynak temizliği]
- Idempotency: [anahtar kapsamı, süre, aynı/farklı payload davranışı]

## 3. Veri yaşam döngüsü

Depolanan alanlar, indeks/benzersizlik, işlem sınırı, kullanıcı/tenant ilişkisi, TTL, aktif silme, secret taşıma, log maskeleme, yedek ve kurtarma davranışı yazılır.

SQL yalnız gerçekten seçilen veritabanının söz dizimiyle eklenir. Şablona rastgele tablo/FK eklenmez; migration sırası ve geri dönüş etkisi açıklanır.

## 4. Uyumluluk ve geçiş

- Eski tüketicinin davranışı: [tanım]
- Eski kuyruk işi/veri sürümü: [tanım]
- Breaking değişiklik: [var/yok ve etki]
- Migration/deploy sırası: [tanım]
- Rollback/forward-fix: [veri kaybı ve sınırlar]
- Etkilenen iş paketleri: [ID listesi]

## 5. Test matrisi

| Test ID | Girdi / durum | Beklenen çıktı / yan etki | Sahibi | Kanıt durumu |
|---|---|---|---|---|
| [pozitif] | [geçerli] | [kesin sonuç] | [rol] | NOT_RUN |
| [negatif] | [geçersiz veya yetkisiz] | [hata ve yan etki yokluğu] | [rol] | NOT_RUN |
| [sınır] | [limit/limit+1] | [kesin sonuç] | [rol] | NOT_RUN |
| [yarış] | [eşzamanlı/tekrar] | [tekilleştirme davranışı] | [rol] | NOT_RUN |
| [kurtarma] | [kesinti/iptal] | [durum ve temizleme] | [rol] | NOT_RUN |

## 6. Kabul ve değişiklik kaydı

| Tarih UTC | Sürüm | Revision | Karar sahibi | Karar / gerekçe | Tüketici etkisi |
|---|---|---|---|---|---|
| [gerçek karar oluşunca] | | | | | |

DRAFT → REVIEWED → ACCEPTED → SUPERSEDED. ACCEPTED durumu ancak gerçek inceleme/kabul kaydıyla yazılır. Sözleşme değişince etkilenen test ve onaylar yenilenir.

Projeye özgü bağlam ve ek kabul ölçütleri kökteki PROJECT.md içinde tanımlanır.

Ortak varsayılanlar [framework.json](../../.agents/framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
