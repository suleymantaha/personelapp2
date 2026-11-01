# Görev indeksi

Tek yazıcı: koordinatör. Henüz bu paketle başlatılmış proje görevi yoktur.

| Görev ID | Hedef | Durum | Aktif kayıt / kanıt |
|---|---|---|---|
| 2026-11-01-codebase-audit | Kod değişmeden rapor/test ve Android audit | DONE | [Kayıt](active/2026-11-01-codebase-audit.md) |
| 2026-10-30-release-10324 | APK 1.0.9+10324, özel Drive ve CI'sız GitHub | DONE | [Kayıt](active/2026-10-30-release-10324.md) |
| 2026-10-30-task-team-flow-repair | Snapshot arşiv filtresi ve güvenli tarih değiştirme | DONE | [Kayıt](active/2026-10-30-task-team-flow-repair.md) |
| 2026-10-30-future-task-team | Bugün/gelecekte otomatik görev timi, belirsiz geçmişte doğrulama | DONE | [Kayıt](active/2026-10-30-future-task-team.md) |
| 2026-10-29-meti-duty | HEYBET/KULE sırası ve tek günlük METİ | DONE | [Kayıt](active/2026-10-29-meti-duty.md) |
| team-duty-analytics | Salt-okunur tim görev analizi | IN_REVIEW | tasks/active/team-duty-analytics.md |
| task-temgundrap-auto-generate | Faaliyetlerden Otomatik TEMGÜNDRAP Üretimi ve Düzenleme | COMPLETED | tasks/active/task-temgundrap-auto-generate.md |
| task-temgundrap-fix-transfer | TEMGÜNDRAP düzeltmelerini F:/personelapp2 deposuna aktarma | DONE | tasks/active/task-temgundrap-fix-transfer.md |
| task-temgundrap-import-export-stability | Import kimliği, overflow ve Excel/PDF çıktı düzeltmeleri | DONE | tasks/active/task-temgundrap-import-export-stability.md |
| 2026-10-27-roster-ui-apk-drive | Çıktı Hazırla UI, güvenli APK güncellemesi ve Drive | DONE | [Kayıt](active/2026-10-27-roster-ui-apk-drive.md) |
| 2026-10-27-rank-export-apk-drive | Rütbe sıralı çıktı APK ve özel Drive teslimi | DONE | [Kayıt](active/2026-10-27-rank-export-apk-drive.md) |
| 2026-10-28-roster-matrix-x-exclusion | Birleşik çıktı modern ekran ve 21+ X hariç tutma | DONE | [Kayıt](active/2026-10-28-roster-matrix-x-exclusion.md) |
| 2026-10-28-roster-rule-apk-drive | Kurallı çıktı APK 10320 ve özel Drive teslimi | DONE | [Kayıt](active/2026-10-28-roster-rule-apk-drive.md) |

Tier 2/3 görevde [şablonu](../.agents/templates/task.md)
`tasks/active/<task-id>.md` olarak doldur ve bu indekse gerçek kayıt ekle.
Bu boş tablo tamamlanmış görev veya uygulama kanıtı değildir.

| 2026-10-23-custom-personnel-order | Kalıcı tim/personel sırası ve çıktı entegrasyonu | DONE | [Kayıt](active/2026-10-23-custom-personnel-order.md) |

| 2026-10-23-personnel-ui | Aynı sayfada personel/tim arayüzü ve sıralama | DONE | [Kayıt](active/2026-10-23-personnel-ui.md) |
| 2026-10-24-daily-team-report | Günlük tek satır tim görevleri ve kişi detayları | DONE | [Kayıt](active/2026-10-24-daily-team-report.md) |

- 2026-10-24: [Independent monthly watch roster](active/2026-10-24-independent-watch-roster.md) — RUNNING, read-only, dedicated emulator only.
- 2026-10-24: Independent monthly watch roster DONE — 712 tests, analyze, dedicated emulator scenario and independent source review PASS; no commit/push.
- 2026-10-24: [Analytics settings and watch location](active/2026-10-24-analytics-settings-cleanup.md) — RUNNING.
- 2026-10-24: Analytics settings/location cleanup DONE — 714 tests, analyze, two isolated Android scenarios and independent review PASS; no user-emulator operations or commit/push.
- 2026-10-24: [Watch calendar](active/2026-10-24-watch-calendar.md) — RUNNING, isolated UI change.
- 2026-10-24: Watch calendar DONE — 718 tests, analyze, separate Android scenario and independent review PASS; other lib files unchanged, no user-emulator operations.
- 2026-10-24: [Monthly default and collapsed teams](active/2026-10-24-monthly-collapsed-teams.md) — RUNNING.
- 2026-10-24: Monthly default and collapsed teams DONE — 719 tests, analyze, separate Android scenario and independent source review PASS; no user-emulator install.
- 2026-10-24: Duty rows now count distinct activity/duty records, not personnel; regression red/green, 719 tests, analyze and dedicated5560 drive PASS. Normal lib/main.dart APK installed -r on user-authorized baba5554 after local backup; DB/preferences byte-identical after navigation. Monthly default and collapsed cards observed. No commit/push.
- 2026-10-24: [Pending changes review and main push](active/2026-10-24-pending-changes-commit.md) — verification PASS; 720 tests, clean analyze, provider lifecycle regression and historical evidence review; authorized commit/push follows.

