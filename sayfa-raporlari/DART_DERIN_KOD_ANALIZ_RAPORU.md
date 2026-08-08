# Dart & Flutter Derin Kod Analiz Raporu

> İnceleme tarihi: 28 Temmuz 2026  
> Kapsam: proje kökündeki `lib/` ve `test/` altındaki bütün `.dart`
> dosyaları. Projede `tool/` altında Dart dosyası bulunmuyor.

## 📊 Genel Değerlendirme Özeti

- **Toplam Dosya:** 63 | **Analiz Edilen Satır:** 20.225
- **Elle yazılmış kod:** 62 dosya / 14.798 satır
- **Üretilmiş kod:** 1 dosya / 5.427 satır (`database.g.dart`)
- **Kritik Skor:** **42/100** (Prodüksiyon Hazırlığı)
- **En Riskli 3 Modül/Dosya:**
  1. `lib/core/database/database.dart`
  2. `lib/core/utils/password_hasher.dart`
  3. `lib/features/activity/data/activity_repository.dart`

Skorun ana gerekçesi, kimlik doğrulamada üretim için güvenli olmayan parola
saklama/doğrulama yaklaşımı, bilinen varsayılan yönetici parolası, veritabanı
migration hatalarının uygulama açılışını durdurmadan yutulması ve çalışmayan
analiz/test kalite kapılarıdır. Uygulamada Riverpod, Drift transaction'ları,
controller `dispose` işlemleri ve domain seviyesinde çakışma testleri gibi
olumlu temeller vardır; ancak mevcut kalite kapıları üretim güvenini kanıtlamaz.

### Analiz ve test kanıtı

- `analysis_options.yaml`, `very_good_analysis` paketini include ediyor; paket
  `pubspec.yaml` içindeki `dev_dependencies` altında yok. Dart MCP analizi bu
  nedenle yalnızca `include_file_not_found` uyarısı verebildi.
- `flutter analyze` 120 saniyede tamamlanmadı. Lint kümesi yüklenemediğinden bu
  koşu “temiz analiz” kanıtı değildir.
- `flutter test`: **22 geçti, 17 başarısız**. Veritabanı testlerinin çoğu
  `sqlite3_initialize` / `sqlite3.dll` native asset yükleme hatasıyla; yeni
  widget testi ise `shaders/ink_sparkle.frag` bulunamadığı için başarısız oldu.
- Statik örüntü taramasında elle yazılmış kodda 54 `setState`, 6
  `shrinkWrap: true`, 5 `NeverScrollableScrollPhysics`, 10 `dynamic`, 22 `late`,
  1 `StreamBuilder` ve 1 `pumpAndSettle` kullanımı bulundu. `StreamController`
  veya doğrudan `.listen()` bulunmadı; bu nedenle açık bir stream kapatma
  sızıntısı tespit edilmedi.

## 🔴 KATEGORİ 1: KRİTİK / BLOKER (Hemen Düzeltme Gerekli)

