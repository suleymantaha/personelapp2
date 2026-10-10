# Görev: Faaliyetlerden Otomatik TEMGÜNDRAP Üretimi ve Düzenleme Entegrasyonu

| Alan | Değer |
|---|---|
| Görev ID | task-temgundrap-auto-generate |
| Amaç ve kabul ölçütü | Günlük faaliyetlerden (`GunlukFaaliyetTable`, `FaaliyetPersonelAtamaTable`) otomatik `TemgundrapOperation` ve taslak `TemgundrapDocument` üreten dönüştürücü servisinin yazılması, Faaliyet Arşivi'nden seçilen faaliyetlerle TEMGÜNDRAP formuna geçiş ve TEMGÜNDRAP formu içinden günün faaliyetlerini içe aktarma diyaloğu eklenmesi; tüm alanların düzenlenebilir kalması ve mevcut PDF/Excel çıktısının formatının birebir korunması. |
| Tier ve gerekçe | Tier 2 — Yeni veri eşleme servisi ve iki ekran arası entegrasyon; şema değişikliği yok, TDD ile doğrulanabilir. |
| Yürütme modu ve gerekçe | native — Mevcut Flutter test altyapısı ve araçları doğrudan yürütülebilir. |
| Kullanıcı yetkisi / kapsam dışı | Yetkili: Kullanıcı talebi doğrultusunda faaliyetleri TEMGÜNDRAP'a dönüştürme ve düzenleme arayüzleri. Kapsam dışı: PDF/Excel çıktı motoru tasarımını değiştirmek veya veritabanı şemasını değiştirmek. |
| Koordinatör ve tek defter yazarı | Antigravity Koordinatör |
| Depo / cwd / base revision | f:\personelapp2 |
| Başlangıç kullanıcı değişiklikleri | Korunan yerel durum mevcut (.gitignore vb.) |
| Sözleşme ID / sürüm | N/A (Mevcut TemgundrapDocument ve GunlukFaaliyetTable sözleşmelerine sadık kalınır) |
| Başlangıç / son güncelleme UTC | 2026-10-10T18:55:00Z |
| Görev durumu | COMPLETED |
| Yayın/merge durumu | NOT_REQUESTED |
| Aktif ajan sınırı | 1 |
| Alt görev kontrol noktası | 15 işlem |
| Aynı hata deneme sınırı | 3 |
| Sonraki somut adım | Tamamlandı |

## İş paketleri

| ID | Hedef | Bağımlılıklar | Sahip | İzinli yollar | Cwd/dal | Durum | Teslim revision | Sonraki adım |
|---|---|---|---|---|---|---|---|---|
| WP-1 | TemgundrapActivityConverter domain servisi ve TDD testleri | yok | Koordinatör | lib/features/temgundrap/domain/, test/features/temgundrap/ | f:\personelapp2 | DONE | HEAD | Tamamlandı |
| WP-2 | TEMGÜNDRAP Formu için Faaliyet İçe Aktarma Diyaloğu | WP-1 | Koordinatör | lib/features/temgundrap/presentation/, test/features/temgundrap/ | f:\personelapp2 | DONE | HEAD | Tamamlandı |
| WP-3 | Faaliyet Arşivi ekranından Seçilenlerle TEMGÜNDRAP Formu Açma | WP-1 | Koordinatör | lib/features/activity/presentation/, test/features/activity/ | f:\personelapp2 | DONE | HEAD | Tamamlandı |
| WP-4 | Tam Entegrasyon ve Regresyon Doğrulaması | WP-2, WP-3 | Koordinatör | test/ | f:\personelapp2 | DONE | HEAD | Tamamlandı |

## Kabul ve kanıt

| Kontrol ID | Kabul ölçütü | Komut / cwd | Revision | Sonuç | Exit code | Zaman UTC | Güvenli rapor yolu |
|---|---|---|---|---|---|---|---|
| TC-1 | TemgundrapActivityConverter testleri başarılı | flutter test test/features/temgundrap/temgundrap_activity_converter_test.dart | HEAD | PASS | 0 | 2026-10-10T19:00:00Z | test/features/temgundrap/temgundrap_activity_converter_test.dart |
| TC-2 | TEMGÜNDRAP genel test paketi (40 test) başarılı | flutter test test/features/temgundrap/ | HEAD | PASS | 0 | 2026-10-10T19:07:47Z | task-325.log |
| TC-3 | Statik analiz hatasız | flutter analyze | HEAD | PASS | 0 | 2026-10-10T19:07:56Z | console |
| TC-4 | Faaliyet Arşivi seçim entegrasyonu başarılı | flutter test test/features/activity/activity_archive_selection_test.dart | HEAD | PASS | 0 | 2026-10-10T19:03:45Z | test/features/activity/activity_archive_selection_test.dart |
