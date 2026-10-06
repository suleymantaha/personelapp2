# Heybet: Aynı Gün Kart Seçimi, Baskı ve İmza Alanları — Değişiklik Planı

Tarih: 06.10.2026
Durum: Planlama tamamlandı; uygulama kodu değiştirilmedi.
İncelenen depo: suleymantaha/personelapp2
İncelenen main: eb3e049d43cdf8c7b8139b2e448cb6aef7b7111f

## Amaç ve kapsam

Açılan Heybet kartını, kullanıcının aynı gün için seçtiği diğer kartlarla ve önceki günden seçtiği kartlarla tek çıktı halinde birleştirmek. Basılı personel listesinin altına tanzim ve tasdik imzalarını koymak. Toplam bölümü Excel’de dijital kullanım için kalacak; PDF ve yazdırma çıktısında yer almayacak. Yaklaşık 95 kişilik listeyi okunabilir biçimde iki A4 sayfasında, tek yaprağın ön ve arka yüzüne basılabilecek şekilde düzenlemek.

İlk teslim birleşik Excel akışını genişletir. Birleşik PDF ve doğrudan yazdırma aynı satır kaynağını kullanacak şekilde takip eden görevde tamamlanır. Normal listelerin personel içeriği ve geçmişten ekleme davranışı korunur. Veritabanına yeni atama yapılmaz; iki gün süren X kaydı yeniden üretilmez.

## Kodda doğrulanan mevcut durum

- combined_heybet_excel_service.dart yalnızca D−1 gününün kartlarını listeliyor ve seçilen önceki gün kayıtlarını ana kartın altına ekliyor.
- previous_day_excel_picker.dart önceki gün için tek seçim kümesi döndürüyor.
- activity_detail_sheet.dart içindeki shareSeparateCombinedExcel bu seçimi alıyor ve ayrı Excel paylaşıyor.
- Birleşik çıktıda BİRLİĞİ değeri J.Komd.Öz.Hrk.Tb.Klığı; DİĞER boş. Başlık dışındaki hücreler birleşmiyor. Bu davranış korunacak.
- Arşivde aynı gün kart seçimi zaten var; fakat dünkü ayrı Heybet Excel akışına bağlı değil. Bu nedenle yeni bağımsız bir arşiv seçimi sistemi kurmak gerekmiyor.
- Excel toplam kutularını A:F alanına yazıyor; baskı alanı personelin son satırında A:E olarak bitiyor. Toplam bölümü baskı dışında tutulacak. İmzalar personel listesinden hemen sonra, toplam ise imza bloğunun ardından baskı alanı dışında yer alacak.
- PDF 32 satırlık parçalara ayrılıyor; 32 satır üstünde özet için ayrıca sayfa açılıyor. 95 kişilik iki sayfa hedefi mevcut PDF düzeniyle sağlanamaz.
- Excel baskı ayarında fitToWidth=1 ve fitToHeight=0 var. Kullanıcının gözlemlediği iki sayfalık çıktı Excel olabilir; örnek dosya ölçümü yapılmadan aynı sonuç PDF için varsayılmayacak.

## Seçim ve çıktı davranışı

1. Heybet kartından “Kartları Birleştir ve Çıktı Al” açılır.
2. Ana kart seçili ve sabittir; aynı kartın ikinci kez eklenmesi engellenir.
3. Tek seçim penceresinde iki bölüm gösterilir:
   - Aynı Günün Kartları: ana kart hariç, ana kartın tarihindeki diğer faaliyetler.
   - Önceki Günün Kartları: ana kart tarihinden bir takvim günü önceki faaliyetler.
