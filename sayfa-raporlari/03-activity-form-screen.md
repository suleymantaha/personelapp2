# Activity Form Screen Raporu

## Sayfa

- Route: `/activity-form`
- Ana dosya: `lib/features/activity/presentation/activity_form_screen.dart`
- Bagli dialog: `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart`

## Amac

Gunluk faaliyet cizelgesi olusturmak ve personeli secilen gorevlerle tarihe
baglamak icin kullaniliyor.

## Temel Kullanici Akisi

1. Kullanici tarih secer.
2. Personel listesi role gore yuklenir.
3. Her personel icin gorev secilir.
4. Uygun gorulen kayitlar payload halinde toplanir.
5. `createActivityWithAssignments()` ile kayit acilir.
   - admin icin dogrudan onayli
   - komutan icin `beklemede`

## Veri ve Bagimliliklar

- `userSessionProvider`
- `allPersonnelProvider`
- `allSquadsProvider`
- `activityRepositoryProvider`
- `databaseProvider`

## Rol ve Yetki Davranisi

- Admin tum personeli gorebilir ve admin'e ozel gorev seceneklerine ulasir.
- Komutan yalnizca kendi timindeki personelle sinirlanir.
- Komutan kaydi onaya duser; admin dogrudan onayli kayit olusturur.

## Dikkat Ceken Davranislar

- Komutanin `timId` bilgisi yoksa bloke edilmesi dogru bir koruma.
- Toplu gorevlendirme mantigi operasyonel hiz sagliyor.
- Ekran, admin ve komutan akislarini ayni yerden yonetiyor.

## Riskler

1. `session == null` durumu admin fallback'i urettigi icin yetki riski dogurur.
2. Ayni gun yeni kayit acildiginda mevcut activity tekrar kullanilip
   guncellenebilir; bu, bagimsiz faaliyet beklentisini bozabilir.
3. `_notes` altyapisi var ama kullanici tarafinda not girisi tam gorunur degil.
4. Yetki mantigi agirlikla UI tarafinda; repository katmaninda daha sert
   denetim yok.

## Bagli Dialog: Bulk Import

Bu ekranla operasyonel olarak en yakin yardimci akis `BulkImportDialog`.
Ozellikle WhatsApp/liste bazli hizli yuklemelerde guclu ama:

- esitlenemeyen personellerin dusmesi
- basari sayisinin aldatıcı olabilmesi
- ayni tarihli kayitlari overwrite etkisi

gibi alanlar yuzunden dikkatli kullanilmali.

## Test Ihtiyaci

- Tim filtresinin komutan icin dogru calismasi
- Admin-only gorevlerin rol bazli gorunmesi
- Bos payload uyarisinin calismasi
- Bulk import butonunun yalnizca admin'de olmasi

## Onerilen Iyilestirmeler

1. Activity olusturma mantigini ayni gun icin daha acik kurallara baglamak
2. Not girisini UI'da gorunur ve testlenebilir hale getirmek
3. Yetki kontrollerini repository katmaninda da tekrar etmek
4. Bulk import sonucunu satir bazli ozetle raporlamak
