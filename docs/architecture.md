# Ortak mimari ve okuma haritası

## İki katman

Ortak katman çalışma yöntemini tanımlar: AGENTS.md ve .agents/.
Yerel katman ürün gerçeğini tanımlar: PROJECT.md, CHECKS.md, projenin kod/test/CI düzeni ve tasks/.
Ortak katman ürünün framework, sağlayıcı, katalog veya iş modelini seçmez.

## Göreve göre okuma

| Tetikleyici | Okunacak ek belge |
|---|---|
| Her başlangıç | AGENTS.md, PROJECT.md, CHECKS.md; mevcut kod/test ve Git durumu |
| Risk seçimi | [.agents/policies/risk.md](../.agents/policies/risk.md) |
| İş paketleri veya delegasyon | [.agents/policies/orchestration.md](../.agents/policies/orchestration.md) |
| Ortak API/olay/şema | [.agents/policies/contracts.md](../.agents/policies/contracts.md) |
| Test/inceleme/teslim | [.agents/policies/quality.md](../.agents/policies/quality.md) |
| Veri/yetki/araç yan etkisi | [.agents/policies/security.md](../.agents/policies/security.md) |
| İzole çalışma alanı | [.agents/workflows/isolation.md](../.agents/workflows/isolation.md) |
| Bağlam devri | [.agents/workflows/context.md](../.agents/workflows/context.md) |
| Tekrarlı hata veya kurtarma | [.agents/workflows/recovery.md](../.agents/workflows/recovery.md) |

Rol dosyası yalnız görev rolü gerektiğinde okunur. Aynı dosya revizyon değişmedikçe sebepsiz tekrar okunmaz.
Tier 1 için gereksiz ayrıntılı defter veya sözleşme üretilmez.
Risk kademesi kontrol derinliğini belirler; dosya sayısı ve ajan sayısından bağımsızdır.

## Ayarlar ve durumlar

[framework.json](../.agents/framework.json) ortak varsayılanları ve ayrı durum sözlüklerini tanımlar.
Varsayılanlar: native, toplam 3 aktif ajan, 1 delegasyon seviyesi,
alt görevde 30 araç işlemi/15 dakika kontrol noktası, aynı hata için 3 başarısız düzeltme.
Ortamın daha düşük kapasitesi ve geçerli görev sınırı uygulanır; ayar daha fazla yetki vermez.
Gerekçeli değişiklik görev kaydına yazılır. JSON tek başına bu limitleri uygulayan runtime değildir.

tasks/ledger.md yalnız indekstir; ayrıntı `tasks/active/<task-id>.md` içinde tutulur.
Görev, kontrol, sözleşme ve yayın durumları birbirinin yerine geçmez.
Tamamlanan kayıt gerektiğinde history/ altına taşınır ve indeks güncellenir.
Geçmiş DONE/PASS yeni göreve aktarılmaz.
