# Proje bağlamı — PersonelApp2

Durum: ACTIVE. Personel ve görev/nöbet takip sistemi.

| Alan | Proje Değeri |
|---|---|
| Proje adı | PersonelApp2 (v1.0.2+3) |
| Kullanıcı ve ihtiyaç | Saha/ekip personel yönetimi, nöbet çizelgeleri, METİ timi, aktivite kayıtları ve arşivleme |
| Hedef ve kabul | Yüksek veri bütünlüğü, yerel şifreli depolama, responsive arayüz ve 0 regresyon |
| Mevcut durum | 652 test yeşil, `dart analyze` 0 issue, Drift veritabanı aktif, bildirim mimarisi kurulu |
| Teknoloji/sürüm | Flutter 3.x, Dart 3.5+, Drift 2.34.2, Riverpod 2.6.1, GoRouter 17.3, Cryptography 2.9 |
| Repo ve çalışma düzeni | `lib/core/` (db, notifications, services) · `lib/features/` (activity, personnel, etc.) · `test/` |
| Kapsam dışı | Üçüncü taraf harici bulut backend (uygulama yerel-öncelikli / offline-first mimaridedir) |
| Veri ve güven sınırları | Personel kimlik/iletişim bilgileri, yerel SQLite şifreleme, Excel/PDF ihracı |
| Ortamlar | Windows Masaüstü, Android/iOS mobil hedefleri |
| Kontroller | [CHECKS.md](CHECKS.md) — `dart analyze` ve `flutter test` |
| Orkestrasyon | UMAF v3.0 Active Orchestra (Orkestra Şefi + 5-Rol Ajan Ordusu) |
