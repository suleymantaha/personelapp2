# Guvenli Toplu Aktarim Paneli Design

## Goal

Metinden toplu faaliyet aktarim ekranini, karisik gercek saha listelerini guvenli sekilde yoneten bir denetim paneline donusturmek. Sistem bos kart veya eksik kritik bilgiyle kayda izin vermeyecek; fakat tim disi gorev gibi operasyonel olarak normal durumlari hata saymayacak.

## Source Of Truth

- Mevcut dialog: `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart`
- Dialog aksiyonlari: `lib/features/activity/presentation/dialogs/bulk_import_dialog_actions.dart`
- Kart UI: `lib/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart`
- Onizleme UI: `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_preview_section.dart`
- Kaydetme cubugu: `lib/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart`
- Sorun gezgini: `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart`
- Parser: `lib/features/activity/domain/parser/bulk_text_parser.dart`
- Eslesme: `lib/features/activity/domain/parser/personnel_fuzzy_matcher.dart`
- Ogrenim servisi: `lib/features/activity/domain/bulk_import_learning_service.dart`
- Hazirlayici: `lib/features/activity/domain/bulk_activity_import_preparer.dart`
- Veritabani tablolari: `lib/core/database/tables.dart`
- Gercek metin ornegi: `C:\Users\baba\.codex\attachments\92bac69d-e6d5-435e-99ca-24f68d419d08\pasted-text.txt`

## Scope

### Included

- Toplu aktarim onizleme ekraninda kritik hata, inceleme uyarisi, otomatik duzeltme ve karantina ayrimini netlestirmek.
- Bos kartlarin faaliyet kaydina gitmesini engellemek.
- Personel dogru eslestiyse, kayitli timi farkli diye kaydi engellememek.
- Tim disi gorevleri ayri bir gorev baglami olarak gostermek.
- Kullanici onayladigi tim disi gorev ve isim eslesmelerini sonraki aktarimlarda daha az uyarili hale getirmek.
- Coklu liste aktariminda tarih, tim, gorev, personel ve sorun durumlarini daha okunabilir bir panelde sunmak.
- Mevcut veritabani ve repository kaliplariyla uyumlu ilerlemek.
- Odakli unit/widget testleri eklemek.

### Excluded

- Personelin ana timini otomatik degistirmek.
- Mevcut faaliyet arsivi, aylik matris veya personel yonetimi ekranlarini bastan tasarlamak.
- Yapay zeka servis baglantisi veya uzak sunucu tabanli ogrenim eklemek.
- Tum parser kurallarini tek seferde kusursuz hale getirmeye calismak.
- Mevcut rol/izin modelini degistirmek.

## Problem Model

Toplu aktarim sonucu tek bir "hata var/yok" durumuna indirgenmeyecek. Her bulgu asagidaki siniflardan birine ayrilacak.

### Critical Error

Kaydetmeyi engeller.

- Bos kart.
- Gecerli tarih yok.
- Gorev turu yok.
- Personel hic eslesmedi.
- Ayni personel ayni tarihte cakisacak sekilde birden fazla goreve ataniyor.
- Parser karti faaliyet olarak yazacak kadar guvenilir bilgi uretmedi.

### Review Warning

Kaydetmeyi engellemez, fakat kullaniciya gosterilir.

- Personel dogru eslesti ama kayitli timi liste timinden farkli.
- Eslesme guveni yuksek ama tam degil.
- Rutbe yazimi farkli.
- Gorev adi standart disi yazilmis ama bilinen bir goreve map edilebilmis.
- "24 saat kalacak" gibi gorev aciklamasi olarak saklanabilecek notlar var.

### Auto Fix

Kullanici aksiyonu istemeden duzeltilir ve kisa sekilde raporlanir.

- Saat formati: `08.00-19.30` -> `08:00 - 19:30`.
- Kucuk yazim hatalari: `TOLAM` -> `TOPLAM`.
- Rutbe varyantlari: `J.Uzm Cvs`, `J.Uzm. Cvş` -> standart rutbe formu.
- Ayni satira sikismis personel girdileri.
- Basit Turkce karakter bozulmalari normalize edilebiliyorsa.

