# Sayfa Raporlari

Bu klasor, uygulamadaki ana route'lar icin hazirlanan detayli inceleme
raporlarini icerir.

## Kapsam

- `/login`
- `/dashboard`
- `/activity-form`
- `/pending-approvals`
- `/personnel-management`
- `/monthly-matrix`
- `/activity-archive`

## Dosyalar

- `01-login-screen.md`
- `02-dashboard-screen.md`
- `03-activity-form-screen.md`
- `04-pending-approvals-screen.md`
- `05-personnel-management-screen.md`
- `06-monthly-matrix-screen.md`
- `07-activity-archive-screen.md`

## Ortak Gozlemler

1. Yetki davranisinin onemli bir kismi veri katmani yerine UI tarafinda
   uygulanmis.
2. Birden fazla ekranda `session == null` durumu fiilen admin gibi ele
   alinabiliyor.
3. Widget/integration test kapsami ekran duzeyinde zayif; agirlikla repository
   ve utility testleri mevcut.
4. Komutan kullanicilar icin gorunen veri ile gercek yetki kontrolu her yerde
   ayni sertlikte degil.

## En Kritik Bulgular

1. `DashboardScreen`, `PersonnelManagementScreen` ve benzeri ekranlarda
   `session?.isAdmin ?? true` kalibi rol sivilmasina neden olabilir.
2. `PendingApprovalsScreen` route seviyesinde admin guard olmadan onay/red
   aksiyonlari sunuyor.
3. `ActivityArchiveScreen` ve bagli detay akislarinda komutan kullanicinin
   kapsam asan goruntuleme veya mutasyon yapabilme riski var.
4. `MonthlyMatrixScreen` export aksiyonu gorunen filtre yerine ham personel
   listesini kullanabildigi icin yetki disi veri disa aktarilabilir.
5. Backup/restore akisi tam restore degil; merge mantigi ile calisiyor ve
   komutan/yetki modelini eksik tasiyor.
