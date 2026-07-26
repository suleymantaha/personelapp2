# Activity Archive Screen Raporu

## Sayfa

- Route: `/activity-archive`
- Ana dosya:
  `lib/features/activity/presentation/activity_archive_screen.dart`
- Bagli widget ve dialoglar:
  - `lib/features/activity/presentation/widgets/activity_summary_card.dart`
  - `lib/features/activity/presentation/widgets/activity_detail_sheet.dart`
  - `lib/features/activity/presentation/dialogs/add_personnel_dialog.dart`
  - `lib/features/activity/presentation/dialogs/edit_assignment_dialog.dart`

## Amac

Gecmis faaliyetleri listelemek, filtrelemek, incelemek, disa aktarmak ve
gerekirse activity icindeki atamalari duzenlemek icin kullaniliyor.

## Temel Kullanici Akisi

1. Arsiv kayitlari filtrelenmis provider uzerinden gelir.
2. Kullanici tarih, arama veya tim filtresi uygular.
3. Kart detayinda activity icindeki atamalar gorulur.
4. Duruma gore:
   - tek activity export
   - toplu export
   - personel ekleme
   - assignment duzenleme
   - silme
   gibi aksiyonlara gidilir.

## Veri ve Bagimliliklar

- `filteredActivitiesProvider`
- `pendingAssignmentsProvider`
- `allPersonnelProvider`
- `allSquadsProvider`
- `databaseProvider`
- `activityRepositoryProvider`

## Rol ve Yetki Davranisi

- Niyet olarak admin tum arsivi, komutan yalnizca kendi timine ait kayitlari
  gormeli.
- Pratikte ise detay akislarinda rol sinirlari yeterince sert degil.

## Dikkat Ceken Davranislar

- Arsiv + detay + export akisini tek modulde topluyor.
- Filtreleme ve ozet kart mantigi kullanisli.
- Detaydan hizli mutasyonlar operasyonel olarak guclu.

## Riskler

1. En kritik alanlardan biri burasi: komutan kapsam asan kayitlari gorebilir
   veya degistirebilir.
2. `timId` bilgisi olmayan komutan icin kapsam daha da genisleyebilir.
3. `+ Personel Ekle`, duzenleme ve silme aksiyonlarinda role uygun sert
   sinirlandirma zayif.
4. Faaliyet silme ve detay mutasyonlari repository tarafinda guvenlik
   bakimindan daha sert korunmuyor.

## Bagli Dialog: Add Personnel

- Var olan activity'ye yeni personel ekler.
- Aday listesi duplicate'i onler.
- Fakat komutana admin-only gorevler acik kalabiliyor.
- `timId` bos komutanin tum personeli gorebilme ihtimali var.

## Bagli Dialog: Edit Assignment

- Tek atamayi gunceller.
- Kaydetme sirasinda status de degisebilir.
- Conflict check yeniden kosulmadigi icin duzenleme sonrasi cakismali ama
  onayli kayit olusabilir.

## Test Ihtiyaci

- Komutanin yalnizca kendi tim kapsaminda kalmasi
- Edit/delete/add erisiminin role gore sinirlanmasi
- Export kapsaminin dogrulugu
- Delete confirm ve detay mutasyon akislarinin testi

## Onerilen Iyilestirmeler

1. Arsiv detay akislarinda server/repository tarafli sert yetki kontrolu
2. Komutan icin okunabilir ama mutasyonlari sinirli bir mod dusunulmesi
3. Edit sonrasi conflict kontrolunun yeniden kosulmasi
4. Export ve detay kapsaminda role-aware filtrelemenin tek yerde toplanmasi
