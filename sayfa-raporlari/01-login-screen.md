# Login Screen Raporu

## Sayfa

- Route: `/login`
- Ana dosya: `lib/features/auth/presentation/login_screen.dart`

## Amac

Kullanici girisini baslatir, ilk giriste parola olusturma akislarini yonetir,
kayitli oturumu yukleyip kullaniciyi dogrudan dashboard'a yonlendirebilir.

## Temel Kullanici Akisi

1. Ekran acildiginda `ensureSeeded()` ile temel veriler hazirlanir.
2. Kayıtli session varsa yuklenir ve kullanici `/dashboard` ekranina gider.
3. Kullanici adi ve sifre girilir.
4. Kullanici bulunduysa:
   - sifre bos ise ilk giris parola olusturma dialogu acilir
   - sifre dogruysa session yazilir ve dashboard'a gidilir
5. Giris basarisizsa snackbar ile hata gosterilir.

## Veri ve Bagimliliklar

- `databaseProvider`
- `userSessionProvider`
- `SessionStorage`
- `personnelRepositoryProvider.updateUserPassword()`
- `PasswordHasher.verifyPassword()`

Bu ekran auth mantiginin bir kismini repository yerine dogrudan DB sorgusuyla
sunum katmaninda yurutuyor.

## Rol ve Yetki Davranisi

- Rol dogrudan `KullaniciTableData.rol` alanindan session'a tasiniyor.
- `tim_komutani` ve `timId == null` durumunda, kullanicinin bagli oldugu tim
  ek sorgu ile `timTable.timKomutaniId` uzerinden bulunmaya calisiliyor.

## Dikkat Ceken Davranislar

- Ilk giris parolasi olusturma akisi kullanisli ve net.
- Session geri yukleme sayesinde tekrar giris ihtiyaci azaltilmis.
- UI sade; temel giris formu ve responsive kart yapisi yerinde.

## Riskler

1. `initState` icindeki seed ve session yukleme hatalari sessizce yutuluyor.
2. Giris mantigi UI katmanina fazla yakin; auth service/repository ayrimi zayif.
3. Seed edilen admin sifresi ve duz metin fallback mantigi guvenlik acisindan
   zayif.
4. Loading durumu, disable state ve cift tik korumasi yok.

## Test Ihtiyaci

- Kayitli session varsa otomatik redirect
- Ilk giris parola olusturma akisi
- Yanlis parola durumda hata mesaji
- `tim_komutani` kullanicida `timId` fallback cozumu

## Onerilen Iyilestirmeler

1. Giris mantigini ayri bir auth service/repository katmanina tasimak
2. Seed ve session yukleme hatalarini gozlemlenebilir hale getirmek
3. Loading ve form validation durumlarini guclendirmek
4. Duz metin sifre fallback davranisini kaldirmak
