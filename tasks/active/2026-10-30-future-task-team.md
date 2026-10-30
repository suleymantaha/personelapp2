# Görev: İleri tarihli görev timi doğrulama

| Alan | Değer |
|---|---|
| Görev ID | 2026-10-30-future-task-team |
| Amaç/kabul | Bugün/gelecekte mevcut timle kayıt; belirsiz geçmişte doğrulama |
| Tier | Tier 2: ortak repository davranışı; şema/migration yok |
| Yürütme | Native uygulama, bounded bağımsız salt okunur inceleme |
| Yetki | Kullanıcı akışı onayladı; commit/push/APK/yayın kapsam dışı |
| Koordinatör | /root; tüm dosyalar tek yazar |
| Cwd/base | F:/personelapp2; 5a83833b984fd36806295c1beccc73ae64198d5a; main |
| Başlangıç değişiklikleri | METİ spec, matrix_day_cell.dart, monthly_matrix_actions.dart, excel_xml_generator.dart, meti_excel_test.dart, meti_matrix_test.dart; .playwright-cli, .serena, output ve iki doğrulama belgesi korunur |
| Sözleşme | Public API/şema aynı; tarih davranışı spec içinde tanımlı |
| Durum | DONE |
| Güncelleme UTC | 2026-10-30T08:10:15Z |
| Yayın/merge | NOT_REQUESTED |
| Aktif ajan sınırı | Ortam 4; yalnız uygulayıcı + reviewer kullanılacak |
| Kontrol noktası | Tek bounded görev; kör tekrar yok |
| Sonraki adım | Yerel kaynak değişikliği teslimi; yayın talep edilmedi |

## İş paketi

ROOT: resolver + iki test dosyası + bu görevin belgeleri; aynı main working tree.
REVIEW: salt okunur final diff; yazma ve yeniden delegasyon yok.

## Kabul ve kanıt

Cwd F:/personelapp2; Flutter 3.47.2, Dart 3.13.2; sentetik in-memory veritabanı.

| Kontrol | Komut | Sonuç | Exit | Log |
|---|---|---|---|---|
| RED | flutter test --no-pub --reporter expanded test/features/activity/task_team_confirmation_test.dart test/features/activity/future_task_team_snapshot_test.dart | FAIL (beklenen; 6 geçti, 7 başarısız; compilation hatası yok) | 1 | output/task-team-future-red.log |
| GREEN | flutter test --no-pub --reporter expanded test/features/activity/task_team_confirmation_test.dart test/features/activity/future_task_team_snapshot_test.dart test/features/activity/task_team_snapshot_prevention_test.dart test/core/services/task_team_history_test.dart | PASS (30 test; 08:09:01Z) | 0 | output/task-team-future-green.log |
| ANALYZE | dart analyze | PASS (08:09:18Z–08:09:41Z; hata/warning yok, mevcut output dosyalarında 14 avoid_print info) | 0 | output/task-team-future-analyze.log |
| TARGET_ANALYZE | dart analyze lib/features/activity/data/activity_repository_task_teams.dart test/features/activity/task_team_confirmation_test.dart test/features/activity/future_task_team_snapshot_test.dart | PASS, No issues found | 0 | terminal |
| FORMAT | dart format --output=none --set-exit-if-changed lib/features/activity/data/activity_repository_task_teams.dart test/features/activity/task_team_confirmation_test.dart test/features/activity/future_task_team_snapshot_test.dart | PASS (0 changed) | 0 | terminal |
| SUITE | flutter test --no-pub --reporter expanded | PASS (898 geçti, 1 SKIP; 08:09:18Z–08:10:11Z) | 0 | output/task-team-future-suite.log |
| REVIEW | /root/review_future_task_team; salt okunur diff ve git diff --check | PASS, bulgu yok | 0 | Aşağıdaki hash'ler üzerinde inceleme |

İlk test taslağında enum/import ve komutan hesabı fixture eksikleri düzeltildi;
üretim yetkileri gevşetilmedi. Son GREEN gerçek komutan hesabını da kullanır.

İncelenen/test edilen revision: yukarıdaki base + SHA256 manifesti:

```text
73B6F775368D5CADD713BA92CB421DC41C43338ACAF95F59C8FE12FFDDF21510 lib/features/activity/data/activity_repository_task_teams.dart
750D7651A4E3C97EB5C8ACC6BA609F9FA15D49DC104A191BE67E662B3E2CF160 test/features/activity/task_team_confirmation_test.dart
38998D663B7125A00D8C46EC28040CABE6CF518F0E56AF0768387E45C8184E2A test/features/activity/future_task_team_snapshot_test.dart
```

## Kararlar ve kurtarma

Bugün/gelecek otomatik ataması üyelik geçmişi üretmez; sadece görev snapshotı yazar.
Geçmiş tarih kontrolü ve açık görev timi tercihleri korunur.
Canlı kullanıcı DB'si/cihazı kullanılmaz. Geri dönüş yalnız göreve ait diff'tir.
Paket derleme ve cihaz smoke kontrolü kapsam dışıdır; APK üretilmez.

## Kapanış

- [x] Regresyon, analyze ve tam test sonuçları kaydedildi.
- [x] Aynı diff bağımsız incelendi; reviewer hash'leri eşleşiyor.
- [x] Kullanıcı değişikliklerine dokunulmadan son diff kontrol edildi.
- [x] Yayın/commit/push yapılmadı; cihaz testi ve APK build NOT_RUN.