| Dosya Yolu | Satır | Sorun Başlığı | Açıklama & Etki | Önerilen Düzeltme |
| :--- | :--- | :--- | :--- | :--- |
| `lib/core/database/database.dart` | 57-63 | Bilinen varsayılan yönetici parolası | İlk açılışta `admin / 123456` hesabı oluşturuluyor ve parola düz metin saklanıyor. Uygulamaya/veritabanına erişen herkes yönetici olabilir. | Varsayılan parola oluşturmayın. İlk kurulumda tek kullanımlık, süreli aktivasyon akışı kullanın; parola belirlenene kadar hesabı yetkisiz tutun. |
| `lib/core/utils/password_hasher.dart` | 5-15, 29-32 | Hızlı ve sabit salt'lı parola özeti; düz metin fallback | SHA-256 parola KDF'i değildir; GPU ile hızlı brute-force edilir. Salt bütün kullanıcılar için sabittir. Satır 32 eski düz metin parolayı doğrudan kabul eder. | Kullanıcı başına rastgele salt ile Argon2id/scrypt/PBKDF2 kullanın. Düz metin fallback'i kaldırın; başarılı eski girişten sonra atomik rehash migration yapın. |
| `lib/core/database/database.dart` | 38-45 | Migration hatası yutuluyor | Tablo oluşturma hatası yalnızca loglanıyor; schema sürümü yine yükselmiş kabul edilerek eksik/bozuk şema ile uygulama devam edebilir ve sonraki sorgular çöker. | Migration'ı transaction içinde çalıştırın; hata sonrası yeniden fırlatın ve açılışı durdurun. “Table exists” gibi beklenen durumları schema introspection ile ayırın. |
| `lib/features/personnel/presentation/dialogs/backup_restore_dialog.dart` | 31-46, 65-80 | Dispose sonrası `setState` | Export/import sürerken dialog kapanırsa başarı, hata ve `finally` blokları dispose edilmiş State üzerinde `setState` çağırarak `setState() called after dispose()` üretir. | Her `await` sonrasında `if (!mounted) return;` uygulayın; `finally` içinde yalnızca `mounted` ise state güncelleyin. |
| `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart` | 78-102 | Dispose edilmiş `TabController`/State kullanımı | Fuzzy eşleştirme devam ederken dialog kapanırsa satır 91'de `setState`, satır 94'te dispose edilmiş `_tabController`, `finally` içinde yeniden `setState` çalışabilir. | `matchedBlocks` döndükten hemen sonra `if (!mounted) return;`; `finally` için `if (mounted) setState(...)` ekleyin. |
| `lib/features/activity/presentation/activity_archive_screen.dart` | 420-429 | Async gap sonrası mounted kontrolü yok | Tarih seçici açıkken ekran kaldırılırsa dönen sonuç dispose edilmiş State'i günceller. | `if (!mounted || picked == null) return; setState(...)` kullanın. |

### Kopyalanabilir kritik düzeltme örnekleri

#### 1. Async yaşam döngüsü

