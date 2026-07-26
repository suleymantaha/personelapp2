# Dashboard Screen Raporu

## Sayfa

- Route: `/dashboard`
- Ana dosya: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Bagli dialog: `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart`

## Amac

Uygulamanin merkez ekranidir. Kullanici buradan diger sayfalara gider, ayarlar
bottom sheet'ini acar, parola degistirir, tema degistirir, cikis yapar; admin
ise ek olarak bakim ve toplu islem aksiyonlari kullanir.

## Temel Kullanici Akisi

1. Session ve bekleyen onay verisi okunur.
2. Admin ise ustte bekleyen onay banner'i gorulur.
3. Grid kartlardan ilgili modullere gecilir.
4. Ayarlar bottom sheet uzerinden:
   - tema degistirme
   - parola degistirme
   - cikis
   - admin icin test personeli ekleme / tum personeli silme

## Veri ve Bagimliliklar

- `userSessionProvider`
- `themeModeProvider`
- `pendingAssignmentsProvider`
- `personnelRepositoryProvider`
- `activityRepositoryProvider`
- `databaseProvider`
- `SessionStorage`

## Rol ve Yetki Davranisi

- Admin ise ek menu kartlari ve bakim aksiyonlari gorunur.
- Komutan kullanicida bazi kart basliklari degisir, ama ana navigasyonun buyuk
  kismi yine aciktir.

## Dikkat Ceken Davranislar

- Pending banner ile operasyonel dikkat gerektiren durumlar one cikiyor.
- Tema persistence'i var.
- Ayarlar bottom sheet'i, kullanicinin sik ihtiyaclarini tek yerde topluyor.
- Bulk import akcakisi admin merkezli tasarlanmis.

## Riskler

1. En kritik konu: `session?.isAdmin ?? true` yaklasimi, session yokken
   kullaniciyi fiilen admin gibi gosterebilir.
2. Router tarafinda auth veya role guard yok; route'lar dogrudan acik.
3. Pending veri akisinda yetki kontrolu UI seviyesinde kaliyor.
4. Sifre degistirme akisinda mevcut sifre dogrulamasi yok.
5. `loading/error` durumlari bazi yerlerde sessizce bos donuyor.

## Bagli Dialog: Bulk Import

`BulkImportDialog`, mesinden coklu faaliyet cikarma ve activity olusturma
islerini yapiyor. Guclu bir hizlandirici ama su riskleri tasiyor:

- eslesmeyen personeller sessizce atlanabilir
- ayni tarihte mevcut kayitlari beklenmedik sekilde guncelleyebilir
- basari sayaci, gercek kayit edilen veri ile birebir ortusmeyebilir

## Test Ihtiyaci

- Admin ve komutan menu gorunurlugu
- Session yokken admin UI acilmamasi
- Logout ve redirect davranisi
- Tema degisiminin kaydedilmesi
- Pending banner count ve tiklama navigasyonu
- Admin destructive aksiyonlarinda confirm akisi

## Onerilen Iyilestirmeler

1. Router seviyesinde auth/role guard eklemek
2. `session == null` durumunu guvenli varsayilan ile ele almak
3. Admin islemleri icin ek koruma ve loglama eklemek
4. Bulk import sonucunu daha denetlenebilir bir ozetle gostermek