4. Ek kartlar otomatik seçilmez. Yalnızca aynı gün, yalnızca önceki gün veya iki bölüm birlikte seçilebilir.
5. Seçimler ayrı kümelerde tutulur. Önceki gün listesi boşsa aynı gün seçimi kullanılabilir. Hiç ek kart seçilmemişse ana kartla devam edilebilir.
6. Sıra: ana Heybet → seçilen aynı gün kartları → seçilen önceki gün kartları. Her bölümde mevcut görev/rütbe sıralaması korunur; sıra numarası sonuçta baştan kesintisiz üretilir.
7. Önizleme kart tarihlerini, dahil edilen satırları ve tekrarları gösterir.
8. Önizleme sonrasında Excel, PDF veya yazdırma seçilir; hepsi aynı doğrulanmış satır listesini kullanır.
9. Son adım öncesinde kayıtlar ve yetki yeniden okunur. Silinen kartlar, değişen yetki veya boş sonuç için açık mesaj gösterilir.

Kesin tekrar politikası: aynı personel seçilmiş kaç kartta bulunursa bulunsun birleşik çıktıda yalnızca bir satır yer alır. Tekilleştirme ad-soyad üzerinden değil personelId üzerinden yapılır; aynı isimli farklı personeller korunur. Kaynak önceliği ana Heybet → seçilen aynı gün kartları → seçilen önceki gün kartlarıdır; aynı bölümde mevcut görev/rütbe sıralamasındaki ilk kayıt kullanılır. Atama ID tekrarları da dışlanır. Tekilleştirme sonrası sıra numaraları 1’den kesintisiz üretilir. Önizleme, Excel, PDF ve yazdırma aynı tekilleştirilmiş listeyi kullanır; dijital toplam bu liste üzerinden hesaplanır. Önizlemede kaç tekrarın elendiği gösterilebilir; bunun için kullanıcıya yeniden seçim yaptırılmaz. Kaynak atamalar ve X geçmişi değişmez.

Yetki kontrolü yalnızca personelin bugünkü timine dayanmaz; mevcut oturum ve atamanın görev timiyle de doğrulanır. Bekleyen/reddedilen ve operasyonel olmayan atamalar mevcut filtreye göre dahil edilmez.

## İmza düzeni

Son basılı sayfada personel listesinin altında, yan yana iki blok. Baskıda toplam kutuları bulunmayacak:

| Sol: TANZİM EDEN | Sağ: TASDİK EDEN |
| --- | --- |
| İhsan DAĞLI | Serdar YILDIZ |
| J.Asb.Kd.Bçvş. | J.Yb. |
| Eğt.Hrk. ve İsth.Ks.A | J.Komd.Öz.Hrk.Tb.K. |

Başlık ile isim arasında el ile imza için boşluk ayrılır. İki imza bloğu birlikte tutulur; birinin diğer sayfaya bölünmesine izin verilmez. İmzalar yalnızca son sayfada bir kez yer alır. İlk kapsam birleşik Heybet çıktısıdır; diğer raporlara aynı kişilerin otomatik eklenmesi yapılmaz.

İmza metinleri tek ortak yapıdan okunur. PDF ve Excel farklı kopyalar tutmaz; metinler rütbe normalleştirmesiyle değiştirilmez.

## Baskı kararı

Önerilen düzen: A4 dikey, bir sayfa genişliği; ikinci sayfanın sonunda yalnızca imza alanları; toplam bölümü baskıda bulunmaz. Ön ve arka sayfada başlık/sütun başlıkları tekrarlanır. Sıra numarası kesintisiz devam eder.

İki sayfaya sığdırma yalnızca satır sayısına dayanmaz. Uzun adlar, görev metinleri, satır yüksekliği, başlıklar ve imza boşluğu hesaba katılır. 95 ve 100 kişilik gerçekçi örneklerle okunabilirlik ölçülür. Son sayfa için yalnızca imza yüksekliği önceden ayrılır.