```dart
Future<void> _exportBackup() async {
  setState(() => _isLoading = true);
  try {
    final json = await PersonnelBackupService(widget.database).exportBackupJson();
    if (!mounted) return;
    setState(() {
      _textController.text = json;
      _statusMessage = 'Yedek oluşturuldu.';
    });
  } on Object catch (error, stackTrace) {
    if (!mounted) return;
    // Hassas veri içermeyen, yapılandırılmış logger kullanın.
    setState(() => _statusMessage = 'Yedek oluşturulamadı.');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

**Neden?** `State` nesnesinin ömrü, başlatılan Future'dan kısa olabilir.
**Doğru kullanım:** Her async sınırdan sonra UI nesnelerine erişmeden önce
`mounted` doğrulanır.

#### 2. Migration fail-fast

```dart
onUpgrade: (m, from, to) async {
  await transaction(() async {
    if (from < 2) {
      await m.createTable(timUyelikGecmisiTable);
    }
  });
},
```

**Neden?** Migration'ın kısmen başarılı görünmesi veri bütünlüğünü bozar.
**Doğru kullanım:** Migration ya bütünüyle tamamlanmalı ya da rollback edilip
açılış kontrollü biçimde başarısız olmalıdır.

#### 3. Parola migration hedefi

```dart
final verification = await passwordService.verify(
  password: inputPassword,
  encodedHash: user.sifre,
);
if (!verification.matches) return false;
if (verification.needsRehash) {
  await repository.replacePasswordHash(
    user.id,
    await passwordService.hash(inputPassword),
  );
}
return true;
```

`passwordService.hash` uygulaması Argon2id/scrypt/PBKDF2 ve kullanıcıya özel
rastgele salt üretmelidir. `inputPassword == storedValue` karşılaştırması hiçbir
koşulda kalmamalıdır.

## 🟠 KATEGORİ 2: MİMARİ / YAPISAL (Teknik Borç Oluşturur)

| Dosya Yolu | Sorun Türü | Açıklama | Refaktör Stratejisi |
| :--- | :--- | :--- | :--- |
| `lib/features/auth/presentation/login_screen.dart` | Layering / SRP | UI doğrudan Drift tablolarını sorguluyor (154-161, 183-186), seed başlatıyor (32-36), parola doğruluyor ve session saklıyor. Test edilmesi güç, veri katmanına bağımlı bir akış. | `AuthRepository` + `SignInUseCase` oluşturun; ekran yalnızca immutable auth state ve command kullansın. Seed/bootstrap işlemini `main` öncesi application initializer'a taşıyın. |
| `lib/features/activity/data/activity_repository.dart` | God class / primitive obsession | 832 satırlık sınıf tarih taşıma, faaliyet yaratma/birleştirme, çakışma, onay, sorgu ve silme işlerini yürütüyor. Girdi sözleşmeleri `List<Map<String, dynamic>>` (44-58, 368-391, 445-449). Yanlış anahtarlar compile-time'da yakalanmaz. | `ActivityWriteRepository`, `ActivityQueryRepository`, `ApprovalService` olarak ayırın. `PersonnelAssignmentInput(personnelId, duty, note)` immutable tipi kullanın. |
| `lib/features/activity/presentation/activity_form_screen.dart` | God widget / geniş rebuild alanı | 1.138 satırlık ekran veri yükleme, eşleştirme, merge kararı, validation ve yoğun widget ağacını tek State'te tutuyor; çok sayıda `setState` çağrısı geniş ağacı yeniden kuruyor. | Form state'ini `Notifier/AsyncNotifier` içine taşıyın; personel satırı, filtre ve seçim özetini ayrı `ConsumerWidget`lara bölün; `select` ile dar izleme yapın. |
| `lib/features/personnel/presentation/personnel_management_screen.dart` | God widget / feature envy | 958 satırda personel, tim, komutan, filtreleme ve dialog iş akışları aynı sınıfta. UI doğrudan repository command'ları çağırıyor. | Personel/tim/komutan yönetimini ayrı controller ve ekran bölümlerine ayırın; command sonuçlarını typed state ile temsil edin. |
| `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart` | SRP / UI'da orchestration | 889 satırlık dialog hâlâ parse, fuzzy match ve DB kayıt orchestration'ını yapıyor. Payload hazırlamanın yeni `BulkActivityImportPreparer` sınıfına çıkarılması doğru yönde, fakat UI sorumluluğu hâlâ geniş. | `BulkImportController` çıkarın; dialog sadece text/preview/progress göstersin. |
| `lib/features/activity/domain/bulk_activity_import_preparer.dart` | Dependency rule | Domain sınıfı satır 1'de data katmanındaki `activity_repository.dart` dosyasını yalnız `ActivityCreateRequest` tipi için import ediyor. Domain → data bağımlılığı Clean Architecture yönünü tersine çeviriyor. | `ActivityCreateRequest` ve typed assignment DTO'larını domain/application katmanına taşıyın; repository bunları tüketen port olsun. |
| `lib/core/providers/providers.dart` | Global mutable singleton / yaşam döngüsü | `_singletonDb` global değişkeni (9-15) provider override/test isolation'ını zayıflatıyor; `AppDatabase.close()` uygulama/provider yaşam döngüsüne bağlanmıyor. | Provider doğrudan `AppDatabase()` oluştursun ve `ref.onDispose(db.close)` kaydetsin. Kalıcılık gerekiyorsa kök ProviderScope yaşam döngüsü zaten yeterlidir. |
| `lib/core/navigation/app_router.dart` | Yetki sınırı / yeniden yaratma | Yalnız `/pending-approvals` admin rotası; diğer write ekranlarında yetki UI koşullarına bırakılmış. Ayrıca session değişince yeni `GoRouter` örneği oluşturuluyor. | Tüm route policy'lerini merkezi role/permission matrisiyle koruyun; router'ı sabit tutup `refreshListenable`/uygun Riverpod bridge ile refresh edin. Domain command'larında da permission kontrolü yapın. |
| `lib/core/services/session_storage.dart` | Ters bağımlılık ihlali / güven sınırı | Core storage, presentation/provider modeli `UserSessionState`e bağımlı. Rol ve tim kimliği doğrulanmadan SharedPreferences'tan güvenilir session olarak yükleniyor. | Bağımsız `Session` domain modeli ve `SessionStore` interface'i kullanın. Açılışta saklı belirteci/veriyi DB hesabına karşı yeniden doğrulayın. |

## 🟡 KATEGORİ 3: PERFORMANS & KAYNAK (Kullanıcı Deneyimini Etkiler)

Gerçek frame time/rebuild/MB ölçümü yapılmadığı için aşağıdaki “metrikler” statik
proxy değerleridir; kesin kazanç iddiası değildir. DevTools profile-mode ölçümü
ile doğrulanmalıdır.

| Dosya Yolu | Metrik / Statik Proxy | Darboğaz Nedeni | Optimizasyon Önerisi |
| :--- | :--- | :--- | :--- |
| `activity_form_screen.dart` | 1.138 satır; 2 adet nested `shrinkWrap` liste; çoklu `setState` | `shrinkWrap` listeyi viewport yerine tüm çocukları ölçmeye zorlar; her seçim geniş formu rebuild eder. | Tek sliver ağacı (`CustomScrollView`, `SliverList`) kullanın; satır state'ini key bazlı provider/ValueNotifier ile izole edin. |
| `personnel_management_screen.dart` | 958 satır; nested listelerde `shrinkWrap` + `NeverScrollableScrollPhysics` (826-827) | Büyük personel listesinde eager layout ve geniş rebuild. | Hiyerarşiyi tek lazy sliver listesine düzleştirin; filtreyi controller/provider katmanında memoize edin. |
| `monthly_matrix_screen.dart` | 906 satır; nested liste (177-178) | Personel × gün hücre ağacı tek build içinde oluşuyor; ay/personel büyüdükçe layout maliyeti katlanır. | Görünür satır/sütun sanallaştırması veya paginated/iki boyutlu scroll yaklaşımı; hücreleri const/leaf widget'lara ayırın. |
| `dashboard_screen.dart` | 506 satır; nested liste (377-378) | Stream/state değişiminde dashboard alt ağacının fazla kısmı yeniden kurulabilir. | Kart başına `Consumer` ve `ref.watch(provider.select(...))`; küçük listelerde dahi ölçüm sonrası sliver tercih edin. |
| `activity_repository.dart` | `findMatchingActivities` içinde eşleşen her faaliyet için ayrı sorgu (405-409) | N+1 sorgu; eşleşme sayısı arttıkça DB round-trip lineer büyür. | Tek join sorgusu ile faaliyet ve atamaları çekip bellekte gruplayın. |
| `activity_repository.dart` | Onay döngüsünde her kayıt için tüm atama/rapor seti tekrar yükleniyor (677-681, 705-706) | `approveAll` içinde tekrarlı tam tablo sorguları yaklaşık O(P×(A+R)). | Transaction başında snapshot'ları bir kez yükleyin; onaylarla çalışma setini güncelleyin veya çakışmayı SQL ile sınırlandırın. |
| `personnel_fuzzy_matcher.dart` | 416 satır; çok aşamalı fuzzy eşleştirme | Büyük toplu importlarda CPU ağırlıklı isim karşılaştırması UI isolate'ını bloke edebilir. | DevTools CPU profile ile eşik belirleyin; saf DTO girdili matcher'ı `Isolate.run`/`compute` içine taşıyın ve normalize indeksleri önceden hesaplayın. |

`RepaintBoundary` her büyük widget'a körlemesine eklenmemelidir. Önce DevTools
“Highlight Repaints” ile pahalı ve bağımsız boyanan matris/roster bölgeleri
kanıtlanmalı; yalnız bu sınırlar ayrılmalıdır.

## 🔵 KATEGORİ 4: KOD KALİTESİ & STANDARTLAR

### Genel Bulgular

- Etkin lint standardı yok: `very_good_analysis` yapılandırılmış fakat dependency
  eksik. `dart_code_metrics.yaml` bulunmuyor.
- `strict-casts`, `strict-inference` ve `strict-raw-types` açık değil.
- Elle yazılmış 14.798 satır içinde 10 `dynamic` ve 22 `late` eşleşmesi var.
  `late` kullanımlarının çoğu controller/test fixture ve doğru dispose ediliyor;
  esas risk `Map<String, dynamic>` veri sözleşmeleridir.
- Büyük sınıflar: `activity_form_screen.dart` 1.138,
  `military_roster_exporter.dart` 1.045,
  `personnel_management_screen.dart` 958,
  `monthly_matrix_screen.dart` 906,
  `bulk_import_dialog.dart` 889 ve `activity_repository.dart` 832 satır.
- Kaynak içinde doğrudan `.listen()` veya `StreamController` yok; Riverpod/Drift
  stream sahipliği bu açıdan olumlu.

### Özel Dosya Bazlı Uyarılar

| Dosya | Kural | Satır | Öneri |
| :--- | :--- | :--- | :--- |
| `analysis_options.yaml` | `include_file_not_found` | 10 | `very_good_analysis` paketini uyumlu sürümle `dev_dependencies`e ekleyin veya mevcut `flutter_lints` include'una dönün. Sonra strict language seçeneklerini açın. |
| `activity_repository.dart` | avoid-dynamic / typed DTO | 56, 372, 391, 447 | Map anahtarlarını immutable `PersonnelAssignmentInput` alanlarına çevirin. |
| `activity_repository.dart` | long-class / SRP | 102-832 | Query, command ve approval sorumluluklarını ayırın. |
| `activity_form_screen.dart` | long-method / long-class | 498-1.124 | Build ağacını semantik widget'lara çıkarın; state'i controller'a taşıyın. |
| `bulk_import_dialog.dart` | discarded-futures / mounted | 78-103 | Async state güncellemelerini mounted-safe yapın; parser ve persistence'ı UI'dan çıkarın. |
| `database.dart` | avoid-catches-without-on-clauses / error handling | 40-44, 51-103 | Migration'da catch etmeyin; seed hatasını typed startup failure olarak üst katmana iletin. |
| `login_screen.dart` | empty-catches | 32-45 | Hataları tamamen yutmayın; güvenli kullanıcı mesajı ve yapılandırılmış telemetry üretin. |
| `providers.dart` | prefer-immutable-value-types | 27-39 | Session'a value equality (`==/hashCode`, Freezed/Equatable) ve kapalı rol enum'u ekleyin. |
| `session_storage.dart` | enum serialization | 14-38 | Serbest `String role` yerine versioned enum/DTO serialize edin; bilinmeyen değeri reddedin. |
| `personnel_backup_service.dart` | schema validation | 44-55 | `version` alanını doğrulayın; maksimum JSON boyutu/kayıt sayısı ve zorunlu alan sınırları koyun. |

Önerilen minimum analiz yapılandırması:

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - "**/*.g.dart"

linter:
  rules:
    public_member_api_docs: false
    lines_longer_than_80_chars: false
```

