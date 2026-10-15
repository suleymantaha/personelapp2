# Tim görev analizi uygulama planı

Base: e56a9754fb13cb716dbd2f72290184f14ecba624. Native yürütme, Tier 2.
Kullanıcı kapsamı ve uygulama talimatı tasarım girdisidir.

## Tasarım ve sözleşme

Mevcut Drift tablolarından salt-okunur, tek transaction içinde tutarlı snapshot alınır.
Yeni tablo, migration, veri giriş ekranı veya mevcut kayıt güncellemesi yoktur.
Görev timi yalnız `gorevTimId` ile belirlenir. Bugünkü üyelik ve isim eşleştirmesi
geçmişe uygulanmaz; eski üyelik geçmişi mevcut migration tarafından kullanılmıştır.
Null timli atamalar ayrı belirsizlik grubunda kalır; komutana gösterilmez.
Komutan kapsamı mevcut kullanıcı/tim çift yönlü ilişkisinden doğrulanır.

Katılım: benzersiz (tim, görev türü, faaliyet ID). Görev günü: kapsanan benzersiz
takvim günü. Personel: benzersiz ID. Personel–görev: benzersiz
(tim, görev türü, faaliyet ID, personel ID). Personel–gün ayrıca tekilleştirilir.
İki günlük görevlerin önceki aydan devamı mevcut DutyCoverage ile hesaplanır.
Katılım başlangıç tarihli ölçüdür; devam eden görev gün üretir, yeni katılım üretmez.
Varsayılan yalnız onaylı operasyonel görevlerdir. Bekleyen/reddedilen durumlar
ayrı filtrelerle incelenir, onaylı toplamlarına karışmaz. İzinler hariçtir.
Farklı faaliyet ID'leri aynı isim/tarihe sahip olsa da ayrı kayıttır; olası tekrar
uyarısı gösterilir, otomatik birleştirilmez. Aynı atama tekrarları tekilleştirilir.
Demo personel hariç; inaktif geçmiş personel dahil. Saat/yük oranı üretilmez.

## İş paketleri

- [x] Gerçek in-memory Drift fixture testleri: çok görev/kişi, tekrar, onay,
  bilinmeyen tim, ay sınırı, eski/inaktif personel, yetki ve salt-okunurluk.
- [x] Immutable analytics modelleri, salt-okunur repository ve hesap servisi.
- [x] Provider, tarih/tim/görev/durum filtreleri; açık/koyu responsive dashboard.
- [x] Görev karşılaştırma çubukları, sıfır ayları içeren trend; tim → görev →
  tarih → faaliyet → personel açılımı. Boş/yükleniyor/hata durumları.
- [x] Widget testleri: dar/geniş ekran, temalar, filtreler ve detay açılımı.
- [x] Android integration testi, analyze, tüm testler, APK, diff incelemesi.
- Entegrasyon kapısı: Feature branch PR CI yeşilse entegrasyon önerisi.
  Main'e otomatik merge/deployment yapılmaz.

## Risk / inceleme odağı

Kimliği farklı mükerrer faaliyetler anlamı doğrulanmadan birleştirilemez.
Silinen timin yalnız adı kaldığında aynı adlı güncel time bağlanamaz.
Onay durumları çelişen tekrarlar ayrı durum dilimlerinde kalır.
Büyük arşivler bounded tarih aralığıyla okunur (en fazla 366 gün).
Yerel test CI ve fiziksel cihaz kabulünün yerine geçmez.

Yerel kabul: 645 unit/widget testi, 4 Android integration testi, temiz analyze, release APK build. Ayrıntı: docs/verification/team-duty-analytics.md.