- Excel: personel tablosu → imza bloğu → dijital toplam bölümü sırası kullanılır. Baskı alanı A:E ile son imza satırında biter; toplam bölümü bunun dışında kalır. Ayrı baskı aralıkları kullanılarak imzaların gereksiz yeni sayfaya düşürülmesinden kaçınılır. İki sayfa ölçekleme ancak metinlerin okunabilir kaldığı doğrulanırsa seçilir.
- PDF: birleşik Heybet çıktısında toplam/özet oluşturulmaz. Sabit 32 satır ve zorunlu özet sayfası yerine kullanılabilir yüksekliğe göre sayfalama yapılır. Kompakt düzende yazı boyutu 8.5 punto altına indirilmez; uzun hücreler ölçülür ve gerektiğinde ek sayfaya geçilir. 95 kişinin her durumda iki sayfaya sığacağı garanti edilmez.
- Son sayfada imzaya yer kalmadığında imzayı tek başına üçüncü sayfaya bırakmak yerine son personel satırlarıyla birlikte yeni sayfaya taşıma tercih edilir.
- Ön/arka basım yazıcı iletişim kutusundan seçilir; dosya bunu zorlayamaz. A4 dikey için uzun kenardan çevirme kullanılmalıdır.

## Değişecek dosyalar

Aşağıdaki yollar lib/features/activity/ altındadır.

| Dosya | Sorumluluk |
| --- | --- |
| presentation/dialogs/previous_day_excel_picker.dart | Aynı gün/önceki gün bölümleri, ayrı seçim kümeleri, kaynak gösteren önizleme |
| presentation/widgets/activity_detail_sheet.dart | Yeni seçim akışını bağlama, ana kartı koruma, çıktı seçeneklerine geçiş |
| services/combined_heybet_excel_service.dart | Aynı gün kart sorgusu, tarih/ID doğrulaması, birleşik satır kaynağı, personelId ile tekilleştirme ve yetki kontrolleri |
| services/military_roster_exporter.dart | Birleşik çıktıya isteğe bağlı imza/baskı ayarlarını iletme |
| services/exporter/excel_xlsx_generator.dart | Excel oluşturucu arayüzüne isteğe bağlı çıktı ayarlarını taşıma |
| services/exporter/excel_xlsx_military_generator.dart | Personelden sonra imza, ardından baskı dışında toplam yazma; son imza satırını baskı sonu olarak hesaplama |
| services/exporter/excel_xlsx_support.dart | Baskı alanı, sayfa ayarları, ortak Excel imza çizimi |
| services/pdf_roster_exporter.dart | Birleşik çıktı ve baskı ayarlarını PDF arayüzüne taşıma |
| services/pdf_roster_document.dart | Birleşik Heybet için toplam/özeti baskıdan çıkarma, imzayı son sayfaya yerleştirme |
| services/pdf_roster_styles.dart | Yüksekliğe göre sayfalama, kompakt tablo, son sayfa alan rezervi |

Yeni dosya önerisi: services/roster_signature.dart — isim, rütbe, görev ve başlıkları içeren ortak imza modeli; birleşik Heybet için belirtilen varsayılanlar.

Mevcut dosya adları ilk aşamada korunur; yalnızca sınıf ve menü adları genişletilen kapsamı anlatır. Arşiv ekranı, veritabanı şeması ve X hesaplama kodu bu değişikliğin uygulama kapsamına dahil değildir. Uygulama sırasında ihtiyaç doğarsa plan güncellenir.

## Uygulama sırası ve doğrulama

### 1. Aynı gün seçimi ve birleşik veri

- [ ] Aynı gün, önceki gün ve karma seçimin mevcut servis testlerine senaryolarını ekle.
- [ ] Ana kartın yeniden seçilmesini, başka tarihe ait ID'yi ve geçersiz ID'yi dışlayan doğrulamaları ekle.
- [ ] Servisi ve seçim penceresini genişlet; mevcut önceki gün testlerini koru.
- [ ] Aynı kişi iki/üç kartta ve iki tarihte varsa tek satır; aynı ad-soyada sahip farklı personelId değerleri varsa ayrı satırlar üretildiğini test et.
- [ ] Ana kart → aynı gün → önceki gün önceliğini, tekilleştirme sonrası kesintisiz sıra numarasını ve tekil toplamı doğrula.
- [ ] Yetkisiz tim, onaysız kayıt, ay/yıl geçişi, boş önceki gün ve değişen kayıt testlerini çalıştır.
- [ ] İşlem öncesi/sonrası atama ve faaliyet tablolarını karşılaştır; iki günlük X'in değişmediğini doğrula.