Bu dosyanın çalışması için `very_good_analysis` gerçekten
`dev_dependencies` altında bulunmalıdır. CI'da:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

## ✅ KATEGORİ 5: GÜVENLİK & TEST EKSİKLİKLERİ

### Güvenlik

1. **Parola saklama ve default hesap (kritik):** Kategori 1'deki SHA-256,
   statik salt, düz metin fallback ve `admin/123456` kaldırılmadan üretime
   çıkılmamalı.
2. **Yerel session'a koşulsuz güven (yüksek):** `session_role` ve
   `session_tim_id`, SharedPreferences'tan okunup DB hesabına karşı
   doğrulanmıyor (`session_storage.dart:24-39`). SharedPreferences güvenli kasa
   veya yetkilendirme otoritesi değildir.
3. **Yetki yalnız UI/router seviyesinde (yüksek):** Repository mutation
   metotları actor/permission almıyor (`activity_repository.dart:778-830`).
   UI görünürlüğü güvenlik sınırı değildir. Use-case katmanında kullanıcı rolü
   ve tim kapsamı zorunlu doğrulanmalı.
4. **Kontrolsüz backup girdisi (orta):** JSON version okunmuyor; boyut, kayıt
   sayısı ve alan uzunluğu sınırı yok (`personnel_backup_service.dart:44-55`).
   Büyük/yapay girdi bellek/CPU tüketebilir ve beklenmeyen veriyi kalıcılaştırır.
