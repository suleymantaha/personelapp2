# Proje kontrol eşlemesi

Durum: UNCONFIGURED. Henüz hedef uygulama veya ürün kontrol komutu seçilmedi.
Mevcut projenin package scripts, CI, wrapper ve SDK tanımlarından gerçek komutlar doldurulur.
Boş satır veya örnek komut çalıştırılmış test değildir.

| Kabul / kontrol | Gerçek komut | Cwd / ortam | Ne zaman? | Kanıt durumu |
|---|---|---|---|---|
| Format/lint | Henüz tanımlanmadı | Gerçek proje | İlgili değişiklik | NOT_RUN |
| Typecheck/build | Henüz tanımlanmadı | Gerçek proje | Gerekiyorsa | NOT_RUN |
| Birim/regresyon | Henüz tanımlanmadı | İzole test | Davranış değişimi | NOT_RUN |
| Contract/integration | Henüz tanımlanmadı | İzole test | Ortak sınır değişimi | NOT_RUN |
| E2E/erişilebilirlik | Henüz tanımlanmadı | İzinli ortam | Kullanıcı akışı | NOT_RUN |
| Güvenlik/yarış/kurtarma | Henüz tanımlanmadı | Sentetik/izole test | İlgili risk | NOT_RUN |

Uygulanmayan kontrol gerekçeli N/A olur. Araç/erişim yoksa BLOCKED; çalıştırılmadıysa NOT_RUN.
0 test keşfi veya başarılı compilation tek başına davranış doğruluğunu kanıtlamaz.
Test komutunun üretime/veritabanına yazıp yazmadığı önce kontrol edilir.

## Bu rehber paketinin doğrulaması

Python 3.10+ ve standart kütüphane gerekir. Cwd: paket kökü.

```powershell
python -B scripts/validate_package.py --root .
python -B -m unittest discover -s tests -v
```

Bu komutlar rehberin dosya, link, şablon ve ayar yapısını sınar; hedef uygulamanın testleri değildir.
Doğrulayıcı ağ çağrısı veya kaynak dosya yazımı yapmaz.
