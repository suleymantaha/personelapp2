# Görev defteri şablonu — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026.

Bu dosya şablondur; henüz başlamış veya tamamlanmış görev kaydı değildir. Gerçek görev için `tasks/active/<task-id>.md` konumuna kopyala ve tasks/ledger.md indeksine ekle. Proje köküne göre ilgili protokol: .agents/policies/orchestration.md.

## Görev başlığı

| Alan | Değer |
|---|---|
| Görev ID | [doldur] |
| Amaç ve kabul ölçütü | [doldur] |
| Tier ve gerekçe | [doldur] |
| Yürütme modu ve gerekçe | [native/delegated seç] |
| Kullanıcı yetkisi / kapsam dışı | [doldur] |
| Koordinatör ve tek defter yazarı | [doldur] |
| Depo / cwd / base revision | [doldur] |
| Başlangıç kullanıcı değişiklikleri | [envanter veya yok olduğuna dair kontrol] |
| Sözleşme ID / sürüm | [gerçek değer veya gerekçeli N/A] |
| Başlangıç / son güncelleme UTC | [henüz başlamadı] |
| Görev durumu | PLANNED |
| Yayın/merge durumu | NOT_REQUESTED |
| Aktif ajan sınırı | [framework.json değeri; varsayılan 3 toplam, ortam daha düşükse o sınır] |
| Alt görev kontrol noktası | [framework.json değeri; varsayılan 30 araç işlemi veya 15 dakika] |
| Aynı hata deneme sınırı | [framework.json değeri; varsayılan 3] |
| Sonraki somut adım | [doldur] |

Yayın/merge durumları: NOT_REQUESTED, PENDING, BLOCKED, COMPLETED. COMPLETED yalnız gerçek işlem kimliği/revizyon kanıtıyla kullanılır.

## İş paketleri

| ID | Hedef | Bağımlılıklar | Sahip | İzinli yollar | Cwd/dal | Durum | Teslim revision | Sonraki adım |
|---|---|---|---|---|---|---|---|---|
| [ID] | [sonuç] | [ID veya yok] | [rol] | [kesin yollar] | [gerçek ortam] | PLANNED | [yok] | [ilk adım] |

Ortak dosya sahibi: [schema/lockfile/migration/token dosyalarını tek yazarlı ata].
Durum sözlüğü: PLANNED → READY → RUNNING → IN_REVIEW → DONE. Gerektiğinde BLOCKED, FAILED veya STOPPED kullan; engel kaldırılınca geçiş nedenini yaz.

## Kabul ve kanıt

| Kontrol ID | Kabul ölçütü | Komut / cwd | Revision | Sonuç | Exit code | Zaman UTC | Güvenli rapor yolu |
|---|---|---|---|---|---|---|---|
| [ID] | [beklenen] | [gerçek komut] | [yok] | NOT_RUN | [yok] | [yok] | [yok] |

Sonuçlar: NOT_RUN, PASS, FAIL, BLOCKED, N/A. N/A gerekçesi gerekir. Başlangıç hatası ile yeni regresyonu ayrı kaydet. Şablon satırı gerçek kanıt değildir.

## Bütçe ve tekrar kaydı

| Görev | Araç işlemi | Süre | Hata parmak izi | Düzeltme denemesi | Devre durumu | Kontrol noktası kararı |
|---|---:|---|---|---:|---|---|
| [ID] | 0 | başlamadı | yok | 0 | READY | başlatılmadı |

Devre durumları: READY, RUNNING, PAUSED, TRIPPED, RECOVERING, CLOSED. Bütçe yenilenirse eski kullanım silinmez. Beklenen ilk kırmızı TDD testi hata sayacına girmez.

## Kararlar, engeller ve devir

| Zaman UTC | Konu | Kanıt / gerekçe | Karar sahibi | Etkilenen görev | Sonraki adım |
|---|---|---|---|---|---|
| [gerçek olay olduğunda doldur] | | | | | |

Aktif süreçler ve sahipliği: [gerçek session/PID veya yok].
Korunan kullanıcı değişiklikleri: [envanter].
Tamamlanmayan kontroller: [gerçek liste].
Geri dönüş seçeneği: [task-owned diff/commit ve veri etkisi].
Bağımsız inceleme: [rol, revision, rapor veya henüz yapılmadı].

## Kapanış

- [ ] Kabul ölçütleri için gerçek kanıt kaydedildi.
- [ ] Gerekli bağımsız inceleme aynı revision üzerinde tamamlandı.
- [ ] Entegrasyon sonrası ilgili doğrulama yapıldı.
- [ ] Kullanıcı değişiklikleri ve veri korunuyor.
- [ ] Göreve ait açık süreçler/çıktılar kaydedildi.
- [ ] Yayın yapılmadıysa açıkça belirtildi.
- [ ] Sonuç, kalan risk ve sonraki adım kullanıcıya bildirildi.

Bu kutular yalnız işlem gerçekten yapıldıysa işaretlenir. Kapsama uymayan madde gerekçeli N/A olabilir.

Ortak varsayılanlar [framework.json](../../.agents/framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
