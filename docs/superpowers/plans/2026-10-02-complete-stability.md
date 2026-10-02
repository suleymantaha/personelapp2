# Personelapp2 kalan düzeltmeler — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Kullanıcı tüm kalan işleri sırayla bitirmeyi açıkça istedi; yeniden kapsam onayı istemeden ilerle. Sonunda bağımsız dal incelemesi yap.

**Goal:** 19 maddelik raporun kalan sorunlarını giderip mevcut çıktıları koruyarak güvenilir personel, geçmiş ve tim görev takibi sağlamak.

**Architecture:** Mevcut Flutter/Riverpod/Drift bileşenlerini koru. Personel kimliği mevcut sabit veritabanı ID'sidir; belirsiz metin aktarımında mevcut kişiyi güncelleme/yeni kişi kararını görünür yap. Geçmiş için atamada görev timini sakla; ayrılan personeli pasifleştir. Saat verisi yokken saat üretme; günlük görev kuralını ve saat metnini açıkça koru.

**Tech Stack:** Flutter, Dart, Riverpod 2, Drift/SQLite, GoRouter, mevcut PDF/Excel kitaplıkları.

**Spec:** `/workspace/scratch/98775bfede29/Personelapp2_Kod_Inceleme_2026-10-02.md`, 19 bulgu ve kabul ölçütleri; kullanıcının çıktı biçimini koruma ve tüm işi bitirme talimatı.

## Global Constraints

- Son ekran sürümü PR #26 ve doğrulanan PR #27 düzeltmeleri temel alınır: b0d5c7d79e48624ae3734e1c1586a9a5664492c7.
- Excel/PDF tablo sütunları, sayfa düzeni ve mevcut sıralama korunur; onay/kimlik filtresi doğruluğu iyileştirilir.
- Gerçek kayıtlara kalıcı silme veya otomatik isim bazlı birleştirme uygulanmaz.
- Yerel Flutter çalıştırması otomatik güvenlik denetimince engellendi. Flutter analiz/test/codegen doğrulaması GitHub Actions'ta yapılır; bu engel yerelden dolanılmaz.
- Önce davranış testi, GitHub üzerinde beklenen başarısızlık, sonra düzeltme; grup bitiminde tam testler ve analiz.
- Yeni dal otomatik commit/push; main'e birleştirme bu çalışmanın parçası değildir.

## Review Focus

- Yetki değişiminden önce açılmış oturum eski timde işlem yapamaz.
- Rütbe ve tim değişikliği mevcut personelin sabit ID'sini/atamalarını korur.
- v4 yedek ve veritabanı yükseltmesinde eski atamalar, raporlar ve telefonlar kaybolmaz.
- Ay sınırını aşan görev, aynı adlı farklı kişiler ve aynı gün farklı görevler ayrı izlenir.
- Kaydetme hatası veya Android geri hareketi taslağı kaybetmez; tekrar denemek mümkündür.

## Task 1: Arşiv, komutan devri ve resmî çıktı (4, 13, 14)

**Files:** activity_repository_queries.dart, activity_repository.dart, personnel_repository.dart, activity_archive_actions.dart, activity_detail_sheet.dart; commander_delegation_test.dart, activity_authorization_test.dart, yeni stability_regression_test.dart.
**Interfaces:** watchAllActivities(limit/offset/startDate/endDate) geriye uyumlu kalır; varsayılan tam kapsam, açık limit varsa sayfalama. assignCommanderToSquad/assignPersonnelAsCommander ilişkileri tek transaction'da değiştirir. _requirePersonnelScope güncel kullanıcı yetkisini veritabanından doğrular.
- [ ] 150 faaliyetle eski güne erişim, A→B komutan devri, tim değiştirme, eski oturum yetkisi ve onaylı çıktı davranış testlerini ekle.
- [ ] GitHub Actions'ta beklenen başarısızlıkları oku.
- [ ] Arşiv kapsamını ve komutan ilişki temizliğini düzelt; ortak onaylı görev filtresini iki çıktı girişinde kullan.
- [ ] Analiz ve tüm testleri doğrula, commit/push; kanıtı aşağıdaki ilerleme kaydına ekle.

## Task 2: Kimlik ve metin aktarımı (2, 3, 15)

