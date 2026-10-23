# Günlük tim görev raporu — 24 Ekim 2026

## Kapsam ve sayım

Ana görünüm tek gün açılır. Her tim bir kartta görev türleri ve tekil kişi sayılarıyla görünür. Tim veya görev seçilince kaynak faaliyet kimliğine göre ayrı kartlar açılır. Aynı faaliyet içindeki yinelenen personel tek sayılır; aynı adlı ayrı faaliyetler birleştirilmez.

`DutyCoverage.coveredDates` iki günlük görevler için matrise ertesi günü ekler. `AnalyticsMetrics.dutyDays` takvim kapsamını sayar. Eski rapor bu kapsamı doğrudan “gün” etiketiyle sunuyordu. Yeni ana rapor ve detay yalnız görev kaydı/kişi gösterir. Kaynak faaliyet başlangıcı korunur, önceki günden gelen kayıt etiketlenir. Matrix ve dönemsel kapsam hesapları değiştirilmez.

## Bilinmeyen tim kök nedeni

Android `emulator-5554` üzerindeki uygulama SQLite dosyası yalnız bellek içine okunup aggregate SQL ile incelendi. Yerel kopya veya personel adları rapora yazılmadı. Gözlenen schema version 6:

| Kontrol | Sayı |
|---|---:|
| Toplam atama | 4685 |
| Görev tim ID'si eksik | 2606 |
| Bunlardan tim adı bulunan | 0 |
| Personelin hiçbir tim üyelik geçmişi yok | 2590 |
| Üyelik geçmişi görev tarihinden sonra başlıyor | 16 |
| Görev tarihinde kullanılabilir üyelik geçmişi var | 0 |

`database.dart` v5 migration'ı tarihsel snapshot alanlarını ekler; `backfillTaskTeamsFromHistory` yalnız görev tarihine eşit/önceki üyelik kaydını kullanır. `TeamAnalyticsRepository` null snapshot'ları ayrı tutar. Bu 2606 kaydı güncel tim üyeliğiyle doldurmak tarihsel doğruluğu bozabilir; veri onarımı yapılmadı.

Yeni arayüz eksik kayıtları açıklamasıyla açar. Bu kayıtların doğru time alınması için güvenilir tarihsel tim bilgisi gerekir. Bu inceleme, tüm atamaların hangi eski yazılım sürümü/aktarım yolunda oluştuğunu kanıtlamaz; mevcut verideki eşleştirme engelini kanıtlar.

## Doğrulama

- PASS: widget regresyonları; gün-etiketi, tim filtresi ve aylık dönüş hataları önce başarısız testle yeniden üretildi.
- PASS: `flutter analyze`, 0 issue (Flutter 3.47.2 / Dart 3.13.2).
- PASS: son tam `flutter test --reporter expanded`, 703 test; `build/daily-analytics-full-tests.log`, exit 0.
- PASS: `flutter drive --driver=test_driver/daily_analytics_screenshots.dart --target=integration_test/daily_team_analytics_android_test.dart -d emulator-5554`, exit 0. Bir davranış senaryosu (runner teardown dahil +2). Gerçek Android SQLite + provider + UI; sentetik in-memory fixture kullanır, gerçek veritabanını açmaz. Gün ileri/geri, tim/görev/personel açılımı, ertesi gün devamı ve beş ilgili tablonun değişmezliği doğrulandı.
- PASS: 320px / 1.3 metin ölçeği ile tam ekran ve açık detay, açık/koyu tema widget testleri.
- PASS: bağımsız kaynak incelemesi; filtre dışında kalan timlerin 0 kayıt gösterilmesi bulgusu giderildi ve tekrar incelendi. Runtime kontrolleri koordinatör tarafından yürütüldü.
- PASS: üç Android ekran görüntüsü görsel incelendi; `build/daily-analytics-evidence/`.
- Son doğrulama zamanı: 2026-10-23 21:53 UTC (24 Ekim, Türkiye). Kaynak tabanı `76d1ebb` + görev diff'i; `daily-team-report.sha256` manifesti.
- Mevcut üçüncü taraf Android pluginlerinin KGP uyumluluk uyarısı var; bu çalışmada dependency değiştirilmedi ve Android build/test başarılı.
- Commit/push/yayın: yapılmadı. Kullanıcının personel UI çalışması kapsam dışı.
- PASS: normal debug build/install/launch. Ancak son veri kontrolünde gerçek atama sayısı 0 bulundu. Flutter drive varsayılan stop aşaması uygulamayı uninstall eder (`flutter_tools/lib/src/drive/drive_service.dart:280-287`); gerçek emülatör verisi bu yüzden silindi. UI testinin in-memory değişmezlik kontrolü bu kurulum yan etkisini kapsamadı. Kullanıcıya açıkça bildirildi. 24 Ekim 00:14 tam yedeği 4685 atama / 2606 bilinmeyen / 284 faaliyet / 186 personel içeriyor; geri yükleme hazırlanıyor. Önceki hatalı korundu notu geri çekildi.

## Kurulum olayı son kontrolü

Geri yükleme yürütülmeden önce yapılan yeni salt-okunur kontrolde bütün kayıtlar yeniden mevcuttu. Recovery testi çalıştırılmadı; geçici recovery kaynak dosyası ve uygulama içine kopyalanan geçici yedek kaldırıldı. İndirilenler içindeki orijinal yedek değişmedi. Veriyi geri getiren başka işlem kesinleştirilemedi.

00:14 yedeğiyle yalnız sayılar değil her satır/sütun karşılaştırıldı: users 1, squads 17, personnel 186, activities 284, assignments 4685, reports 0, membershipHistory 16, aliases 512, bulkImportHistory 194; dokuz tablo da MATCH, farklı satır 0. SharedPreferences liste/boolean kodlaması çözüldükten sonra 44 yedek tercihinin 43'ü eşleşiyor; yalnız app_theme_mode farklı. TEMGÜNDRAP ve kart sıraları dahil yedek tercihler doğrulandı. Görev başlangıcının tam byte snapshot'ı tutulmadığı için yedek sonrası olası değişikliklerin eşdeğerliği iddia edilmez.

Tekrar çalıştırma: yalnız ayrılmış test emülatöründe, `flutter drive --keep-app-running --driver=test_driver/daily_analytics_screenshots.dart --target=integration_test/daily_team_analytics_android_test.dart -d <test-device>`. Test öncesi geri yüklenebilir tam snapshot alınmalı; mevcut kullanıcı verili cihaz tekrar kullanılmamalı. `drive.dart:400-403` keep-app-running halinde uninstall yapan stop çağrısını atlar. Uygulama normal debug paketiyle çalışır durumda bırakıldı; ek kurulum yapılmadı.
