# Audit düzeltmesi ve imzalı APK

| Alan | Değer |
|---|---|
| ID | 2026-11-01-audit-hardening-apk |
| Hedef | Raporun gerekli düzeltmeleri, regression ve veri koruyan imzalı APK |
| Tier | 3 — kalıcı yetki, yedek snapshot ve native I/O |
| Base | c16a7e5d4b4cb803d8ec9448d045d08d6a3b9acf |
| Cwd/dal | F:/personelapp2 / fix/audit-hardening-apk-2026-11-01 |
| Durum | IN_REVIEW — uygulama/kanıt tamam, Git teslimi hazırlanıyor |
| Yetki | Kullanıcının düzeltme ve APK talebi; main merge/store/deploy yok |
| Sahiplik | Root backup/UI/release/defter; auth worker auth/personnel/activity ve atanmış UI; native worker Kotlin |
| İnceleme | Bağımsız reviewer, salt okunur kaynak/artifact incelemesi |
| Başlangıç kullanıcı dosyaları | .playwright-cli/, .serena/, output/ untracked, korunuyor |
| Aktif sınır | En fazla 3 aktif ajan; test/build slotu tek yazarlı |

## Kabul ve kararlar

- [Plan ve sözleşme](../../docs/verification/audit-hardening-2026-11-01/PLAN.md).
- Şema7 ve backup v2 değişmez. Snapshot/dated history/METİ/X kuralları korunur.
- F01 bağlantılar atomik, belirsiz legacy hesap fail-closed; F02 güncel DB yetkisi
  mutation transaction'ında; F04 boş parola kayıtlı session'ı açmaz.
- F03 DB/audit/sequence aynı snapshot; iki gerçek WAL bağlantısı ile regression.
- F05 50 MiB ham-byte limiti, arka plan I/O, provider cancellation ve stream close.
- Debug integration APK'ları `.qa` suffix alır. Flutter driver cleanup paketleri
  kaldırabildiğinden signed baseline tüm integration testleri bittikten sonra hazırlandı.
  Gelecek drive komutları için --keep-app-running belgelenmiştir.
- Yerel/CI APK/signer envanteri: Actions41256938039 artifact13064165568 gerçekten
  indirilip okundu: 1.0.12+10327, applicationId com.example.personelapp2.
- Yerel 10325 ve CI10327 aynı signer SHA-256:
  afa692e51779950a263e6320220a7738d5c3fe5549c8c4b3eeda062a85ede63c.
- Yeni sürüm1.0.13+10328; doğrulanan önceki kodların üzerindedir.
- Test AVD nizam-nobet-test / emulator-5554 her install öncesi doğrulanır.
  CI10327 baseline install -r başarıyla kuruldu; gerçek kullanıcı cihazı kullanılmaz.

## Kanıt

- Auth RED4 → odaklı GREEN; eksik persisted-account test fixture'ları düzeltildi.
- Backup gerçek bağlantı RED: referans tutarsızlığı. Snapshot patch'iyle GREEN;
  Drift BEGIN IMMEDIATE writer'ı dışlar; export sonrası retry aynı veriyi yazar.
- Native helper RED → GREEN13; reviewer aktif-stream iptal eksikliğini buldu,
  CancellationSignal ve close sahipliği eklendi. Son kaynak incelemesi bekleniyor.
- UI RED → GREEN10; ay kimliği, tek satır tema metni, boş arama başlığı.
- Tam host1026 PASS/1SKIP, root analyze PASS, Android20+4 PASS, native13 PASS.
- Release1.0.13+10328 build/signature/16KiB alignment PASS. Signed10327→10328
  upgrade PASS: kişi/rütbe/tim, görev/HEYBET, admin session, dark tema,
  firstInstallTime ve kurulu APK byte hash'i korundu/doğrulandı.
- Gerçek signed APK native picker exact50MiB okuma, +1byte ret ve küçük kontrol
  PASS; sonrasında sentetik kayıtlar korundu. Restore veya veri temizleme yapılmadı.
- Bağımsız source/artifact reviewer final594 dosya manifestinde0 uyuşmazlık ve
  artifact/signature/alignment/upgrade kanıtlarında blocker olmadığını doğruladı.
- [Teslim raporu](../../docs/verification/audit-hardening-2026-11-01/REPORT.md).
- Ham log ve çalışma çıktıları build/audit-hardening altında; teslim kaydı docs/verification altında.

## Kalan kapsam

DB/backup encryption migration, toplu refactor ve dependency yükseltmesi bu APK'ya
alınmaz. Fiziksel cihaz NOT_RUN. CI sürüm politikası ayrı altyapı işi olarak kalır;
bu teslimde gerçek max versionCode ve signer elle/araçla doğrulandı.
Token/cache/parasal maliyet ölçümü yok; tasarruf iddiası yok.