**Files:** personnel_import_models.dart, personnel_import_draft.dart, bulk_personnel_import_dialog.dart, personnel_repository.dart; bulk_import_learning_service.dart, personnel_fuzzy_matcher.dart, bulk_import_dialog/actions.dart, bulk_activity_import_preparer.dart.
**Interfaces:** import entry için optional existingPersonnelId ve açık yeni-kişi kararı; eski çağrılar tekrar aktarımda geriye uyumlu. Takma ad anahtarı tim bağlamını içerir; eski global eşleştirme belirsiz kişileri otomatik seçemez. declaredTotals ve ignoredLineCount önizlemeye taşınır.
- [ ] Aynı tim adaşları, rütbe değişikliği ile aynı ID, farklı timde aynı kısaltma, bildirilen toplam uyuşmazlığı testlerini yaz ve RED doğrula.
- [ ] Mevcut kişiyi güncelle/yeni kişi seçimi ve tim bağlamlı öğrenmeyi uygula; kayıtta ID ve üyelik geçmişini koru.
- [ ] Toplam farkını bloklayan doğrulama/uyarı ve atlanan satır bilgisini göster; saat metnini günlük kayıt açıklamasında sakla.
- [ ] Tüm testleri doğrula ve commit/push.

## Task 3: Geçmiş ve veritabanı güvenliği (7, 8, 16, 17, 19)

**Files:** tables.dart, database.dart/generated, personnel_repository.dart, activity_repository_assignments/queries.dart, app_backup_service.dart, providers.dart, dashboard_settings.dart.
**Interfaces:** personel aktif ve demo alanları; atamada görev timi snapshot'ı. v5 migration varsayılanlarla geriye uyumlu; eski atamaların timi mümkünse tarihli üyelikten alınır, bilinmeyen geçmiş bugünkü timden tahmin edilmez. deletePersonnel normal kullanımda pasifleştirme; tim değişimi ve geçmiş transaction'da. Varsayılan timler ilk kurulumda bir kez oluşturulur.
- [ ] Pasifleştirme sonrası eski atama/rapor, transaction rollback, tarihli tim üyeliği, yeniden adlandırılan timin tekrar yaratılmaması, demo tekrar/filtreleme ve v4 yedek restore testlerini yaz; RED doğrula.
- [ ] Şema/migration/codegen ve yedek uyumluluğunu uygula; normal seçimlerde pasif/demo kayıtları dışarıda tut, geçmiş çıktıda kimliği koru.
- [ ] Komutan personel taşımasını ortak transaction hizmetine bağla; demo oluşturmayı geliştirme kullanımına sınırla.
- [ ] Tüm testleri ve migration/codegen çıktısını doğrula; üretilmiş kaynakları da commit/push.

## Task 4: Tim görev çizelgesi (5, 6, 7, 12)

**Files:** matrix_repository.dart, team_duty_analytics_dto.dart, team_duty_calendar_modal.dart ve mevcut tüketiciler.
**Interfaces:** Gün içinde birden fazla görev grubu; kimlikten katılımcı sayısı. Onaylı operasyonel görev yükü, bekleyen ve izin/rapor ayrı. Gerçek süre bulunmadığında toplamGorevSaati için uydurma 24×gün hesabı kullanılmaz; UI kapsanan gün gösterir.
- [ ] Aynı gün 5 Gülüşkür+3 Heybet, aynı adlı farklı ID, izin/bekleyen, ay geçişi ve tim değişikliği testlerini yaz; RED doğrula.
- [ ] Tim/tarih/görev türü gruplarını ve ölçümleri uygula; eski DTO çağrılarını varsayılanlarla koru.
- [ ] Takvim/modal görünümünü görev gruplarını gösterecek şekilde güncelle; PDF/Excel düzenine dokunma.
- [ ] Tüm testleri doğrula ve commit/push.

## Task 5: Geri dönüş, paylaşım ve hata toparlama (9, 10, 11)

**Files:** add_personnel_dialog.dart, temgundrap_form_screen.dart, temgundrap_repository.dart, temgundrap_pdf/excel_exporter.dart, mevcut gezinme ve roster_share_file yardımcıları.
**Interfaces:** Form adımı geri hareketi, taslak bırakma onayı ve kayıt sırasındaki koruma tutarlı. Kaydetme finally ile açılır; başarısız yazım görünür. Paylaşım await edilir ve benzersiz dosya kullanır.
- [ ] Geri tuşu/ok, adım dönüşü, kirli taslak, kayıt hatası/tekrar deneme ve tekrarlı PDF/Excel dosyası testlerini yaz; RED doğrula.
- [ ] Ortak davranışı uygula; belge düzenini koru, hatada taslağı sakla ve kullanıcıya sonucu göster.
- [ ] Tüm testleri doğrula ve commit/push; fiziksel cihaz paylaşım kontrolünü yapılmış gibi raporlama.

