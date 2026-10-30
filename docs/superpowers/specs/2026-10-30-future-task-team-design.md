# Bugünkü ve ileri tarihli görevlerde tim seçimini hızlandırma

Kullanıcı 30 Ekim 2026 tarihinde mevcut tim üyeliklerinin kesin olduğunu belirtti
ve doğrulamanın yalnız timi bilinmeyen geçmiş tarihlerde açılmasını onayladı.

- Bugün ve ileri tarihler: açık görev timi tercihi varsa korunur; yoksa personelin
  mevcut timi (veya gerçek Tim dışı durumu) görev kaydına snapshot olarak yazılır.
- Geçmiş tarih: güvenilir tarihli üyelik geçmişi kullanılır; belirsizse mevcut
  doğrulama penceresi ve transaction koruması devam eder.
- Sonraki tim/isim değişiklikleri kaydedilmiş snapshotları değiştirmez.
- Yetki kapsamı, tarih doğrulama ve stale-date kontrolleri korunur.
- Var olan dolu/boş arşiv kayıtları, üyelik geçmişi ve migration değiştirilmez.

## Yaklaşımlar ve karar

UI kontrolünü atlamak repository reddini çözmez. Her tarihi güncel timle
doldurmak geçmişi yanlış sınıflandırır. Onaylanan çözüm, ortak resolver'da
bugünkü tim yolunu ileri tarihlere de uygulamak; geçmiş resolver'ı korumaktır.

Flutter/Drift/Riverpod korunur; dependency, şema, APK, push veya yayın yoktur.
