# Proje kontrol eşlemesi — PersonelApp2

Durum: CONFIGURED. Flutter 3.x / Dart 3.5+ projesi için gerçek kontrol komutları test edilip doğrulandı.

| Kabul / kontrol | Gerçek komut | Cwd / ortam | Ne zaman? | Kanıt durumu |
|---|---|---|---|---|
| Format/lint/analiz | `dart analyze` | `.` (Host) | Her PR ve teslimat öncesi | PASS (0 issue) |
| Birim ve Widget Testleri | `flutter test` | `.` (Host) | Her PR ve teslimat öncesi | PASS (652/652 test geçti) |
| Zarf ve Worktree Teslimatı | `python scripts/dispatch_task.py verify --worktree <wt> --apply` | `.` (Host / cmd.exe) | Görev teslimatında | PASS |
| E2E / Cihaz Testi | `flutter test integration_test` | `.` (Host / Emulator) | Canlı sürüm öncesi | İsteğe bağlı |

## Doğrulama Notları
- Dart ve Flutter araçları Windows üzerinde `.bat` / `.exe` sarmalayıcıdır; komutlar host şeridinde doğrudan çalışır.
- 652 testin tamamı yerel veritabanı (Drift mock/in-memory), bildirim mimarisi, form validasyonları ve responsive arayüzleri kapsar.
