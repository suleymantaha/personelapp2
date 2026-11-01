# Nizam / PersonelApp2

Flutter tabanlı, yerel SQLite ile çalışan personel ve görev yönetim uygulaması.

## Modüller

- Personel ve tim yönetimi, komutan kapsamı ve kalıcı sıralama.
- Faaliyet oluşturma, onay, arşiv, görev timi snapshot ve çıktı hazırlama.
- Tim görev analizi, aylık özet ve günlük ayrıntılar.
- Aylık personel/görev matrisi ve nöbet takvimi.
- TEMGÜNDRAP taslakları ve belge çıktıları.
- Yerel hesap/parola, tema, tam yedekleme ve geri yükleme.

`lib/features/` sekiz feature içerir: activity, analytics, auth, dashboard,
matrix, personnel, temgundrap ve watch_roster. Shopping/debt veya cloud sync modülü yoktur.

## Yerel kontroller

```powershell
flutter pub get
flutter analyze
flutter test --reporter expanded --timeout 2m
```

`test/core`, `test/features`, `test/unit`, `test/widget` ve `test/audit` aynı tam
komutla keşfedilir. `scripts/test_runner.bat` host analiz/test sarmalayıcısıdır;
cihaza otomatik kurulum yapmaz. Coverage yüzde hedefi ile ölçülmüş coverage ayrıdır.

Android integration testlerini yalnız ayrı `nizam-nobet-test` AVD'sinde ve her
çalışmada yeniden doğrulanan seri ile çalıştırın. Örnek:

```powershell
flutter drive --keep-app-running --driver=test_driver/codebase_audit.dart --target=integration_test/codebase_audit_android_test.dart -d <verified-test-serial>
```

Integration debug target'ları `.qa` applicationId suffix'i kullanır. Flutter
driver'ın test sonu uninstall adımından kaçınmak için `--keep-app-running` kullanın.
Signed upgrade baseline'ını integration testleri bittikten sonra kurup hazırlayın;
gerçek kullanıcı cihazında test veya veri temizleme yapılmaz.
Native bounded backup testleri için mevcut cached Kotlin compiler ile:

```powershell
./android/app/src/test/run-bounded-backup-tests.ps1
```

## Yapı ve veri sınırları

Flutter/Riverpod/GoRouter, Drift/SQLite ve SharedPreferences kullanılır.
DB standart SQLite'tır; uygulama düzeyinde DB encryption yoktur. JSON yedek
checksum'u bozulmayı denetler, encryption/authentication sağlamaz. Yedek dosyalarını
hassas veri olarak koruyun. Parolalar Argon2id ile hash'lenir.

Release hazırlığı, sürüm/signer devamlılığı ve veri koruyan güncelleme kuralları
[AGENTS.md](AGENTS.md) içindedir. Aynı applicationId ve signer korunmalı; yeni
versionCode dağıtılmış ve CI paketlerinden daha büyük olmalıdır.

[CI workflow](.github/workflows/android-release.yml), [kontroller](CHECKS.md),
[kod audit raporu](docs/audits/2026-11-01/RAPOR.md),
[düzeltme/APK raporu](docs/verification/audit-hardening-2026-11-01/REPORT.md).
