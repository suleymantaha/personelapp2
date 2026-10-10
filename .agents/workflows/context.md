# Bağlam ve çalışma devri — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026.

Amaç, karar için gerekli kanıtı koruyup gereksiz tekrarları azaltmaktır. Kısa rapor tek başına doğruluk veya düşük maliyet garantisi değildir.

## Hedefli okuma

Önce dosya/sembol araması yap; sonra ilgili işlev, çağıran, test ve yapılandırmayı oku. Tam dosya okumak gerektiğinde yasak değildir; sırf satır sayısını azaltmak için önemli sözleşmeyi atlama.

Aynı içeriği sebepsiz tekrar getirme. Revizyon değişmişse veya yeni bilgi mevcut sonucu etkiliyorsa yeniden oku. Hatırlanan eski plan, güncellenmiş dosyanın yerine geçmez.

## Delege edilen bağlam

Görev hedefi, izinli yollar, revision, sözleşme, kabul testleri, bütçe ve yasak yan etkiler yeterlidir. Tüm sohbeti, bütün kaynak kodu veya secret'ları devretme.

Keşif ajanı yalnız bağımsız araştırmanın faydası maliyetini karşılıyorsa kullanılır. Küçük bir aramayı sırf “keşif” diye delege etme. İşçi sınırlarını değiştiren yeni bilgi koordinatöre geri bildirilir.

## Kanıtı özetleme

- Büyük logun güvenli kopyası tutulur; raporda komut/cwd/exit code/test özeti ve bağlantı verilir.
- Hata özetlenirken neden zinciri ve gerekli stack bölümü korunur; sadece ilk beş satırın yeterli olduğu varsayılmaz.
- Veri/secret önce maskelenir. Maskeleme yapılmadan harici depoya veya ajan mesajına kopyalanmaz.
- Kod parçası gerekiyorsa kısa ilgili bölümü göster; “ham kod asla gösterilmez” kuralı yoktur.
- “PASS” sonucu incelenen revision'a bağlanır.

## Kontrol noktası / compaction özeti

| Alan | Gereken bilgi |
|---|---|
| Amaç | Kullanıcının güncel hedefi ve korunacak önceki kararlar |
| Yetki | Verilmiş izinler, kapsam dışı ve engellenen işlemler |
| Durum | Tamamlananlar, çalışan görevler, son somut sonuç |
| Kimlik | Repo/cwd, base ve current revision |
| Değişiklik | Sahip olunan yollar ve korunan kullanıcı değişiklikleri |
| Sözleşme | ID/sürüm ve kabul durumu |
| Kanıt | Son test komutları, sonuç, rapor yolları |
| Bütçe | Kullanım, tekrar sayacı, sonraki kontrol noktası |
| Süreç | Açık task-owned process/session ve kapatma yolu |
| Sonraki adım | Tek, somut devam adımı ve gerekli bilgi |

Bağlam özetlenmesi görevi bitirmez; tamamlanmış işi tekrar başlatma. Kullanıcının yeni mesajı açık iptal/değişim değilse mevcut işin yönlendirmesi olarak ele alınır.

## Token ve maliyet dürüstlüğü

Araç gerçek kullanım gösteriyorsa bunu kaydet. Göstermiyorsa token/dolar sayısı uydurma; ajan sayısı, araç işlemi ve süre gibi gözlenebilir ölçüleri kullan. Sabit sayı sınırına uymak için doğrulama adımını atlama; kapsamı veya yürütme biçimini yeniden planla.

[Görev raporu](../templates/report.md)

Ortak varsayılanlar [framework.json](../framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
