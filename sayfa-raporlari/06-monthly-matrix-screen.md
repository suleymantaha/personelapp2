# Monthly Matrix Screen Raporu

## Sayfa

- Route: `/monthly-matrix`
- Ana dosya: `lib/features/matrix/presentation/monthly_matrix_screen.dart`

## Amac

Personel bazli aylik gorev/izin matrisini gosterir ve Excel XML olarak disa
aktarir.

## Temel Kullanici Akisi

1. Ay secilir.
2. `allPersonnelProvider` ve `monthlyMatrixProvider(yearMonth)` verisi okunur.
3. Mobilde personel bazli acilir kartlar, genis ekranda grid gorunur.
4. Export butonu ile XML disa aktarim baslatilir.

## Veri ve Bagimliliklar

- `allPersonnelProvider`
- `monthlyMatrixProvider`
- `userSessionProvider`
- `ExcelXmlGenerator`

## Rol ve Yetki Davranisi

- Gorsel listede komutan kendi timine filtrelenir.
- Ancak export akisinda gorunen filtre yerine ham personel listesi
  kullanilabildigi icin yetki disi veri disa aktarilabilir.

## Dikkat Ceken Davranislar

- Mobil ve genis ekran icin farkli ama tutarli gorunum stratejisi var.
- Ay secici ve onceki/sonraki ay gezintisi kullanisli.
- Gunun vurgulanmasi ve kisa kod sistemi operasyona uygun.

## Riskler

1. En kritik risk: komutan kullanicinin tum personeli export edebilmesi.
2. Rejected/pending gibi durumlar kullaniciya yeterince ayristirilmis
   gorunmeyebilir.
3. Ayni gun ayni personele birden fazla assignment varsa son degerin kazanmasi
   veri yorumunu bozabilir.
4. Repository rolden bagimsiz ham veri uretiyor; filtreleme buyuk olcude ekran
   tarafinda.

## Test Ihtiyaci

- Komutan export kapsami
- Pending/rejected gorunumlerinin dogrulugu
- Ayni gun coklu assignment davranisi
- Mobil ve desktop parity testleri

## Onerilen Iyilestirmeler

1. Export aksiyonunda filtrelenmis personel listesini zorunlu kullanmak
2. Durum kodlarini daha acik legend veya aciklama ile gostermek
3. Coklu assignment durumlari icin net bir is kurali tanimlamak
4. Matrix verisi icin role-aware repository veya servis katmani dusunmek
