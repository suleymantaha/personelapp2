# Güvenli görev timi geçmişi

Kullanıcının 29 Ekim 2026 tarihli kapsam onayının yazılı kaydı.

## Amaç ve sınırlar
Mevcut verileri koruyarak Ayarlardan isteğe bağlı güvenli onarım sağla; yeni atamalarda eksik/yanlış tarihsel tim oluşmasını engelle. Gerçek kullanıcı verisiyle test, canlı onarım, push, yayın ve APK dağıtımı kapsam dışıdır. Flutter/Drift/Riverpod korunur, yeni dependency eklenmez.

## Yaklaşımlar
Sessiz otomatik doldurma belirsiz geçmişi değiştirebileceği için reddedildi. Yalnız manuel tek tek düzenleme tekrar oluşumu engellemez. Kullanıcının onayladığı yaklaşım: önizleme ve doğrulanmış yedekle sınırlı onarım + yazma yollarında tarih kontrolü.

## Veri kuralları
- Yalnız gorevTimId ve gorevTimAdi birlikte null olan eski atamalar adaydır. Dolu alanlar, gerçek Tim dışı ve belirsiz kayıtlar korunur.
- Geçerli tarihli üyelik geçmişiyle tek anlamlı son durum yoksa bilinmiyor sayılır. Aynı gündeki farklı durumlar, geçersiz kayıtlar ve eksik tim referansı otomatik çözülmez. Bugünkü üyelik eski tarihe kanıt değildir.
- Yeni bugünkü atama açık tim tercihi veya güncel tim ile snapshot alır. Geçmiş/farklı tarihte açık görev timi yoksa güvenilir geçmiş gerekir; bulunamazsa açıklayıcı hata ile transaction geri alınır. Açık Tim dışı seçimi desteklenir.
- Transfer aynı gün snapshot korur; tarih değişirse yeniden doğrulama gerekir. Tarih değiştirme belirsiz/dolu snapshotları sessizce yeniden sınıflandırmaz.
- Yeni üyelik olayları tarihli kaydedilir; geçmişteki eksik üyelikler topluca uydurulmaz.
- Yedek geri yükleme mevcut snapshotları değiştirmez; otomatik backfill kaldırılır. Eski migration da aynı temkinli resolver kullanır.

## Onarım ve kurtarma
Yalnız yönetici: değişmeyen ham verinin tutarlı tam yedeği → salt okunur önizleme → dosyaya kaydet → dosyayı yeniden seç ve içeriği doğrula → açık Uygula. Yedek iptal/hata/uyuşmazlıkta yazma yok. Önizleme sonrası veritabanı veya yetki değişirse işlem reddedilir. Adaylar transaction içinde yeniden doğrulanır; sadece önizlenen boş alanlar güncellenir, audit aynı transactionda yazılır. Tekrar çalıştırma idempotenttir. Audit yalnız kayıt ID, eski/yeni tim ve yedek checksum tutar; kişisel veri/log/sır içermez. Tam yedek hassas kalır, üçüncü tarafa gönderilmez.

## Doğrulama
Sentetik in-memory DB ile kesin/belirsiz/tim dışı, dolu alan koruma, yetki, stale preview, yedek iptali/bozukluğu, transaction rollback, idempotency, migration ve backup uyumu; atama/Excel/transfer/date-change regression; widget akışı ve dar testler ardından analyze/full suite. Bağımsız inceleme gerekir.