## Task 6: Ortak kurallar ve son bakım (18 ve yapısal maddeler)

**Files:** password_hasher/validation helper, login_screen.dart, dashboard_settings.dart, personnel_repository.dart; personnel_search_service.dart, app_backup_service.dart, mevcut iskelet servisler.
**Interfaces:** İlk oluşturma/değiştirme/repository için aynı 12 karakter minimumu; mevcut kullanıcıları kilitlemez. Fuzzy mesafe düşük oldukça daha güçlü sonuç. Yedek kapsamına mevcut kart sıralaması ve onaylayan varsayılanları dahil edilir.
- [ ] Kısa yeni parola, doğru fuzzy sıralaması ve tercih restore testlerini yaz; RED doğrula.
- [ ] Ortak kuralları ve yedek kapsamını uygula. Kullanılmayan iskeletleri referans taramasıyla doğrula; yalnız gerçekten kullanılmayanları kaldır.
- [ ] Tüm testleri/analizi ve release APK'yı doğrula.
- [ ] Bağımsız final dal incelemesi; önemli bulguları RED→GREEN düzelt, raporun 19 maddesini ayrı durumla güncelle ve PR'ı hazır hâle getir.

## İlerleme ve karar kaydı

- Başlangıç: PR #27 başarılı; 438 test ve APK. Kalan işlerin hiçbirisi tamamlanmış sayılmıyor.
- Ruling: Yeni bir sicil zorunluluğu eklemek yerine mevcut sabit personel ID'si ve açık import kararı kullanılacak — mevcut kayıtlar ve çıktı formatı korunur — yanlış seçim kullanıcıya gösterilen adaylarla düzeltilebilir.
- Ruling: Günlük görev kuralı korunacak; okunmuş saat açıklamada saklanacak, gerçek saat hesabı uydurulmayacak — mevcut çakışma modeliyle uyum — saatlik planlama ayrı özellik olur.
- Ruling: Önce arşiv/yetki, sonra kalan kimlik ve tarih modeli — geçmiş ve yetki risklerini erken sınırlar — kullanıcı talimatı tüm işleri kesintisiz sürdürmektir.

- 2026-10-02 Task 1 RED: run 37022796129 — 438 eski test geçti, 5 yeni test beklenen davranışlarla başarısız oldu. Düzeltme 17c71977efeb448feaebc13e468e5dab9519f25c: sınırsız varsayılan arşiv, çift yönlü komutan temizliği, yazımda güncel hesap kontrolü, onaylı operasyonel çıktı filtresi. Tam GREEN henüz yok: çıktı testi doğruluk assertions geçti ancak Drift dinleyici temizliğinde test timer sorunu görüldü; ek kapsam sağlayıcısı testi var.
- 2026-10-02 Task 2 ve geçmiş/çizelge RED: run 37024473935 — kimlik/rütbe, global takma ad, toplam/saat, kalıcı silme, üyelik rollback, varsayılan tim ve görev ölçümü testleri beklenen hataları gösterdi. Sonuç GREEN olarak kaydedilmedi.
- Ruling: Kritik gerçek davranış testleri CI'da ayrı ilk adımda çalıştırılır, ardından bütün mevcut testler çalışır — yeni hata yolunu doğrudan gösterir — tam suite atlanmaz. Yerel Flutter engeli korunur.

- Task 3, 5, 6 ek RED kanıtı: run 37025822586, job 110900638377 — v4 migration alanları eksik, eski komutan oturumunda okuma açık, onaylayan/kart sırası restore kaybı, kirli TEMGÜNDRAP geri çıkışı, bozuk JSON ve tekrar paylaşım dosya adı testleri beklenen davranışları gösterdi. İşlem yeni commit ile iptal edildi; bu bir GREEN çalışması değildir.
- Task 3: v5 aktif/demo alanları ve görev timi ID/ad snapshot'ı, üyelik tarihinden geri doldurma, pasifleştirme, tarihsel roster kimlikleri ve debug demo temizliği uygulandı. Codegen CI'da çalışır ve kaynak artifact olarak alınır; üretilmiş dosya elde edilmeden bu grup tamamlandı sayılmaz.
