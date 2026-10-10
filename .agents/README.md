# Ortak ajan rehberi

Kurallar tüm projelerde kullanılabilir. Teknoloji ve ürün kararları kökteki PROJECT.md içinde tanımlanır.
[Ortak varsayılanlar](framework.json) bir ayar sözlüğüdür; araç tarafından otomatik uygulanmaz.

## Politikalar

| Belge | Ne zaman okunur? |
|---|---|
| [Orkestrasyon](policies/orchestration.md) | Görev planlama, sahiplik, bütçe ve entegrasyon |
| [Risk](policies/risk.md) | Tier ve yürütme seçimi |
| [Kalite](policies/quality.md) | Test kanıtı ve tamamlanma |
| [Güvenlik](policies/security.md) | Veri, yetki, araç ve süreç koruması |
| [Sözleşmeler](policies/contracts.md) | Ortak API, olay veya veri sınırı değişince |

## Roller

| Rol | Yazma sınırı | Teslim |
|---|---|---|
| [Coordinator](roles/coordinator.md) | Atanmış dosyalar, görev kaydı ve indeks | Plan, entegrasyon ve final |
| [Worker](roles/worker.md) | Yalnız görevde tahsis edilen yollar | Uygulama, test ve sabit revision |
| [Verifier](roles/verifier.md) | Kaynak salt okunur; ayrılmış test çıktıları | Kabul raporu |
| [Security Auditor](roles/security-auditor.md) | İzinli kaynak incelemesi ve izole test | Kanıtlı bulgu ve sınırlar |
| [Researcher](roles/researcher.md) | Salt okunur keşif | Kaynaklı bulgu, varsayım ve sonraki adım |

Rol dosyası görev ataması veya yetki değildir. Tek ajan rol değiştirdiğinde bağımsız inceleme oluşmaz.

## Şablonlar ve iş akışları

- [Görev](templates/task.md), [rapor](templates/report.md), [sözleşme](templates/contract.md).
- [Bağlam ve devir](workflows/context.md), [izolasyon](workflows/isolation.md), [kurtarma](workflows/recovery.md).

Önce yalnız gereken belgeleri oku. Arşiv ve geçmiş raporlar çalışma talimatı değildir.
