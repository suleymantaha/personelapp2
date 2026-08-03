# Monthly Matrix Screen Raporu

## Sayfa

- Route: `/monthly-matrix`
- Ana dosya: `lib/features/matrix/presentation/monthly_matrix_screen.dart`
- Bagli widget:
  `lib/features/matrix/presentation/widgets/team_duty_calendar_modal.dart`
- Bagli utility: `lib/core/utils/duty_abbreviation_mapper.dart`
- Domain DTO: `lib/features/matrix/domain/team_duty_analytics_dto.dart`

## Amac

Personel bazli aylik gorev/izin matrisini tim gruplari halinde gosterir, tim
bazli gorev takvimi ve analitik ozet sunar, Excel XML olarak disa aktarir.

## Temel Kullanici Akisi

1. Ay secilir.
2. `allPersonnelProvider` ve `monthlyMatrixProvider(yearMonth)` verisi okunur.
3. Personeller **tim bazinda gruplandirilarak** akordeon kartlari halinde
   gosterilir (varsayilan kapali).
4. Her tim basliginda **takvim butonu** ile `TeamDutyCalendarModal` acilir:
   - Analitik ozet karti (gorevli gun, aktif personel, yogunluk indeksi)
   - 7 sutunlu takvim grid (gorev turune gore renk kodlu)
   - Secili gun detay paneli (gorevli personel chip'leri)
5. Mobilde personel bazli acilir kartlar, genis ekranda grid gorunur.
6. Export butonu ile **session bazli filtrelenmis** XML disa aktarim baslatilir.

## Veri ve Bagimliliklar

- `allPersonnelProvider`
- `monthlyMatrixProvider`
- `userSessionProvider`
- `allSquadsProvider` — tim isim cozumleme icin
- `matrixRepositoryProvider` — takvim modal verisi icin
- `ExcelXmlGenerator`
- `DutyAbbreviationMapper` — gorev kisa kodlari ve renkleri
- `TeamDutyAnalyticsDto` — 3 DTO: `TeamDutySummaryDto`,
  `TeamDayDutyDto`, `TeamMonthlyCalendarDto`

## Rol ve Yetki Davranisi

- Gorsel listede komutan kendi timine filtrelenir.
- Export akisinda artik session bazli filtreleme uygulaniyor (eski risk kismen
  giderilmis).
- Ancak `getTeamMonthlyCalendar()` repository seviyesinde rol kontrolu
  yapmiyor; cagiran taraf filtreliyor.

## Dikkat Ceken Davranislar

- Mobil ve genis ekran icin farkli ama tutarli gorunum stratejisi var.
- Ay secici ve onceki/sonraki ay gezintisi kullanisli.
- Gunun vurgulanmasi ve kisa kod sistemi operasyona uygun.
- Tim bazli akordeon gruplama ile personeller organize edilmis.
- Tim Gorev Takvimi modal'i ile analitik ozet ve detayli takvim gorunumu
  sunuluyor.
- `DutyAbbreviationMapper` ile gorev turleri renk kodlu badge sistemiyle
  gosteriliyor (7 gorev turu: Guluskur, Hazir Kita, Nobet, Izinli,
  Istirahatli, Raporlu, Sevk).
- Yogunluk Indeksi hesaplamasi: gorevli personel >= %70 oldugunda
  `isYogunGorev` flag'i aktif.

## Riskler

1. Export'ta session bazli filtreleme artik uygulaniyor. Ancak
   `getTeamMonthlyCalendar()` repository seviyesinde ek rol kontrolu yapmiyor.
2. Rejected/pending gibi durumlar kullaniciya yeterince ayristirilmis
   gorunmeyebilir.
3. Ayni gun ayni personele birden fazla assignment varsa son degerin kazanmasi
   veri yorumunu bozabilir.
4. Repository rolden bagimsiz ham veri uretiyor; filtreleme buyuk olcude ekran
   tarafinda.
5. Takvim modal'inda ayni gune birden fazla gorev atandiginda sadece ilk gorev
   gosteriliyor.
6. `DutyAbbreviationMapper` sabit kodlu 7 gorev turu taniyor; yeni gorev
   turleri eklendiginde mapper guncellenmezse fallback (ilk 3 harf) devreye
   girer.

## Bagli Widget: TeamDutyCalendarModal

- `lib/features/matrix/presentation/widgets/team_duty_calendar_modal.dart`
- 485 satirlik kapsamli modal bottom sheet widget'i.
- Tim adi + ay/yil basligi, drag handle, kapatma butonu.
- 3 istatistik karti: Gorevli Gun, Aktif Personel, Yogunluk Indeksi
  (renk kodlu).
- 7 sutunlu takvim grid, her hucre bir gunu temsil eder.
- `DutyAbbreviationMapper` ile gorev turune gore dinamik light/dark
  renklendirme.
- Secili gun detay paneli: gorev rozeti, tam ad, gorevli personel chip'leri.
- Tam dark mode destegi.

## Bagli Utility: DutyAbbreviationMapper

- `lib/core/utils/duty_abbreviation_mapper.dart`
- 7 gorev turu icin kisa kod, arka plan rengi ve metin rengi mapping'i.
- Light/dark mode destegi.
- Statik metotlar: `getAbbreviation()`, `getBadgeBgColor()`, `getTextColor()`.
- Tanimsiz gorevler icin fallback: ilk 3 harf.

## Domain DTO'lari

- `lib/features/matrix/domain/team_duty_analytics_dto.dart`
- `TeamDutySummaryDto`: Tim ozet istatistikleri (toplam gorev gunu, aktif
  personel, yogunluk yuzdesi, gorev turu dagilimi)
- `TeamDayDutyDto`: Gunluk gorev detayi (tarih, gorev kodu, gorevli personel
  listesi, yogunluk flag'i)
- `TeamMonthlyCalendarDto`: Tim aylik takvim verisi (gunler listesi + ozet)

## Test Ihtiyaci

- Komutan export kapsami (artik filtreleme var ama repository seviyesinde test
  gerekli)
- Pending/rejected gorunumlerinin dogrulugu
- Ayni gun coklu assignment davranisi
- Mobil ve desktop parity testleri
- Tim bazli gruplama ve akordeon acilis/kapanis davranisi
- `TeamDutyCalendarModal` acilma ve veri gosterim testi
- `DutyAbbreviationMapper` kisa kod ve renk dogrulugu
- `getTeamMonthlyCalendar()` yogunluk hesaplama dogrulugu

## Onerilen Iyilestirmeler

1. ~~Export aksiyonunda filtrelenmis personel listesini zorunlu kullanmak~~ →
   **TAMAMLANDI**
2. Durum kodlarini daha acik legend veya aciklama ile gostermek → Kismen
   tamamlandi (takvim modal'inda badge sistemi var, ana matriste hala basit
   metin)
3. Coklu assignment durumlari icin net bir is kurali tanimlamak
4. Matrix verisi icin role-aware repository veya servis katmani dusunmek
5. `getTeamMonthlyCalendar()` icinde rol bazli filtreleme eklemek
6. `DutyAbbreviationMapper`'i veritabani/config tabanli dinamik yapiya
   cevirmek
7. Takvim modal'inda ayni gune birden fazla gorev durumunu desteklemek