5. **Hata ayrıntısının kullanıcıya sızması (düşük/orta):**
   `backup_restore_dialog.dart:39-41, 73-75` exception metnini doğrudan
   gösteriyor. DB yolu/SQL ayrıntıları açığa çıkabilir. Kullanıcıya sabit hata
   kodu, log katmanına redacted ayrıntı gönderin.
6. HTTP, WebView, `url_launcher`, MethodChannel veya uygulamaya ait FFI kodu
   bulunmadığından timeout, pinning, XSS/CSRF ve platform-channel tip uyuşmazlığı
   kapsamında somut bulgu yok. SQLite bağımlılığı native asset kullansa da
   projede elle yazılmış FFI sahipliği bulunmuyor.

### Test boşlukları

- Parola hasher/auth için hiç test yok: legacy düz metin kabulü, rehash ve
  default admin davranışı güvenlik regresyonuna açık.
- Session restore/rol manipülasyonu ve route authorization testleri yok.
- Migration v1→v2 başarı/rollback ve bozuk migration senaryosu test edilmiyor.
- Backup parser için bozuk tip, aşırı büyük payload, version uyumsuzluğu ve
  transaction rollback testleri eksik.
- Async dialoglar kapatıldıktan sonra Future tamamlanması senaryosu widget
  testiyle doğrulanmıyor.