### Quarantine

Faaliyete kaydedilmez, fakat kullanicinin incelemesi icin ham parca olarak tutulur.

- Kart basligi ve personel satirlari birbirine karismis.
- Tarih bir yerde farkli, alt satirda farkli ve sistem guvenli karar veremiyor.
- Liste basligi bir timi soyluyor ama personel grubu baska timle baskin sekilde eslesiyor.
- Toplam kisi sayisi ile bulunan kisi sayisi uyumsuz ve eksik kisiler tespit edilemiyor.

## Desired User Flow

1. Kullanici metni yapistirir.
2. Sistem metni bloklara ayirir ve personelleri eslestirir.
3. Panel once "Duzeltme gerekli" kartlari gosterir.
4. Kullanici kritik hatalari cozer veya karti siler.
5. Tim disi gorev, dusuk riskli eslesme ve rutbe farki gibi durumlar "Inceleme" sekmesinde kalir.
6. Kullanici tek tek veya toplu onay verebilir.
7. Tum kritik hatalar bitince kaydetme aktif olur.
8. Kayit sonrasi sistem onaylanan eslesmeleri ve tim disi gorev baglamlarini ogrenim kaydina ekler.

## UI Design

### Panel Structure

Toplu aktarim onizlemesi uc ana bolgeden olusur.

- Ust ozet: kart sayisi, tarih sayisi, personel sayisi, kritik hata sayisi, inceleme sayisi.
- Filtre sekmeleri: `Duzeltme Gerekli`, `Inceleme`, `Kaydedilebilir`, `Tum Kartlar`.
- Kart listesi: her faaliyet karti tarih, liste timi, gorev, saat, personel sayisi ve durum etiketiyle gosterilir.

### Card Status

Her kart tek bir ana durum alir.

- `Kaydedilemez`: kirmizi, kritik hata var.
- `Inceleme`: sari veya mavi, kayit mumkun ama onay bekleyen bilgi var.
- `Hazir`: yesil, kayda engel veya inceleme gerektiren durum yok.
- `Karantina`: gri/kirmizi, faaliyet kaydina dahil edilmeyecek.

### Personnel Row Status

Personel satirinda kullanici ayni anda iki bilgiyi gorur.

- Eslesen personel: ad, rutbe, kayitli tim.
- Gorev baglami: bu listede gecen tim ve gorev.

Tim disi gorev ornegi:

`Ahmet TINAS - Kayitli tim: 6/B - Liste timi: 9/B - Tim disi gorev`

Bu satir kaydi engellemez. Kullanici isterse `Bu goreve kabul et` diyerek uyariyi onaylar.

### Save Bar

Kaydetme bolgesi sade olmalidir.

- Kritik hata varsa: `Kaydedilemiyor - 3 kritik sorun var`.
- Sadece inceleme varsa: `Kaydedilebilir - 5 inceleme var`.
- Sorun yoksa: `Faaliyetleri Kaydet`.

Kaydetme butonu sadece kritik hata varsa kapanir. Inceleme uyarilari kaydi engellemez.

## Learning Design

Ogrenim sistemi dort bilgi turunu saklar.

### Name Alias Learning

Mevcut `personelIsimTakmaAdTable` kullanilir. Kullanici ham isim satirini bir personele bagladiginda sonraki aktarimlarda ayni isim otomatik eslesir.

### Duty Alias Learning

Gorev adi varyantlari standart gorev turlerine map edilir. Ornek:

- `Guluskur`, `Gülüşkür`, `GÖREV Listesi (Altın Kaz)` -> ilgili gorev turu.
- `Hazir kita`, `Hazır Kıta`, `Sabit kalınacak` -> ilgili gorev turu veya aciklama.

Bu kapsam icin yeni tablo veya mevcut ayar yapisi degerlendirilecek; ilk uygulamada kucuk ve test edilebilir bir mapping servisi tercih edilir.

### Cross-Team Assignment Learning

