# Modern Uygulama Bildirimleri Tasarımı

## Amaç

Uygulama genelinde ekranın altından çıkan `SnackBar` bildirimlerini kaldırmak ve tüm geri bildirimleri modern, tutarlı, erişilebilir bir üst bildirim kartı üzerinden göstermek.

## Kullanıcı Deneyimi

- Bildirimler mobil ve tablet ekranlarda güvenli alanın altında, üst orta konumda görünür.
- Geniş ekranlarda bildirimler sağ üstte görünür.
- Bildirim kartı sayfa düzenini itmeden içerik üzerinde yüzer.
- Kart ekrana kısa bir kayma ve solma animasyonuyla girer; kapanırken ters animasyonu kullanır.
- Başarı, hata, uyarı ve bilgi durumları farklı ikon, vurgu rengi ve erişilebilir anlamla ayrılır.
- Bildirim metni birden fazla satıra yayılabilir ancak kart ekran genişliğini aşmaz.
- Kullanıcı kartı kapatma düğmesiyle anında kaldırabilir.
- Mevcut `GERİ AL` gibi bildirim eylemleri korunur.
- Aynı anda yalnızca bir bildirim gösterilir. Yeni bildirimler sıraya alınır; tekrar eden eşdeğer bildirimler gereksiz yığılmayı önlemek için birleştirilir.
- Bilgi ve başarı bildirimleri kısa süre, uyarılar daha uzun süre görünür. Hatalar kullanıcıya okumak için yeterli süre tanır.
- Uygulamada alttan çıkan kullanıcı bildirimi kalmaz.

## Mimari

### Bildirim modeli

Ortak model aşağıdaki bilgileri taşır:

- mesaj
- tür: `success`, `error`, `warning`, `info`
- isteğe bağlı eylem etiketi ve callback
- isteğe bağlı özel görünme süresi
- otomatik oluşturulan veya çağıran tarafından verilen benzersiz kimlik

### Bildirim yöneticisi

Tek bir uygulama düzeyi yönetici, bildirim kuyruğunu ve görünür bildirimi yönetir. Çağıran ekranlar overlay ayrıntılarını bilmez; yalnızca semantik `showSuccess`, `showError`, `showWarning` veya `showInfo` çağrılarını kullanır.

Yönetici şu davranışlardan sorumludur:

- yeni bildirimi kuyruğa eklemek
- eşdeğer tekrarları engellemek
- süre dolduğunda sıradaki bildirime geçmek
- eyleme basıldığında callback'i bir kez çalıştırmak
- ekran veya rota değişse bile geçerli uygulama bağlamında bildirim göstermek

### Sunum katmanı

`MaterialApp.router` seviyesine yerleştirilen bir overlay host, görünür bildirim modelini dinler ve kartı ekrana çizer. Konumlandırma ekran genişliğine göre responsive olarak belirlenir. Kart renkleri doğrudan sabitlenmek yerine mevcut açık ve koyu tema renkleriyle uyumlu yüzey ve vurgu renklerinden oluşturulur.

Bu sınır sayesinde görünüm ileride değiştirilebilir; özellik ekranlarındaki çağrılar etkilenmez.

## Geçiş Stratejisi

1. Ortak bildirim modeli, yönetici ve overlay host eklenir.
2. Önce bileşenin davranış testleri yazılır ve başarısız oldukları doğrulanır.
3. Uygulama köküne host bağlanır.
4. `lib/` altındaki tüm doğrudan `ScaffoldMessenger`, `showSnackBar` ve kullanıcıya dönük `SnackBar` çağrıları ortak API'ye taşınır.
5. Bildirim içindeki eylemler ve mevcut mesaj metinleri korunur.
6. Kaynak taramasıyla alttan bildirim üreten doğrudan çağrı kalmadığı doğrulanır.

Geçiş yeni bir üçüncü taraf pakete ihtiyaç duymaz; Flutter'ın overlay, animasyon ve tema altyapısı kullanılır.

## Hata ve Yaşam Döngüsü Davranışı

- Geçersiz veya artık bağlı olmayan bir widget bağlamı bildirim sistemini düşürmez; uygulama düzeyi host kullanılır.
- Eylem callback'i hata verirse kuyruk kilitlenmez ve sonraki bildirim gösterilebilir.
- Host henüz hazır değilse bildirim kısa süreli kuyrukta tutulur.
- Hızlı art arda gelen bildirimler animasyonu veya zamanlayıcıyı çakıştırmaz.
- Uygulama kapanmış ya da widget ağacı kaldırılmışsa bekleyen zamanlayıcılar temizlenir.

## Erişilebilirlik

- Tür yalnızca renkle anlatılmaz; ikon ve uygun semantik etiket kullanılır.
- Metin ve eylem renkleri açık/koyu temada yeterli kontrast sağlar.
- Büyük yazı ölçeğinde kart içeriği kesilmez.
- Kapatma ve eylem hedefleri dokunmaya uygun minimum boyutta olur.
- Ekran okuyucuya yeni bildirimin içeriği canlı bölge olarak duyurulur.
- Azaltılmış hareket tercihi etkinse animasyon süresi azaltılır.

## Test Stratejisi

Widget ve birim testleri aşağıdaki davranışları kapsar:

- bildirim mobilde üst ortada, geniş ekranda sağ üstte görünür
- dört bildirim türü doğru ikon ve semantik bilgiyi üretir
- otomatik kapanma süresi çalışır
- kapatma düğmesi kartı kaldırır
- eylem callback'i yalnızca bir kez çalışır
- art arda gelen bildirimler sırayla gösterilir
- eşdeğer tekrarlar yığılmaz
- açık/koyu tema ve büyük metin ölçeğinde taşma oluşmaz
- uygulama kaynaklarında doğrudan kullanıcı `SnackBar` çağrısı kalmaz

Uygulama sonunda `flutter analyze` ve tam `flutter test` paketi çalıştırılarak regresyon kontrolü yapılır.

## Kapsam Dışı

- İşletim sistemi push bildirimleri
- Kalıcı bildirim merkezi veya bildirim geçmişi
- Sunucudan gelen gerçek zamanlı bildirimler
- Ekran içindeki kalıcı uyarı panellerinin değiştirilmesi

Bu çalışma yalnızca geçici, kullanıcı etkileşimine yanıt olarak gösterilen uygulama içi bildirimleri kapsar.