- Activity repository için önemli testler mevcut olsa da SQLite native asset
  yüklenemediği için 17 test kalite kapısı oluşturamıyor.
- Tek `pumpAndSettle` kullanımı
  `activity_form_modern_ui_test.dart` içindedir. Sonsuz animasyon halinde
  flakiness riski taşır; hedeflenen `pump(Duration...)` ve açık durum assertion'ı
  tercih edilmelidir.
- `integration_test` paketi/yapılandırması bulunmuyor. En az login → faaliyet
  oluşturma → admin onayı → matris görünümü ana akışı gerçek platform DB'siyle
  test edilmelidir.

## 🚀 AKSİYON PLANI (Öncelik Matrisi)

1. **Sprint 1 (Acil)**
   - Default `admin/123456` seed'ini kaldır; ilk-kurulum aktivasyonunu uygula.
   - Argon2id/scrypt/PBKDF2 tabanlı, kullanıcıya özel salt'lı parola servisine
     geç; düz metin fallback'i kontrollü migration sonrası sil.
   - Migration hatalarını fail-fast/rollback yap; v1→v2 migration testini kur.
   - Backup ve bulk-import async yaşam döngüsü hatalarını, archive tarih seçici
     mounted hatasını düzelt.
   - `very_good_analysis` dependency/include tutarsızlığını düzelt; analyzer'ı
     CI'da `--fatal-infos` ile çalışan kalite kapısı yap.
   - SQLite native asset ve shader test ortamını düzelt; tüm mevcut testleri
     yeşile getir.

2. **Sprint 2 (Yüksek)**
   - Auth/use-case katmanı oluştur; DB sorgusu, seed, parola ve session işlerini
     `LoginScreen`den çıkar.
   - Repository mutation'larına actor/permission kapsamı ekle; sadece UI
     gizlemeye dayalı yetkilendirmeyi kaldır.
   - `ActivityRepository`yi query/write/approval bileşenlerine ayır ve
     `Map<String, dynamic>` yerine typed DTO kullan.
   - `approveAll` tekrar sorgularını ve `findMatchingActivities` N+1 sorgusunu
     tek snapshot/join yaklaşımıyla düzelt.
   - Global DB singleton'ını provider-owned yaşam döngüsüne geçir ve `close`
     garantisi ekle.

3. **Sprint 3 (Orta)**
   - Üç büyük ekranı controller + küçük leaf widget'lara böl; provider `select`
     ile rebuild alanlarını daralt.
   - Nested `shrinkWrap` listelerini sliver/lazy listelere dönüştür; matris için
     görünür alan sanallaştırmasını değerlendir.
   - Fuzzy matcher'ı profile et; eşik aşılırsa isolate'a taşı.
   - Session/backup formatlarını versioned typed DTO yap; veri boyutu ve alan
     limitleri ekle.
   - Auth, authorization, async-dispose, migration ve bozuk backup testlerini;
     ardından kritik uçtan uca `integration_test` akışını ekle.

## Tamamlama Ölçütleri

Üretim hazırlık skorunu yeniden değerlendirmeden önce şu kanıtların tamamı
aranmalıdır:

- Bilinen/default veya düz metin kabul edilen hiçbir parola yolu kalmaması.
- Migration hata testinde rollback ve güvenli açılış başarısızlığının görülmesi.
- `flutter analyze --fatal-infos` komutunun sıfır çıkış koduyla tamamlanması.
- `flutter test` komutunun native asset/shader istisnası olmadan tamamen geçmesi.
- En az bir gerçek platform integration testinin login–kayıt–onay–matris akışını
  doğrulaması.
- DevTools profile-mode ölçümünde hedef cihaz için jank/frame ve bellek
  baseline'ının kaydedilmesi; optimizasyon sonrası karşılaştırılması.
