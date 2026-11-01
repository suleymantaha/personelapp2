# Faaliyet arşivi düzeltmeleri ve doğrulama

Tarih: 1 Kasım 2026. Base: 6f8d1d6dff8ca5fccdac11a764ddf1a942708352.
Çalışma alanı: F:/personelapp2-archive-flow; dal: codex/archive-flow-redesign.
Commit, push, merge, release veya dağıtım yapılmadı. Orijinal checkout ve mevcut değişiklikleri korundu.

## Uygulanan akış
- Günlük arşiv: kompakt faaliyet kartları, yıl içeren tarih, görünür seçim/sıralama ve gün/çoklu kart çıktısı girişleri.
- Faaliyet detayı ayrı route: tarih, snapshot timleri, personel/görev/not/onay durumu, mevcut yönetici ve ekleme araçları.
- Açık tim seçim modu, tümünü seç/iptal, bağımsız personel açma oku ve sabit işlem çubuğu.
- Seçim sırasında tüm faaliyete ait ekleme/çıktı araçları gizlenir. Görev değişimi ile başka karta taşıma ayrı kalır.
- Standart çıktılar tek kısa menü: Excel, uzun PNG, PDF, yazdırma ve metin. Saat isteğe bağlı kapalı ayrıntı alanında.
- Kart birleştirme seçili gün/önceki gün, sıra, farklı kişi sayısı, X kuralı, rütbe sırası ve imzaları korur.
- TEMGÜNDRAP ayrı düzenlenebilir taslak akışı olarak korunur. PDF/yazdırma üç mevcut düzeni kullanır.

## Kapatılan doğruluk ve yetki sorunları
- Ortak transaction snapshot'ı: güncel DB hesap rolü/komutan yetkisi; kaynak ID/ad/tarihi; açık atama ID'leri; onaylı operasyonel görev ve tarihsel tim kapsamı.
- TEMGÜNDRAP fresh kaynakları kullanır; yabancı/pending-only kart başlıkları ve boş operasyonlar aktarılmaz.
- Birleşik çıktı ve varsayılan matrix okuması güncel hesap yetkisini doğrular; yetkisi kaldırılmış admin sınırsız kapsam alamaz.
- Günlük Excel/PDF/print/metin saat aralığını da alır. Gerçek XLSX hücreleri ve metin paylaşımı test edildi.
- Faaliyet/tek atama/çoklu atama silme güncel admin rolünü transaction içinde doğrular. Onay sonrası aktör yeniden okunur.
- Eski tim seçimleri stream güncellemelerinde temizlenir; iptal seçimi korur. Son atama silinse de groups state korunup sticky toolbar temizlenir.
- Tarihte yıl, taşma yapmayan takvim sınırları ve desktop seçim/sıralama modlarının ayrılması sağlandı.
- Tim başlıkları çıktıdaki görev timi snapshot adını kullanır.
- Bulk preview/picker güncel actor kapsamında; quick-add kişi ve alias yazıları Save'e ertelendi.
- Personel/üyelik geçmişi/atama/alias/import metadata aynı outer transaction içindedir; hata rollback, tekrar deneme tek kayıt üretir.
- Hedef faaliyete metin aktarımındaki bütün bloklar hedef tarihi gösterir/kullanır.
- Desktop edit save tek uçuşludur; beklerken geri/iptal engeli ve görünür genel hata vardır. Mobil sessiz genel hata da giderildi.

## Gerçek kontroller
| Kontrol | Sonuç | Kanıt |
|---|---|---|
| flutter test --no-pub --reporter expanded | 1013 PASS / 1 SKIP | output/archive-flow-verification/tests-release-check.log |
| flutter analyze --no-pub | No issues found | output/archive-flow-verification/analyze-release-check.log |
| Gerçek GoRouter archive → detail → combined → preview → geri | PASS | archive_router_flow_test.dart; router-flow.log |
| Android debug QA build | PASS | android-build-final.log; qa-apk-package.txt |
| Android drive, nizam-nobet-test / emulator-5554 | PASS | android-flow-final.log |
| Dört gerçek emülatör ekranı | Görsel olarak incelendi | device/01-archive.png … device/04-output.png |
| git diff --check / format | PASS | verification.json; format.log |

SKIP, görev dışı CAPTURE_DASHBOARD görüntü yakalama testinin varsayılan opt-in koşuludur.
Android senaryosu gerçek UI/Drift/export metni yolunu sentetik in-memory DB ile çalıştırır; yalnız son OS paylaşım handoff'u mock'tur ve mesaj gönderilmez.
Seçili tim çıktısında pending/diğer tim dışlanması; günlük çıktıda kapsam ve saat; kayıtların birebir korunması doğrulanır.
Gerçek yazıcı, fiziksel cihaz, iOS/web paylaşımı ve release upgrade bu görevde çalıştırılmadı.

## Bağımsız inceleme
Reviewer, review-snapshot.json içindeki 63 dosyanın hash'ini doğruladı ve üç somut bulgu bildirdi.
Kalan combined admin authority, tek/toplu silme authority ve son atamada sticky toolbar sorunları regression RED ile yeniden üretildi; düzeltmeler focused ve tam testlerde geçti.
İnceleme sonrası bu düzeltmelerin son kabulü koordinatörün kaynak/test doğrulamasıdır; ikinci bağımsız inceleme yapıldığı iddia edilmez.

## Android izolasyonu ve tekrar çalıştırma
- Ayrı read-only AVD kullanıldı. QA APK'nın gerçek package name'i aapt ile com.example.personelapp2.qa olarak doğrulanmadan son kuruluma geçilmedi.
- Suffix yalnız integration_test/archive_flow_android_test.dart hedefinde etkindir; normal debug/release kimliği değişmez.
- Global Flutter JDK ayarı eski dizine işaret ediyordu. APPDATA görev altındaki flutter-config dizinine yönlendirilerek kurulu JDK 21 için görev özel config kullanıldı; global ayar değiştirilmedi.
- İlk denemede env Gradle property QA suffix'i üretmedi; Flutter read-only geçici katmanda eski test paketini yeniden kurdu. Kalıcı AVD verisi değişmedi; yeni read-only boot'ta orijinal release yolu geri geldi.
- Son denemede orijinal release paketi kurulum öncesi/sonrası aynı path'tedir; original-package-before.txt ve original-package-after.txt eşleşir.
- integration_test girişi Türkçe tarih verisini kendi başlatır; unit test config'ine bağımlı değildir.
- Build: flutter build apk --debug --no-pub --target=integration_test/archive_flow_android_test.dart.
- AVD ve APK kimliği doğrulandıktan sonra: flutter drive --no-pub --driver=test_driver/archive_flow_driver.dart --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk --target=integration_test/archive_flow_android_test.dart -d emulator-5554.
- Bu QA APK dağıtım paketi veya release güncelleme kanıtı değildir.

Tam source hash manifesti, UTC/exit code kayıtları ve artifact hash'leri output/archive-flow-verification/verification.json ve final-snapshot.json içindedir.
