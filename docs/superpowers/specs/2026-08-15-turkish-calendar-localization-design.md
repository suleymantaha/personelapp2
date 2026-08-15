# Türkçe Takvim Yerelleştirmesi Tasarımı

## Amaç

Uygulamadaki tüm Material tarih seçicilerin Türkçe metinler, Türkçe ay ve gün adlarıyla görüntülenmesini ve takvim haftasının pazartesi gününden başlamasını sağlamak.

## Mevcut Durum ve Kök Neden

Uygulama `intl` ile `tr_TR` tarih biçimlendirme verisini başlatıyor; ancak kök `MaterialApp.router` içinde Flutter'ın yerelleştirme delegeleri, desteklenen locale listesi ve uygulama locale'i tanımlı değil. Bu nedenle `showDatePicker` çağrıları varsayılan İngilizce `MaterialLocalizations` kullanıyor. Mevcut yedi tarih seçici çağrısının hiçbirinde ayrıca locale tanımlanmamış.

## Seçilen Yaklaşım

Yerelleştirme uygulamanın kökünde merkezi olarak yapılandırılacak:

- Flutter SDK'dan `flutter_localizations` bağımlılığı eklenecek.
- `MaterialApp.router` için locale `tr_TR` olarak sabitlenecek.
- Material, Widgets ve Cupertino global localization delegeleri tanımlanacak.
- Desteklenen locale listesi yalnızca `tr_TR` içerecek.

Bu yapı sayesinde mevcut ve gelecekte eklenecek, uygulama ağacından açılan tüm Material tarih ve saat seçiciler aynı Türkçe bağlamı devralacak. Tek tek `showDatePicker` çağrılarına locale eklenmeyecek.

## Beklenen Davranış

- `Select date`, `Cancel`, `OK` gibi metinler Türkçe karşılıklarıyla gösterilir.
- Ay ve gün adları Türkçe gösterilir.
- Gün başlıkları pazartesiden başlayıp pazarla biter.
- Uygulamanın mevcut tema, router, bildirim host'u ve tarih kayıt formatları değişmez.
- Tarih seçicilerin `firstDate`, `lastDate`, başlangıç tarihi ve seçim işleme davranışları korunur.

## Test Stratejisi

Önce kök uygulama için başarısız bir widget regresyon testi yazılacak. Test, uygulamanın sağladığı `MaterialLocalizations` nesnesinde:

- Türkçe locale'in etkin olduğunu,
- tarih seçici eylem metinlerinin Türkçe olduğunu,
- haftanın ilk günü indeksinin pazartesiyi gösterdiğini

doğrulayacak. Ardından minimal üretim değişikliği uygulanacak ve hedef test, formatlama, statik analiz ile ilgili testler çalıştırılacak.

## Kapsam Dışı

- Uygulamaya çalışma zamanında dil seçimi eklemek.
- Tarihlerin veritabanı veya API saklama formatlarını değiştirmek.
- Özel takvim widget'ı veya özel localization delegate yazmak.
- Takvimlerle ilgisiz ekran metinlerini yeniden düzenlemek.