Personelin ana timi degismez. Kullanici "bu personel bu liste timinde gorev alabilir" onayi verdiginde sistem bunu sonraki aktarimlarda kritik sorun veya sert uyari saymaz.

Saklanacak bilgi:

- personel id
- liste/gorev timi
- gorev turu
- ilk onay tarihi
- son kullanim tarihi

### Parser Pattern Learning

Sistem sik gorulen liste baslik kaliplarini tanir. Ornek:

- `9/B Gülüşkür Listesi`
- `5-B Heybet Listesi`
- `6/B Görev (Adliye) listesi`
- `10/B Timi Hazır Kıta İsim Listesi`

Bu ogrenim kullaniciya agir bir ayar ekrani olarak degil, onaylanan aktarimlardan beslenen basit kalip toleransi olarak uygulanir.

## Data Model Direction

Kisa vadede mevcut tablo yapisi bozulmadan ilerlenir.

- Eslesen personel kaydi `FaaliyetPersonelAtamaTable.personelId` ile tutulmaya devam eder.
- Gorev turu `gorevVeyaIzin` alaninda kalir.
- Tim disi gorev bilgisi ilk asamada `aciklama` alanina standart bir metinle yazilabilir.

Orta vadede daha temiz model icin `FaaliyetPersonelAtamaTable` tablosuna `gorevTimId` veya `kaynakTimAdi` alani eklenmesi degerlendirilir. Ilk plan, migrasyon riskini dusuk tutmak icin bunu ayri gorev olarak ele alacaktir.

## Error Handling

- Kritik hata mesajlari kullaniciya cozum aksiyonuyla birlikte gosterilir.
- Bos kart icin aksiyonlar: `Karti sil`, `Metne don`, `Kart duzenle`.
- Eslesmeyen personel icin aksiyonlar: `Personel sec`, `Yeni personel ekle`, `Satiri kaldir`.
- Tim disi gorev icin aksiyonlar: `Bu goreve kabul et`, `Personel degistir`, `Satiri kaldir`.
- Karantina karti varsayilan olarak kayda dahil edilmez.

## Testing Strategy

### Unit Tests

- Bos kartlar kritik hata olarak isaretlenir.
- Tim disi ama eslesmis personel kritik hata degil, inceleme uyarisi olur.
- Inceleme uyarilari kaydetme butonunu kapatmaz.
- Kritik hata varken kaydetme butonu kapali kalir.
- Onaylanan tim disi gorev sonraki aktarimda daha dusuk siddetle gosterilir.
- Ayni satira sikismis iki personel ayrilabiliyorsa iki personel olarak parse edilir.

### Widget Tests

- Panel `Duzeltme Gerekli`, `Inceleme`, `Kaydedilebilir`, `Tum Kartlar` filtrelerini gosterir.
- Kritik hata filtresi sadece kaydi engelleyen kartlari gosterir.
- Tim disi personel satiri `Tim disi gorev` etiketiyle gorunur.
- `Tum tim disi gorevleri kabul et` aksiyonu ilgili satirlari onaylar.
- Sadece inceleme uyarisi kalan durumda `Faaliyetleri Kaydet` aktif olur.
- Mobil genislikte panel tasma yapmadan kaydirilabilir.

## Acceptance Criteria

- Bos kart faaliyet arsivine veya gunluk faaliyet kaydina gitmez.
- Eslesen personel, sirf liste timi farkli diye kaydi engellemez.
- UI kritik hata ile inceleme uyarisini net ayirir.
- Kullanici coklu listede once sadece cozulmesi gerekenleri gorebilir.
- Tim disi gorevler personelin ana timini degistirmez.
- Onaylanan eslesmeler sonraki aktarimlarda yeniden ayni sert uyarilari uretmez.
- Kaydetme davranisi acik ve tahmin edilebilir olur.
- Mevcut faaliyet kaydetme ve arsiv akislarinda regresyon olusmaz.
- `flutter analyze` ve ilgili testler gecmeden uygulama tamamlanmis sayilmaz.

