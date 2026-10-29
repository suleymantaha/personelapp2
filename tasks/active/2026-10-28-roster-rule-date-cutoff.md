# Kurallı çıktı: seçilen güne kadar X sayımı

| Alan | Değer |
|---|---|
| Görev ID | 2026-10-28-roster-rule-date-cutoff |
| Amaç ve kabul | Seçilen çıktı günü dahil, o ayın yalnızca o güne kadarki X'leri sayılır; 20 X kalır, 21+ X hariç tutulur. Sonraki günler erken tarihli çıktıyı etkilemez. |
| Tier / yürütme | Tier 2: çıktı davranışı. Ana ajan tek yazar; bağımsız read-only reviewer. |
| Depo / base | `F:/personelapp2`, `main`, `0f3bd08`; başlangıçta önceki özellik ve APK çalışmasına ait dirty dosyalar vardı. |
| Kapsam | Kural, preview ve export doğrulaması, Türkçe açıklama, regresyon testleri. APK/Drive/CI/commit/push istenmedi. |
| Durum | DONE, 2026-10-28 08:50 UTC. Yayın: NOT_REQUESTED. |

## Karar

`widget.date` çıktı için seçilen tarihtir. Matris bu tarihin ayından yüklenir; hem preview hem export sırasında `throughDay` ile seçilen gün dahil sınırlandırılır. Önceki gün kartları ana çıktı tarihi altında yer alır. Sıralama ve normal çıktı yolları değişmedi. Kart başlığı `1–25 Ekim 2026` gibi sayılan dönemi gösterir.

## Kanıt

| Kontrol | Komut / cwd | Sonuç |
|---|---|---|
| TDD kırmızı | `flutter test --no-pub test/unit/roster_matrix_x_rule_test.dart` / repo | Beklenen FAIL: `throughDay` henüz yoktu. |
| Dar test | `flutter test --no-pub test/unit/roster_matrix_x_rule_test.dart test/features/activity/roster_matrix_x_preview_test.dart test/features/activity/roster_preview_design_test.dart --reporter expanded` / repo | PASS, 10 test. İlk UI test denemesinde offscreen test kaydırması düzeltilip tekrar edildi. |
| Analiz | `dart analyze` / repo | PASS, 0 issue. |
| Tam test | `flutter test --no-pub --reporter compact` / repo | PASS, 769 başarılı, 1 skip. |
| Diff | `git diff --check` / repo | PASS; `tasks/ledger.md` için mevcut LF/CRLF uyarısı. |
| Bağımsız inceleme | Reviewer, aynı çalışma ağacı | PASS; actionable bulgu yok. Cihaz kabulü yapılmadı. |

Çalıştırılan kontroller exit code `0` ile tamamlandı. Kodun bu kayıt sırasındaki SHA-256 değerleri:

- `roster_matrix_x_rule.dart`: `5945ED5CE30FD7AC7DADA821D06BFD52CD86D822F879F47551DC6B144FF38096`
- `roster_output_preview_screen.dart`: `C74A78F56290E37F3D34F7CB2234C9AD6FC31B9DB96DB2F4F9FF9AD2FD9401F7`
- `app_tr.arb`: `C465ADFD8578E9E957843CDFCFA73E894B4A7C43F1B0ACF74A3EFDD67953083C`
- `app_localizations_tr.dart`: `C71F315D6D99929AF0F12EAA5F65A53ED30F7A79B29728BD7173237CEED2090F`
- `roster_matrix_x_rule_test.dart`: `7591FC08BA321C2941C8B666ECCC5A354D2E5B7106C65C116F5A54946B520ECA`
- `roster_matrix_x_preview_test.dart`: `6C6418358DFA4997A3011F29E19944A09138E62CF5F54D1980159F5106C12128`
- `roster_preview_design_test.dart`: `6696BF944FBBE92963DEE9352C9FFCEE1FBD8C4067E2AC08F59B1117A229F60F`

Kalan sınır: Honor 200 üzerinde yeni kod çalıştırılmadı; bu değişiklik için APK üretilmedi. Önceki kullanıcı dosyaları, sentetik veri ve dağıtılmış 10320 APK korunuyor.