Testler: test/unit/combined_heybet_excel_service_test.dart
ve test/features/activity/separate_heybet_excel_test.dart.

### 2. Excel imzası ve toplamı dışlayan baskı alanı

- [ ] Ortak imza modelini ekle; belirtilen metinleri birebir koru.
- [ ] Birleşik çıktı için personel listesinin altında iki imza bloğu üret; dijital toplam bölümünü imzalardan sonraya yerleştir.
- [ ] Baskı alanının personeli ve tüm imza satırlarını içerdiğini, toplam satırlarını dışladığını OpenXML üzerinden doğrula.
- [ ] Personel hücreleri, başlık ve toplam kutularının mevcut birleştirme davranışlarını kontrol et.
- [ ] 95/100 kişi ve uzun isimli örnek dosyalarla iki sayfa baskı önizlemesini ölç.

Test: test/unit/military_roster_exporter_test.dart.
İmza desteği birleşik Heybet çağrısında etkinleştirilir; genel oluşturucuya isteğe bağlı parametreyle taşınır.

### 3. PDF ve doğrudan yazdırma

- [ ] Birleşik veriyi yeniden kullanarak PDF/paylaş/yazdır seçeneklerini bağla.
- [ ] Birleşik Heybet PDF’sinde toplam/özeti dışla; son sayfa için imza yüksekliği ayır ve 32 satır sınırını ölçüme dayalı sayfalamayla değiştir.
- [ ] 0, 1, 32, 33, 95, 100 ve 120 satırla sayfalama testlerini ekle.
- [ ] Uzun ad/rütbe/görev metinleri, sayfa arasında bölünen timler, tek imza bloğu, sıra numarası ve taşma durumlarını doğrula.
- [ ] Üretilmiş PDF'leri görsel olarak incele; sayfa sayısı ve imza metinlerini kontrol et.

Test: test/unit/pdf_roster_exporter_test.dart.

### 4. Son kontrol ve teslim

- [ ] İlgili servis/widget testleri ve flutter analyze.
- [ ] flutter test ile genel regresyon kontrolü.
- [ ] Mevcut CI çalıştırılır; sonucu görülmeden başarılı olduğu söylenmez.
- [ ] Android'de seçimden geri dönme, önizlemeyi kapatma, paylaşım/yazdırma sonrası ekrana dönüş kontrol edilir.
- [ ] 95 kişilik çıktı gerçek yazıcıda ön/arka kontrol edilir; fiziksel test yapılamadıysa bu açıkça belirtilir.

## Kabul ölçütleri

- Ana kart + seçilen aynı gün kartları + seçilen önceki gün kartları aynı dosyada yer alır.
- Birlik metni ve boş DİĞER davranışı korunur.
- Kaynak kayıtlar ve iki günlük X işaretleri değişmez.
- Personel listesi ve belirtilen imzalar baskıda görünür; toplam kutuları PDF/yazdırmada bulunmaz. Excel’de toplam bilgisi baskı alanının dışında korunur.
- 95 kişilik standart örnekte iki sayfa hedefi değerlendirilmiş ve ölçülmüş olur; taşan uzun metinler kesilmez.
- Aynı personel tüm seçilmiş kartlarda toplam bir kez görünür; tekilleştirme personelId ile yapılır.
- Önizleme, Excel, PDF ve yazdırma aynı tekilleştirilmiş listeyi kullanır.
- İptal/geri/paylaşım dönüşünde ekran kullanılabilir kalır.

## Kesinleşen kullanıcı kararları

- Toplam bölümü yazdırılmaz; imzalar yazdırılır.
- Aynı kişi birden fazla seçilmiş kartta olsa da çıktıda yalnızca bir kez görünür.
- Kaynak kayıtlar ve iki günlük X işaretleri değiştirilmez.
