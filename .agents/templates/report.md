# Görev teslim ve inceleme raporu — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026.

Native veya delegated çalışmada kullanılabilir. Kısa özet hedeflenir; kanıtı gizleyen katı 5–10 satır sınırı yoktur. Ham kod/log yerine güvenli dosya/revizyon bağlantısı verilir.

Gerçek raporu `tasks/active/<task-id>-report.md` konumuna kopyala; göreli ayar bağlantısı bu yerleşimle uyumludur.

## Doldurulacak rapor

~~~markdown
### [Görev ID / rol] — teslim raporu

- Durum: [DONE / IN_REVIEW / BLOCKED / FAILED / STOPPED]
- Kapsam ve sonuç: [gerçekte yapılan davranış]
- Başlangıç / teslim: [base SHA ve tam commit SHA veya hash manifesti]
- Değişen dosyalar: [yollar; salt okunur ise kaynak değişmedi]
- Sözleşme: [ID/sürüm veya gerekçeli N/A]
- Kanıt: [komut, cwd, UTC zaman, ortam, exit code, test sayısı]
- Kontrol sonucu: [PASS/FAIL/BLOCKED/NOT_RUN/N/A; gerçek rapor yolu]
- Eksik kontrol / risk: [varsa açık liste]
- Bütçe ve süreçler: [ölçülen işlem/süre, task-owned PID/session]
- Sonraki adım: [inceleme/entegrasyon/düzeltme; merge/yayın ayrı]
~~~

Birden çok kontrol varsa tablo kullan:

| Kontrol | Revision | Komut / cwd | Exit code | Sonuç | Test özeti / kanıt |
|---|---|---|---|---|---|
| [ad] | [tam kimlik] | [gerçek değer] | [henüz yok] | NOT_RUN | [henüz yok] |

## Güvenlik bulgusu eki

| Alan | Açıklama |
|---|---|
| ID / durum | [CONFIRMED veya SUSPECTED gibi] |
| Konum / revision | [tam kimlik ve dosya] |
| Ön koşul | [yetki ve girdi] |
| Beklenen / gözlenen | [davranış farkı] |
| Kanıt | [sentetik yeniden üretim, sır içermeyen rapor] |
| Etki / şiddet / güven | [gerekçeli] |
| Düzeltme / tekrar test | [öneri ve kabul ölçütü] |

## Raporlama kuralları

- Test edilmemiş sonucu, örnek sayıyı veya şablon durumunu gerçekmiş gibi kullanma.
- Önceki FAIL'den sonra PASS varsa iki revizyonu ve değişikliği ayır.
- Kaynak değişince eski onayın geçersiz olduğunu belirt.
- İlgisiz ham dosya, token, kullanıcı belgesi veya tüm konuşma geçmişini ekleme.
- Geri alma ihtiyacı varsa neden ve task-owned kapsamı belirt; “test FAIL” otomatik rollback kararı değildir.
- Denetçinin kaynak değiştirmemesi test/cache çıktısı üretmediği anlamına gelmez; geçici yan etkileri açıkla.

Ortak varsayılanlar [framework.json](../../.agents/framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