- 2026-10-24: [Nizam responsive design](active/nizam-responsive-design.md) — IN_REVIEW; UI implemented, 747 tests PASS, analyze PASS; full web build blocked by existing drift/native imports. No publication.

- 2026-10-24: [Role bridge opt-in](active/2026-10-24-role-bridge-opt-in.md) - offline integration, see task record.

- 2026-10-24 | APK/private Drive + persistent local web | DONE | tasks/active/2026-10-24-apk-web.md | 10306 upgrade verified; 748 tests + 3 focused, analyze/build PASS; browser-runner blocked; no push/deploy.

- 2026-10-24 | Compact dashboard and archive hero | PASS | tasks/active/2026-10-24-compact-dashboard.md | 42 dashboard tests, analyze and visual review; no APK distribution.

- 2026-10-24 | User-ordered workspace / APK10308 | DONE | tasks/active/2026-10-24-ordered-workspace.md | 42 tests/analyze/build/update PASS; private Drive delivered.

- 2026-10-24 | Restore original dashboard / APK10309 | DONE | tasks/active/2026-10-24-restore-original-ui.md | 18 tests/analyze/build/update PASS; private Drive delivered; web fixes preserved.

- 2026-10-28 | Rule output selected-day cutoff | DONE | [Task](active/2026-10-28-roster-rule-date-cutoff.md) | 769 tests + 1 skip, analyze, independent review PASS; no APK/CI/commit/push.

- 2026-10-28 | Rule cutoff APK10321 private Drive | DONE | [Task](active/2026-10-28-roster-rule-cutoff-apk-drive.md) | 769 tests + 1 skip, analyze/build, same signer, data-safe AVD update, independent review and private upload PASS; no CI/commit/push.

- 2026-10-28 | Birleşik Çıktı UI / APK10322 emülatör onayı | IN_REVIEW | [Task](active/2026-10-28-roster-preview-ui-emulator.md) | 775 tests + 1 skip, analiz/build/izole AVD PASS; dahil/hariç sayıları kişi listesini açıyor; kullanıcı görünüm onayı bekleniyor, Drive/CI/commit/push yok.
- 2026-10-29 | Router extra history | DONE | [Task](active/2026-10-29-router-extra-history.md) | 782 PASS + 1 SKIP; analyze/format/diff and live browser back-forward/expired history PASS; no commit/push.
- 2026-10-29 | Monthly analytics dashboard and XLSX charts | DONE | [Task](active/2026-10-29-monthly-analytics.md) | 54 focused / 797 full PASS + 1 skip; scoped analyze, read-only backup reconciliation, XLSX openpyxl and independent source review PASS; no APK/commit/push.

- 2026-10-29-safe-team-history: DONE — Ayarlarda güvenli onarım ve tarihli snapshot koruması; tasks/active/2026-10-29-safe-team-history.md.
- 2026-10-29 | Personnel count clarity / partial team assignments | DONE | [Task](active/2026-10-29-personnel-count-clarity.md) | 62 analytics / 860 full PASS + 1 skip; analyze, independent source review, latest backup reconciliation and XLSX cache readback PASS; no APK/commit/push.

- 2026-10-29-analytics-personnel-label: IMPLEMENTED (scoped checks PASS; concurrent daily-detail tests still FAIL) — Tim Analizi personel satırı/görev etiketi düzeltmesi; görev verileri salt okunur korunur; tasks/active/2026-10-29-analytics-personnel-label.md.
- 2026-10-30 | Fixed daily detail summary / scrollable task-team lists | DONE | [Task](active/2026-10-29-monthly-fixed-header.md) | 79 analytics PASS; 4 final sheet regressions PASS; scoped analyze and independent review clear; Android integration PASS + interactive emulator checked with synthetic data; separate QA package, no product release/commit/push.

- 2026-10-30-main-release-10323: main integration and version1.0.8+10323 APK; verification in progress; see tasks/active/2026-10-30-main-release-10323.md.
- 2026-10-30-main-release-10323 DONE: main5bf4633, 887PASS/1skip, signed1.0.8+10323, retained-data upgrade PASS, private Drive upload/readback PASS; no push/CI.

- 2026-11-01 archive-conveniences: tasks/active/2026-11-01-archive-conveniences.md — DONE (960 PASS/1 SKIP + 3 additional PASS; no commit/push)

- 2026-11-01 integrated-release-10325: tasks/active/2026-11-01-integrated-release-10325.md — DONE (963 PASS/1 SKIP, signed APK and retained-data upgrade PASS; local main, no push)

- 2026-11-01-archive-flow: DONE — [task](active/2026-11-01-archive-flow.md), codex/archive-flow-redesign, isolated F:/personelapp2-archive-flow; no push.

- 2026-11-01-release-10326: BLOCKED — signed1.0.11+10326 built; artifact checks/independent artifact review PASS; retained-data upgrade blocked by native QEMU crashes; no delivery/commit/push/upload.

- 2026-11-01-archive-compact-selection: DONE — compact cards, reorder X, select-before-output;1013PASS/1SKIP/analyzePASS; tasks/active/2026-11-01-archive-compact-selection.md; no APK/commit/push.

- 2026-11-01-release-10327: DONE — signed1.0.12+10327, retained-data upgrade and independent acceptance PASS, verified local Downloads copy; no commit/push/upload.
