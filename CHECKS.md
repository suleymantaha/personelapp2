# Proje kontrol eşlemesi — PersonelApp2

Durum: CONFIGURED. Flutter 3.x / Dart 3.5+ projesi için gerçek kontrol komutları test edilip doğrulandı.

| Kabul / kontrol | Gerçek komut | Cwd / ortam | Ne zaman? | Kanıt durumu |
|---|---|---|---|---|
| Format/lint/analiz | `flutter analyze` | `.` (Host) | Her PR ve teslimat öncesi | Her revizyonda yeniden ölçülür |
| Birim ve Widget Testleri | `flutter test --reporter expanded --timeout 2m` | `.` (Host) | Her PR ve teslimat öncesi | Her revizyonda yeniden ölçülür |
| Zarf ve Worktree Teslimatı | `python scripts/dispatch_task.py verify --worktree <wt> --apply` | `.` (Host / cmd.exe) | Görev teslimatında | PASS |
| E2E / Cihaz Testi | `flutter test integration_test` | `.` (Host / Emulator) | Canlı sürüm öncesi | İsteğe bağlı |

## Doğrulama Notları
- Dart ve Flutter araçları Windows üzerinde `.bat` / `.exe` sarmalayıcıdır; komutlar host şeridinde doğrudan çalışır.
- Test sayısı sabit değildir; son revizyonun gerçek çıktısı docs/verification altında kaydedilir.
- Tam host komutu test/core, test/features, test/audit, test/unit ve test/widget kapsamını keşfeder.
- output/ ve build/ yerel QA artifact'ları analizden ayrıdır; production ve test kaynakları taranır.
