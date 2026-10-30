# Görev: Görev timi akışını tamamlama

| Alan | Değer |
|---|---|
| Görev ID | 2026-10-30-task-team-flow-repair |
| Amaç/kabul | Arşiv tim filtresi snapshot; güvenli ve tutarlı tarih değişikliği |
| Tier | Tier 2: ortak repository/preview/UI sözleşmesi, migration yok |
| Kullanıcı yetkisi | İki doğrulanan hatayı doğru akışla düzelt; commit/push/APK/yayın kapsam dışı |
| Koordinatör / tek defter yazarı | /root |
| Cwd/branch/base | F:/personelapp2; main; 5a83833b984fd36806295c1beccc73ae64198d5a |
| Başlangıç değişiklikleri | Önceki future-task-team patch'i ve ilgisiz matrix/METİ dirty dosyaları korunur |
| Sözleşme | Spec: ../../docs/superpowers/specs/2026-10-30-task-team-flow-repair-design.md |
| Başlangıç / güncelleme | 2026-10-30; final 2026-10-30T08:42:53Z |
| Durum | DONE |
| Yayın / merge | NOT_REQUESTED |
| Aktif ajan sınırı | Host 4; root + test worker + read-only reviewer |
| Tekrar sınırı | Aynı hata için kör tekrar yok; beklenen RED ayrı |
| Sonraki adım | Yerel kaynak teslimi; yayın talep edilmedi |

## İş paketleri ve sahiplik

- ROOT: activity repository, card filter, date UI helper, confirmation dialog,
  repository tests, dokümanlar ve kayıt. Tek source yazarı.
- /root/archive_filter_regressions: yalnız activity_archive_team_filter_test.dart
  ve activity_date_change_action_test.dart. RED ve UI GREEN tamamlandı.
- /root/review_team_flow_repair: salt okunur bağımsız inceleme. İlk P2 adayı root
  tarafından RED ile doğrulandı ve assignment full-row snapshot guard ile kapatıldı.

## Kabul ve kanıt

Cwd F:/personelapp2; Flutter 3.47.2 / Dart 3.13.2; sentetik in-memory DB.
Base + test edilen source hash'leri output/task-team-flow-source-manifest.json.

| Kontrol | Komut / kapsam | Sonuç | Exit | Log |
|---|---|---|---|---|
| DATE_RED | flutter test --no-pub --reporter expanded test/features/activity/activity_date_team_resolution_test.dart | FAIL beklenen: ileri güne taşımada TaskTeamRequiredException | 1 | output/task-team-date-flow-red.log |
| ARCHIVE_RED | flutter test --no-pub --reporter expanded test/features/activity/activity_archive_team_filter_test.dart | FAIL beklenen: 4 FAIL, 1 PASS | 1 | output/task-team-archive-filter-red.log |
| STALE_RED | flutter test --no-pub --reporter expanded test/features/activity/activity_date_team_stale_test.dart | FAIL beklenen: eski onayla yeni atama değişiyordu | 1 | output/task-team-date-stale-red.log |
| GREEN | Date/history/confirmation/archive/widget/prevention dar paketi | PASS (46; ardından ek regression) | 0 | output/task-team-flow-green.log |
| STALE_GREEN | stale/history/confirmation/date UI paketi | PASS (19; sonra ek same-ID-note testi) | 0 | output/task-team-date-stale-green.log |
| ANALYZE | dart analyze lib test | PASS (No issues found; final tekrar da temiz) | 0 | output/task-team-flow-analyze.log |
| FULL_ANALYZE | dart analyze | PASS (2026-10-30T08:41:54Z–08:42:03Z; mevcut output dosyalarında 14 avoid_print info, error/warning yok) | 0 | output/task-team-flow-full-analyze.log |
| SUITE | flutter test --no-pub --reporter expanded | Final 924 PASS, 1 SKIP; 2026-10-30T08:41:54Z başlangıç, 08:42:53Z öncesi tamamlandı | 0 | output/task-team-flow-suite.log |
| REVIEW | Yukarıdaki reviewer; final 7 production dosyası | PASS, eski P2 kapandı, yeni ciddi bulgu yok | 0 | Oturum raporu, 2026-10-30T08:40:59Z |

## Kararlar / kurtarma / sınırlar

Tarih değişimi admin actor ister. UI expectedDate + immutable assignmentSnapshot
taşır; transaction içinde ID ve tüm satır içerikleri tekrar karşılaştırılır.
Eşleşen timin eski adı/snapshotı korunur. Yalnız açık seçimler moved assignment'a
yazılır; tüm doğrulama bittikten sonra tarih ve seçimler atomik uygulanır.
İptal/conflict/stale durumunda yazım olmaz; üyelik geçmişi ve başka görevler değişmez.

İlk genel analyzer, kendi output reproducer dosyalarındaki eski API çağrısını
yakalamıştır. Önceki hata kanıtları *.dart.reference.txt olarak saklandı;
derlenen production veya test kapsamına dahil değiller. Mevcut kullanıcı
output dosyalarındaki avoid_print info ayrı raporlanır; ilgisiz dosyalar değiştirilmez.

Geri dönüş: yalnız bu görev diff'i; canlı DB/migration yok. Cihaz smoke/APK NOT_RUN.
Parasal/token maliyeti ölçülmedi; tasarruf iddiası yok. Açık görev süreci finalde kapatılır.

## Kapanış

- [x] Final regression/suite/analyze/format kanıtı kaydedildi; 16 dosyada format 0 değişiklik.
- [x] Son source bağımsız incelendi; 7 source hash'i reviewer ile birebir eşleşti.
- [x] Kullanıcı değişiklikleri korunarak final diff kontrol edildi; ilgisiz matrix/METİ numstat değişmedi.
- [x] Commit/push/yayın yapılmadı; cihaz smoke/APK NOT_RUN.
