# Devre kesici ve güvenli kurtarma — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026.

Amaç aynı başarısız yaklaşımda kontrolsüz tekrar ve kaynak kaybını durdurmaktır. Devre kesilmesi otomatik dosya silme veya genel reset anlamına gelmez.

## Tetikleyiciler

| Durum | Tepki |
|---|---|
| Aynı hata parmak izinde 3 başarısız düzeltme | TRIPPED; teşhis ve farklı plan |
| 30 araç işlemi veya 15 dakika | PAUSED; kanıtlı kontrol noktası |
| Yetkisiz erişim/secret açığa çıkması/kullanıcı verisi riski | Derhal dur; ilgili etkileri sınırla |
| Beklenmeyen bütçe veya üretim yan etkisi | Yeni yan etkiyi durdur; kapsamı bildir |
| Araç/erişim eksikliği | BLOCKED görev durumu; sahte tekrar döngüsü yok |

Hata parmak izi: kontrol/test ID + kök hata sınıfı + etkilenen bileşen. Başarısız düzeltme girişimi, aynı sorunu çözmek için yapılan anlamlı değişiklik ve ardından başarısız doğrulamadır. TDD'nin beklenen ilk kırmızı testi veya yalnız log okuma sayılmaz.

## Durum modeli

READY → RUNNING → PAUSED veya TRIPPED → RECOVERING → RUNNING/CLOSED.

Bütçe yenileme eski sayacı silmez. Koordinatör yeni hipotez, daralan kapsam ve ek sınırı kaydeder. Kullanıcı yetkisi içinde kalan rutin yeniden planlama için tekrar onay gerekmez.

## Durduğunda

1. Yeni yazma/yan etkiyi kes. Yalnız görevine ait process/session kimliklerini durdur.
2. Cwd, başlangıç ve mevcut revision, dirty/untracked envanteri, güvenli log ve test sonucunu koru.
3. Kullanıcı değişiklikleriyle görev değişikliklerini ayır; sahiplik belirsizse geri alma yapma.
4. Kök nedeni veya doğrulanacak hipotezi ve sonraki en küçük denemeyi yaz.
5. Güvenli ileri düzeltme, kapsamlı geri dönüş veya izolasyonda bekletme seçeneklerinden uygun olanı seç.

## Geri dönüş matrisi

| Durum | Güvenli yaklaşım |
|---|---|
| Commit edilmemiş yalnız task-owned değişiklik | Diff'i koru; başlangıç içeriğine yalnız sahip olunan değişikliği ters uygula |
| Kullanıcı değişikliğiyle karışmış hunk | Dur; farkı ayrıştır; belirsiz kullanıcı içeriğini ezme |
| Paylaşılmamış checkpoint commit'i | Referansı koru; görev dalında projenin güvenli kurtarma yöntemini kullan |
| Paylaşılmış/merge edilmiş commit | Geçmişi yeniden yazmadan uygun revert/forward-fix; entegrasyon testi |
| Üretim artifact'ı | Doğrulanmış önceki sürüm veya feature flag; veri/şema uyumunu kontrol et |
| DB migration | Kurtarma/forward migration ve yedek doğrulaması; kod rollback'i veriyi geri getirmez |
| Harici mesaj/ödeme/veri aktarımı | Git geri dönüşü etkisizdir; yetkili telafi işlemi ve etki bildirimi |
| Başarısız işçi alanı | Kanıt ve değişiklik korunur; otomatik worktree silme yok |

Genel git reset --hard, git clean -fd, toplu restore veya kapsamı belirsiz recursive silme otomatik kurtarma komutu olarak kullanılmaz. “Temp” adı veya dosya uzantısı yeterli güvence değildir.

## Yeniden başlatma kapısı

Hipotez değişmiş, kabul ölçütü açık, gerekli erişim mevcut ve yeni kaynak bütçesi kayıtlı olmalı. Aynı yamayı başka ajana vermek tek başına yeni yaklaşım sayılmaz.

Yeni denemede test sonucu ilgili revision'a bağlanır. PASS yalnız belirlenmiş kontrol içindir. Kullanıcı verisi veya üretim etkisi varsa bağımsız inceleme ve yayın kapısı ayrıca tamamlanır.

## Kullanıcıya rapor

Yapılan iş, tetikleyici, korunan değişiklik/kanıt, tamamlanabilen bölüm, gerçek engel ve sonraki somut adım verilir. “Geri alındı” yalnız geri alma gerçekten uygulanıp sonucu doğrulandıysa yazılır.

[Görev defteri](../templates/task.md) · [Güvenlik](../policies/security.md)

Ortak varsayılanlar [framework.json](../framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
