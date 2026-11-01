# Proje bağlamı — PersonelApp2

Durum: ACTIVE. Personel ve görev/nöbet takip sistemi.

| Alan | Proje Değeri |
|---|---|
| Proje adı | Nizam / PersonelApp2; güncel sürüm pubspec.yaml içinde |
| Kullanıcı ve ihtiyaç | Saha/ekip personel yönetimi, nöbet çizelgeleri, METİ timi, aktivite kayıtları ve arşivleme |
| Hedef ve kabul | Yüksek veri bütünlüğü, yerel depolama, responsive arayüz ve regression koruması |
| Mevcut durum | Drift ve bildirim mimarisi aktif; güncel test/analiz kanıtları docs/verification altında |
| Teknoloji/sürüm | Flutter 3.x, Dart 3.5+, Drift 2.34.2, Riverpod 2.6.1, GoRouter 17.3, Cryptography 2.9 |
| Repo ve çalışma düzeni | `lib/core/` (db, notifications, services) · `lib/features/` (activity, personnel, etc.) · `test/` |
| Kapsam dışı | Üçüncü taraf harici bulut backend (uygulama yerel-öncelikli / offline-first mimaridedir) |
| Veri ve güven sınırları | Personel kimlik/iletişim bilgileri, standart yerel SQLite, Excel/PDF ihracı; DB/yedek için uygulama düzeyinde encryption yok |
| Ortamlar | Windows Masaüstü, Android/iOS mobil hedefleri |
| Kontroller | [CHECKS.md](CHECKS.md) — `dart analyze` ve `flutter test` |
| Orkestrasyon | UMAF v3.0 Active Orchestra (Orkestra Şefi + 5-Rol Ajan Ordusu) |
