# Toplu aktarım doğruluğu

Kullanıcının onayladığı kapsam: mevcut görev/tim, çakışma ve kart mantığını koruyarak OCR isim kaybını ve belirsiz kayıt akışını düzeltmek.

- OCR: METİ hücreleri ad/soyad olmaz; METİ başlığı korunur; rütbe ve arka plan başlığı kişi olmaz. Bölünmüş gerçek soyadları korunur. Testlerde gerçek personel verisi kullanılmaz.
- Görev timi: mevcut üyelik tahmini tarihsel kanıt sayılmaz. Yalnız açık seçim görev snapshot'ına gider; ana üyelik değişmez. Belirsiz kişiler için tek seçim topluca uygulanabilir.
- Tarih: cihazın yerel takvim günü esas alınır. Geçmiş gün veya bugünden **3 günden fazla ileri** gün için kayıttan önce açık onay istenir. Bugün/+1/+2/+3 için ek tarih onayı yoktur. İptal hiçbir kalıcı yazım yapmaz. Onaylanan gün değiştirilmez.
- Hedef kart: mevcut karta aktarım yeni kart açmaz; kaynak tarihi farklıysa hedef tarih sessiz uygulanmaz. Farklı kaynak gününü korumak isteyen kullanıcı genel aktarım yoluna dönmelidir. Aynı tarih+görev için mevcut birleştirme korunur.
- Sonuç: yeni kart/mevcut karta ekleme hedefi görünür; eklenen/zaten kayıtlı/çakışma nedeniyle atlanan kişi sayıları ayrılır. Sıfır kişinin eklenmesi genel başarı diye sunulmaz.

Yaklaşım: OCR'deki aday ayıklama hatasına yerel düzeltme, ortak kayıt öncesi tarih onayı ve mevcut üç adım içinde açıklayıcı hedef/tim bilgisi. Baştan OCR motoru/tablo sistemi yazımı daha geniş değişiklik ve platform riski getirir; mevcut mantığın yeniden tasarımı kapsam dışıdır.

DB şeması, üyelik geçmişi çıkarımı, yetki kuralları, görev kapsam günleri, mevcut personel/kayıtlar değişmez. APK, dağıtım ve main merge kapsam dışıdır.
