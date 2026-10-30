# Görev timi akışını tamamlama

30 Ekim 2026: Kullanıcı, doğrulanan arşiv filtresi ve tarih değiştirme hatalarının
doğru akışla düzeltilmesini yetkilendirdi. Flutter/Drift/Riverpod korunur.

## Karar

- Arşiv kartı ve detay filtresi aynı gorevTimId snapshotını kullanır. Personelin
  bugünkü timi, aktifliği veya silinmesi geçmiş kartı başka time taşımaz.
- Tarih değişikliği önizlemesi ve yazımı ortak tarihli görev timi resolver'ını
  kullanır: bugün/gelecekte mevcut tim, geçmişte tarihli üyelik geçmişi.
- Yeni tarihte çözülen tim kayıttakiyle aynıysa snapshot korunarak tarih değişir.
  Tim farklı/belirsizse veya eski snapshot bilinmiyorsa açık seçim gerekir.
- Açık seçim yalnız taşınan faaliyet atamalarının snapshotını değiştirir;
  personel üyeliği, üyelik geçmişi ve diğer faaliyetler değişmez.
- İptal, conflict, stale tarih/assignment veya geçersiz seçimde yazım olmaz.
- Tarih değiştirme yalnız admin; UI seçilen tarihle doğrulama sonucunu bağlar,
  commit öncesi transaction içinde veriler yeniden kontrol edilir.

## Yaklaşımlar

Eski snapshotı koşulsuz yeni güne taşımak yanlış döneme tim yazar. Güncel timi
sessizce uygulamak geçmişi yeniden sınıflandırır. Seçilen çözüm: eşleşeni koru,
farklı/belirsizi kullanıcıya seçtir, tarih ve snapshotları atomik yaz.

Public tarih değiştirme çağrıları actor alır; preview sonucu doğrulama gereken
personnel ID kümesini taşır. Yeni şema, dependency, backfill, commit/push/APK/yayın yok.
