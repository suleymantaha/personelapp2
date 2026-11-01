# Audit düzeltmeleri ve APK planı

Base: c16a7e5d4b4cb803d8ec9448d045d08d6a3b9acf.
Dal: fix/audit-hardening-apk-2026-11-01. Risk: Tier 3, yetki/veri/upgrade.

Kullanıcı rapordaki gerekli düzeltmeleri ve APK üretimini yetkilendirdi.
Mevcut görev timi snapshot, geçmiş belirsizliği, METİ/X, çıktı ve arşiv kuralları korunur.
Şema veya backup envelope değişmez; yeni dependency ve büyük refactor yapılmaz.

1. F01/F02/F04: kalıcı hesap/tim bağlantısı, transaction içinde güncel yetki ve
   boş parola için kayıtlı session reddi; önce negatif regression testleri.
2. F03: tek transaction içinde DB snapshot; gerçek ikinci WAL connection ile
   sorgular arasında commit testi; nested repair transaction uyumluluğu.
3. F05: native 50 MiB byte sınırı, arka plan I/O ve yaşam döngüsü güvenliği.
4. Aynı tasarımda dar ekran okunabilirliği ve ortak metin/renk düzeltmeleri;
   kanıtlanmamış dead code silinmez, sırf satır sayısı için dosya bölünmez.
5. Güncel APK/Actions/kurulu test cihazı versionCode ve signer envanteri;
   daha büyük code, aynı applicationId/signer ile release build.
6. Odaklı testler → tam suite → analyze/format → bağımsız inceleme.
7. Ayrı AVD'de önceki imzalı sürüm + sentetik veri/ayar → install -r ile yeni
   release → uygulama açılışı, kayıtlar/ayarlar ve byte fingerprint kontrolü.
8. APK hash/signature/alignment ve açık kalan kapsamı raporla. Main merge,
   store/deploy veya Drive paylaşımı bu istekte yok; ayrıca yapılmaz.

Seçim: mevcut repository/Drift/SharedPreferences sözleşmelerine küçük yamalar.
Toplu mimari refactor ve DB encryption migration'ı bu APK'ya alınmaz; veri
uyumluluğunu ve mevcut çalışma şeklini gereksiz değiştireceğinden ayrı tasarım gerekir.
Dosya sahibi: auth worker ilgili auth/personnel/activity; native worker Kotlin;
ana ajan backup/UI/release/görev kayıtları. Aynı dosyada iki yazar yok.
