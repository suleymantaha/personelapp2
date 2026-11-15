# Geçmiş tarihte otomatik tim seçimi

| Alan | Karar |
|---|---|
| Görev | 2026-11-15-personnel-team-history-json |
| Kabul | Arşiv ataması, görev tarihindeki doğrulanmış timi otomatik kaydeder. |
| Kademe | Tier 2. Yedekleme ve atama akışı etkilenir. Veritabanı şeması aynıdır. |
| Baz | `f69ae9eee5ad6ce4c2f8bce5b5872e24ae79ac44` |
| Sözleşme | Personel JSON v1. `membershipHistory` isteğe bağlıdır, kaynak personel ve tim kimlikleri geri yüklemede eşleştirilir. |
| Kapsam | Yerel regresyon, sürüm artışı, PR üzerinde Android CI. |

- Yedek aynı veritabanı işlemi içinde personeli, timleri ve üyelik hareketlerini okur.
- Eski yedekte yalnız mevcut tim varsa, geçerli yedek tarihinde başlangıç hareketi oluşturulur. Daha eski tarih için onay gerekir.
- Önceden içe alınmış personelde benzersiz ad, rütbe ve kayıt günü eşleşmesi aranır. Yeniden içe aktarma yalnız yerel geçmiş başlamadan önceki boşluğu doldurur.
- Yeni personel ve üyelik geçmişi aynı işlemde geri yüklenir. Tekrar içe aktarım yeni hareket üretmez.
- Android sürüm kodu, önceki imzalı APK'da doğrulanan 10335'in ardından 10336 olarak ayarlandı.

| Kontrol | Durum |
|---|---|
| Yeni regresyonların değişiklik öncesi sonucu | RED, eski uygulama arşiv atamasında görev timini bulamadı. |
| Yeni ve ilgili regresyonların değişiklik sonrası sonucu | 34 PASS, 0 FAIL. Windows'ta aynı testler yerel Flutter test motorunda çalıştırıldı. |
| Android CI | PR üzerinde takip edilecek. |
| İmzalı APK yerinde güncelleme | NOT_RUN. |
