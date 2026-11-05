# Toplu aktarım onarımı — doğrulama

- Görev: `2026-11-03-bulk-import-repair`
- Base: `7f2154e30cee549b2084f04497b7a465f8115a4b`
- Test edilen kaynak/index ağacı: `e1f1bda0f5c155893a8eec1b60fd5b4a680b69d1` (rapor eklenmeden önce).
- Kaynak hash manifesti aşağıda; testten sonra ürün/test kaynakları değişmedi.
- Cwd: `/workspace/scratch/40bc8847f0e7/repo`
- Ortam: Linux; Flutter 3.47.9 stable / Dart 3.13.7; izole SQLite memory testleri.
- Son kayıt UTC: `2026-11-03T11:08:02.553437+00:00`.

## Son kontroller

| Kontrol | Komut | Sonuç |
|---|---|---|
| Tüm testler | `CI=true /tmp/personelapp-sdk/flutter/bin/flutter test --no-pub --reporter expanded --timeout 2m` | PASS, exit 0; 1058 başarılı, 1 isteğe bağlı capture testi atlandı; 3 dakika 42 saniye |
| Analiz | `CI=true /tmp/personelapp-sdk/flutter/bin/flutter analyze --no-pub` | PASS, exit 0; No issues found |
| İlgili son regresyonlar | Aynı `flutter test` komutu; OCR 3 dosya, authority, bulk-add, team-fallback, navigation-dismissal, date-consent, date-save testleri | PASS, exit 0; 59 test |
| Format | `dart format --output=none --set-exit-if-changed` + manifestteki 18 Dart dosyası | PASS, exit 0; 0 değişiklik |
| Diff | `git diff --cached --check` | PASS, exit 0 |

Atlanan: `test/features/dashboard/dashboard_visual_capture_test.dart`, mevcut `CAPTURE_DASHBOARD` opt-in koşulu. Ürün davranışı testi atlanmadı.

## RED → GREEN ve inceleme

- Tarih helper'ı öncesi 5 anlamlı RED; bugün/+3 zaten sorulmadan ilerliyordu. Kayıt yolu öncesi dört geçmiş/ileri, genel/hedef senaryosu onay eksikliği nedeniyle RED; son koşuda PASS.
- OCR baseline `7f2154e` kopyasında beş anlamlı RED; tim arayüzü baseline kopyasında beş RED. Paylaşılan kaynak geri alınmadı; geçici kopyalar kullanıldı.
- İlk tam koşu 7 hata verdi: yeni tarih sözleşmesine göre eski hedef tarih/saklama/navigation testleri onay adımına uyarlandı; duplicate ön-onayında loading gösterilmemesi korundu (ayrı single-flight kilidi). Son tam koşu PASS.
- Bağımsız inceleme: `final_review`, index `54c3d493c7a850f4d5ddcd42e7decf89424a9e75`; iki P2 saptadı: METİ hücresinin gerçek nöbet görevini ezmesi ve kişi adındaki Meti'nin genel görevi belirlemesi.
- Her iki bulguya altı sentetik RED regresyon eklendi; açık operasyonel görev önceliği ve yalnız başlıklardan genel görev çıkarımı düzeltildi. Son 59 test ve tüm paket PASS. İsimdeki Meti ve iki kelimelik soyadı korunur.
- Analizdeki yeni async-context uyarısı mounted kontrolü ile giderildi; son analiz temiz.

## Korunan sınırlar ve yapılmayanlar

DB şeması, ana tim üyelikleri, rol/yetki, çakışma kuralları, iki günlük görev kapsamı ve tarih+görev birleştirmesi değişmedi. İptal kayıt yazmaz. Geçmiş ve bugünden 3 günden fazla ileri tarihler yasak değildir; açık onayla belirtilen güne yazılır. Bugün/+1/+2/+3 ek tarih onayı istemez. Hedef kart aktarımında kaynak tarihleri korunarak fark gösterilir; onaylanan hedef güne eklenir.

APK üretilmedi, cihaz verisine erişilmedi, main birleştirilmedi ve dağıtım yapılmadı. Gerçek kamera/MLKit fotoğraf okuma testi yapılmadı; OCR motoru hâlâ düz metin verir, geometrik tablo yeniden kurma eklenmedi. Testler sentetik veri kullanır; yüklenen fotoğraflar ve gerçek personel listesi depoya eklenmedi.

## Kaynak/test hash manifesti

