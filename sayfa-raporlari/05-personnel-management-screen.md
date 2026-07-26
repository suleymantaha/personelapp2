# Personnel Management Screen Raporu

## Sayfa

- Route: `/personnel-management`
- Ana dosya:
  `lib/features/personnel/presentation/personnel_management_screen.dart`
- Bagli dialoglar:
  - `lib/features/personnel/presentation/widgets/personnel_form_dialog.dart`
  - `lib/features/personnel/presentation/dialogs/backup_restore_dialog.dart`
- Bagli servis:
  - `lib/features/personnel/services/personnel_backup_service.dart`

## Amac

Personel, tim ve komutan yetkilerini yonetmek icin merkez ekran olarak
kullaniliyor. Admin burada kadroyu yonetir; komutan ise kendi timini gorur.

## Temel Kullanici Akisi

1. Personel listesi, tim listesi ve komutan listesi provider'lar uzerinden
   yuklenir.
2. Arama ve tim filtreleri uygulanir.
3. Admin:
   - personel ekler / duzenler / siler
   - komutan atar
   - tim ekler
   - yetki devri yapar
   - backup/restore dialogunu acar
4. Komutan:
   - kendi timiyle sinirli listeyi gorur

## Veri ve Bagimliliklar

- `userSessionProvider`
- `allPersonnelProvider`
- `allSquadsProvider`
- `allCommandersProvider`
- `databaseProvider`
- `personnelRepositoryProvider`

## Rol ve Yetki Davranisi

- Ayrim agirlikla `isAdmin` ile UI seviyesinde yapiliyor.
- Komutan filtrelemesi ekranda uygulanmis; veri katmaninda her yerde ayni
  sertlikte garanti edilmiyor.

## Dikkat Ceken Davranislar

- Tek ekrandan birden fazla operasyonu yonetebilmesi guclu.
- Tim bazli gruplama ve filtre yapisi kullanisli.
- Komutan atama ve yedek islemleri operasyonel olarak pratik.

## Riskler

1. `session == null` durumunda admin varsayimi buyuk yetki riski.
2. `timId` bos komutan kullanicinin kapsam disi veri gorebilme ihtimali var.
3. Ekran asiri buyumus; listeleme, form, komutan yonetimi, backup ayni state
   class icinde birikmis.
4. Buyuk veri setinde istemci tarafinda gruplama/siralama maliyeti yukselebilir.

## Bagli Dialog: Personnel Form

Bu dialog yeni personel ekleme ve mevcut kaydi duzenleme icin kullaniliyor.

Gozlemler:

- Rütbe ve birlik fallback'leri veri kalitesini sessizce bozabilir.
- Validation daha cok save aninda yapiliyor.
- Birlik uretme kurali UI tarafinda.

## Bagli Dialog: Backup Restore

JSON metin uzerinden export/import yapiyor.

Gozlemler:

- "Restore" ifadesine ragmen davranis tam geri yukleme degil, merge mantiginda.
- Preview/dry-run yok.
- Buyuk JSON'u textbox ile yonetmek kirilgan.

## Bagli Servis: Personnel Backup Service

Servis `personelTable` ve `timTable` uzerinden JSON yedegi uretiyor ve geri
aliyor.

Kritik noktalar:

- `kullaniciTable` ve komutan iliskileri kapsama alinmiyor
- dedupe mantigi `rutbe + adSoyad` ile sinirli
- versiyon bilgisi yaziliyor ama migration mantigi zayif

## Test Ihtiyaci

- Admin/komutan gorunurluk testleri
- `session == null` ve `timId == null` senaryolari
- Filtre, arama ve gruplama kombinasyonlari
- Komutan atama/devir akislarinin tutarliligi
- Backup export/import ve commander iliskilerinin korunmasi

## Onerilen Iyilestirmeler

1. Yetkiyi veri katmaninda da zorlamak
2. Ekrani daha kucuk widget ve feature bloklarina ayirmak
3. Backup formatina kullanici ve yetki modelini eklemek
4. Form fallback kurallarini daha acik ve denetlenebilir hale getirmek
