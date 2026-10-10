# Etkiye göre görev sınıflandırma — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026.

Risk kademesi ile ajan sayısı farklı kararlardır. İki dosya değiştirmek otomatik olarak orkestrasyon gerektirmez; tek satırlık yetki açığı Tier 3 olabilir.

## Karar matrisi

| Ölçüt | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| Etki | Yerel, düşük, geri alınabilir | Birden fazla davranış veya ortak sınır | Veri, yetki, para, üretim veya güven sınırı |
| Örnek | Yazım, küçük stil, sınırları belli düzeltme | Yeni akış, API tüketicisi, davranış refactor'u | Sahiplik, ödeme, yıkıcı migration, dosya sandbox'ı |
| Plan | Kısa kabul notu | Bağımlılık ve iş paketleri | Tasarım, tehdit/veri akışı ve kurtarma |
| Takip | Gerekirse tek kayıt | Görev defteri | Defter + risk/karar kayıtları |
| Test | Değişen davranışa uygun | Sözleşme, regresyon ve entegrasyon | Negatif, yarış, izolasyon ve kurtarma |
| İnceleme | Öz denetim çoğunlukla yeterli | Etkiye göre bağımsız denetim | Yayından önce bağımsız ilgili inceleme |
| Varsayılan yürütme | Native | Native veya gerekçeli delegated | Native veya gerekçeli delegated |

## Sınıflandırma soruları

1. Kullanıcı verisi veya sır silinebilir, açığa çıkabilir ya da yanlış kişiye verilebilir mi?
2. Para, hak/kota veya hesap yetkisi değişiyor mu?
3. API/şema tüketicileri, migration veya asenkron iş durumu etkileniyor mu?
4. Yanlışlık üretimde geri alınamaz sonuç doğurur mu?
5. Testle sınırlandırılabilir mi; kapsam ve sahiplik anlaşılır mı?

İlk iki soruda anlamlı risk varsa Tier 3 değerlendirilir. Sadece biçimsel değişikliğin güvenlik dosyasına dokunması tek başına Tier 3 uygulama değişikliği değildir; değişen davranış/rehberin etkisi incelenir.

## Yürütme seçimi

Delegasyon için bağımsız iş, ayrı yazma kapsamı, kullanılabilir araç, bütçe ve birleştirme planı gerekir. Aynı sözleşme üzerinde eşzamanlı yazan iki ajan bağımsız değildir.

Native modda ana ajan iş paketlerini sırayla tamamlar. Bağımsız inceleme gerekiyorsa ayrı denetçi veya insan incelemesi kullanılır; öz denetim bağımsızmış gibi adlandırılmaz.

Tahmini token aralıkları gerçek ölçüm olmadan verilmez. Daha fazla ajan daha iyi kalite garantisi değildir; koordinasyon maliyeti ve gecikme hesaba katılır.

## Kademe değişimi

Gizli bağımlılık veya veri/üretim etkisi ortaya çıkarsa daha yüksek kademeye geç; gerekçeyi ve değişen testleri kaydet. İşin tahmin edilenden küçük çıkması, gerekli güvenlik kontrolünü kaldırmak için tek başına gerekçe değildir.

İşletim ayrıntısı: [orkestrasyon protokolü](orchestration.md).

Projeye özgü bağlam ve ek kabul ölçütleri kökteki PROJECT.md içinde tanımlanır.

Ortak varsayılanlar [framework.json](../framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