| Dosya | SHA-256 |
|---|---|
| `lib/features/activity/domain/ocr/roster_ocr_name_extractor.dart` | `f5d25d7d6b096ca95bcacef3841c48198f27bed8712b7d9801b2382592a59e14` |
| `lib/features/activity/domain/parser/bulk_text_personnel_parser.dart` | `0be39c750e2bb013b56de72d365ba683b6724203ecd06292a71a9d5ee5b4ebc6` |
| `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_confirm_section.dart` | `0c4e70f02795ff3d3b6458baee167715c1763f771e8e4eab74b6189ef912bd35` |
| `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_save_handler.dart` | `bf77c69cc75218ac2da28a8eb47e02b893aef1decc868ec56ffe62d1c11b41e7` |
| `lib/features/activity/presentation/dialogs/bulk_import/edit_activity_block_dialog.dart` | `e606337606aae017522928eef4a796b47d031fa34f972b2f7a12db898807ecb9` |
| `lib/features/activity/presentation/dialogs/bulk_import/import_date_consent.dart` | `966b44887ad54c6629d29a989f1851cb7dac1e25f487760fb3eceb3709622dfc` |
| `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart` | `874c0b08efe29aa93595c4414c15a9fa1c718f889b9d471c1d1e801964fc3f08` |
| `lib/features/activity/presentation/dialogs/bulk_import_dialog_actions.dart` | `bd8a1a3034053c35ab573be10bccb4f250346ad33f73379b5d1ef27b0925f6d9` |
| `lib/features/activity/presentation/dialogs/task_team_confirmation.dart` | `eab1df3bf50be72e71a3063445e833d41748954261be7414c2b2161d869b988d` |
| `test/features/activity/bulk_add_personnel_to_activity_test.dart` | `a6afd6616a3fceca04d66a519a809712b7a6a93686e893bdc9de5ed4385d29c4` |
| `test/features/activity/bulk_edit_task_team_confirmation_test.dart` | `00003b26b8a1e357463e9bff8f65b1ff5c527dc75aae1e3664b6d86ded4780d5` |
| `test/features/activity/bulk_import_authority_test.dart` | `661daea216596e6ab75d452761d8d483602a48ed3fa793605f5fe256b91fdc5a` |
| `test/features/activity/bulk_import_date_save_test.dart` | `e6c1a6b636612c40941c1947a26193f319aa34ed84a9fab024fca96b7fbd09ca` |
| `test/features/activity/bulk_import_team_fallback_test.dart` | `0c4159c999f976bc95f8c5e4a83d6e17b8d0cdac9502c5f5cb372f57b7161994` |
| `test/features/activity/import_date_consent_test.dart` | `58a824b630a08849942a7efec8c988d33e469c58cfc7a9af552e0dbadad1dfda` |
| `test/features/activity/navigation_dismissal_regression_test.dart` | `52292aadd178d6261fae25e51f5fe2417db480f400886343be68a50d9f67b5de` |
| `test/features/activity/roster_ocr_meti_regression_test.dart` | `7226a75f413d4110b148b63499dcfadffe160c2a516ee777fc7f44fc459230d4` |
| `test/features/activity/task_team_bulk_choice_test.dart` | `dfffe4b5a465811e4442de4e190dfe51b35a08a0a7a73a5b96cc82aaf50158b7` |

## Yerel kanıt hashleri

Ham loglar geçici çalışma alanında tutulur; aşağıdaki hashler kaydı tanımlar. Ham loglar depoya eklenmedi.

| Log | SHA-256 |
|---|---|
| `/tmp/personelapp-full-final.log` | `b39710fb3730c64b3709f3ba0d8fb02444448e672d042a8df9f6fd170150e8e3` |
| `/tmp/personelapp-analyze-final.log` | `28acde92a327fce7b896eaa07c39d8ba0f637251f25f1b6b4280a09fd90cd01a` |
| `/tmp/personelapp-final-targeted.log` | `35448070274c1e97fd48a1588518c07576fc5727e7472c22af595f0589fb74a7` |
| `/tmp/personelapp-date-red.log` | `8c4c340280b3a0a12ebded069116ad9a1aaeac1f9e813f42c6a2d2fea5b517fb` |
| `/tmp/personelapp-save-red.log` | `d01d8a8ab8a55a246dc74bf3425750fa988c83f1bbb2e0c4ba29cdd0e88e4936` |
| `/tmp/personelapp-ocr-red.log` | `926e1496370d254c19669aa35d7093ba8c78a6134ddc2d5f55c7d17c2803015f` |
| `/tmp/personelapp-team-red.log` | `9c6ec540874709c63fc0fe7a7cfe1b743f663feebde01507a40f921c03ff16ce` |
| `/tmp/personelapp-review-red.log` | `6c7c154f872911704ec4855bd44ef7319742144530ca41f52c623225fc8db474` |
| `/tmp/personelapp-final-format.log` | `3e76781306cde0909b9526efe54dfdf979e64d34f29b635ece74a66401544fab` |

## GitHub teslim durumu

Kod ve rapor yerel özellik dalına commit edildi. GitHub push otomatik onay denetiminde BLOCKED: kullanıcı düzeltmeye izin verdi, ancak açık harici yayımlama izni bulunmadığı gerekçesiyle gönderim reddedildi. Remote değiştirilmedi; alternatif araçla gönderim denenmedi. Açık kullanıcı onayı sonrası aynı dal gönderilebilir.
