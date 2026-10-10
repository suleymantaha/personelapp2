# Universal Agent Kit — global kullanım

Sürüm: 1.0 · Kök: C:/Users/baba/.codex/agent-kits/universal-agent-kit/1.0
Bu dosya Codex global AGENTS.md girişinden okunur. Projeye bağlı değildir.

## Kapsam ve öncelik

- Geçerli sistem/geliştirici talimatları, kullanıcı talebi ve projenin yerel AGENTS.md kuralları önceliklidir.
- Global kit yalnız ortak çalışma rehberidir. Projeye özgü teknoloji, ürün kapsamı veya test komutu dayatmaz.
- Kit içindeki PROJECT.md/CHECKS.md/tasks belgeleri şablondur; aktif proje bağlamı veya görev kanıtı değildir.
- Projenin PROJECT.md/CHECKS.md belgeleri varsa onları oku. Yoksa README, config, CI, kod/test ve kullanıcı talebinden gerçek durumu çıkar.
- Sırf rehbere uydurmak için projeye dosya ekleme veya mevcut yapıyı yeniden tasarlama.
- Salt sohbet, açıklama ve küçük işler için bütün rehberleri okuma veya görev defteri oluşturma.

## Gerektikçe okunacak rehberler

Göreli linkler bu global kit köküne aittir; projenin .agents/ klasörüyle karıştırma.

| Gereksinim | Global rehber |
|---|---|
| Tier ve yürütme seçimi | [Risk](.agents/policies/risk.md) |
| İş paketleri, dosya sahipliği, bütçe | [Orkestrasyon](.agents/policies/orchestration.md) |
| Ortak API/olay/şema değişikliği | [Sözleşme](.agents/policies/contracts.md) |
| Test, inceleme ve tamamlanma kanıtı | [Kalite](.agents/policies/quality.md) |
| Veri/yetki/secret/yan etki | [Güvenlik](.agents/policies/security.md) |
| Tekrarlı hata, teşhis, geri dönüş | [Kurtarma](.agents/workflows/recovery.md) |
| İzole çalışma alanı | [İzolasyon](.agents/workflows/isolation.md) |
| Bağlam veya görev devri | [Bağlam](.agents/workflows/context.md) |
| Gerçekten gereken rol | [Rol indeksi](.agents/README.md) |

Ortak varsayılanlar [framework.json](.agents/framework.json) içinde; daha düşük ortam kapasitesi uygulanır.
Native varsayılandır. Delegasyon ancak kullanıcı veya geçerli ortam talimatı yetki verirse yapılır.
Rol dosyasını okumak ajan başlatma izni vermez; aynı ajanın rol değiştirmesi bağımsız inceleme değildir.

## Projeye yazma ve kayıt

Tier 2/3 görevde gerekliyse [görev şablonunu](.agents/templates/task.md) kullan.
Aktif görev, rapor, sözleşme ve test kanıtı ilgili proje/görev çalışma alanında tutulur;
global kit altına kullanıcı verisi, secret veya proje geçmişi yazılmaz.
Şablonun linkleri kopyalandıktan sonra gerçek proje veya bu global kit konumuna göre düzeltilir.
NOT_RUN, PASS, FAIL, BLOCKED ve N/A ayrıdır; şablon ve geçmiş PASS yeni başarı kanıtı değildir.

Bu kurulum talimat keşfini etkinleştirir; runtime, sandbox veya zorunlu CI enforcement sağlamaz.
