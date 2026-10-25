# Sınırlı kod analizi (opt-in)

Bu belge yalnızca açıkça istendiğinde uygulanır. Otomatik model yönlendirmesi,
global ayar, yeni runtime veya ajan ordusu etkinleştirmez. Varsayılan yürütme
mevcut koordinatörün native araçlarıyla salt okunur incelemedir.

## Akış

1. Hedefi tek bir soruya indir; geçerli AGENTS.md kurallarını ve Git durumunu oku.
2. İzinli kaynakları tam göreli yollarla belirle; içerik SHA256 değerlerini kaydet.
   Kullanıcı değişikliklerini koru. Personel verisi, sırlar ve tüm sohbet geçmişini
   analiz paketine ekleme.
3. İlgili çağrıları, testleri ve bağımlılık sınırlarını yerel aramayla kontrol et.
   Eksik bağlamda kapsamı sessizce genişletme; eksik dosyayı veya sınırı raporla.
4. Gerçek analyzer/test komutunu çalıştır; cwd, UTC, exit code ve kaynak hashlerini
   kaydet. PASS, FAIL, BLOCKED ve NOT_RUN durumlarını ayır.
5. Bulguyu dosya/satır kanıtıyla sun. Test boşluğu, varsayım ve doğrulanmış hatayı
   ayır. Salt analiz isteğinde uygulama kodunu değiştirme.

## Doğrulanmış küçük hedef

Soru: PDF/Excel dosya adı normalizasyonu neyi garanti ediyor, hangi sınırlar test dışı?
Başlangıç kaynakları:
- `lib/core/utils/export_file_name_helper.dart`
- `test/unit/export_file_name_helper_test.dart`

Yardımcı :10-22 başlık/tarihi temizler; :24 uzantıyı küçük harfe çevirip noktaları
kaldırır; :26 tarihi substring kontrolüyle yinelenmekten korur. Mevcut üç test
Türkçe karakterleri, başlık temizliğini ve tarih tekrarını kapsar.
Boş başlık, ayrılmış adlar, geçersiz uzantı ve substring sınırları bu dosyada
kapsanmıyor; bunlar tek başına doğrulanmış uygulama hatası değildir.
Yerel aramada bulunan altı üretim çağrısı sabit `pdf` veya `xlsx` kullanıyor:
`military_roster_exporter.dart`:212,247,301; `pdf_roster_actions.dart`:22;
`temgundrap_excel_exporter.dart`:212; `temgundrap_pdf_exporter.dart`:263.

2026-10-23 UTC; cwd `F:\personelapp2`;
HEAD `91e99200b8c3d5e71ce2c0c7321007de7db6a519`.
Başlangıç Git durumu: yalnızca kullanıcıya ait değiştirilmiş `AGENTS.md`.

| Kontrol | Başlangıç UTC | Sonuç |
|---|---|---|
| `C:\DevMobile\flutter\bin\cache\dart-sdk\bin\dart.exe analyze` | 23:41:00 | PASS, 0 issue, exit 0 |
| `C:\DevMobile\flutter\bin\flutter.bat test --no-pub test/unit/export_file_name_helper_test.dart` | 23:41:09 | PASS, 3 test, exit 0 |
| Tam test paketi / cihaz testleri | — | NOT_RUN; bu dar analizde çalıştırılmadı |

Kaynak SHA256:
- Yardımcı: `A39410057FA5CD1FD0B8FEB24EBF075734A9AF897BE4B2823030A5CD3FE694DB`
- Test: `20C3067968045607C0E419276E34A5D952C0B319E755B648C1CA975698871CDA`

Dart sürümü: 3.13.2. Kontroller komuta özel native onayla çalıştı; bu onaylar
kalıcı klasör yetkisi oluşturmaz. Normal kısıtlı oturumda analyzer yol çözümlemesi
OS error 5, Git status ise exit 128 vermişti. Reddedilen işlemi başka yoldan
atlatma; gerekiyorsa desteklenen komuta özel onayı kullan.

## Delegasyon ve karşılaştırma sınırı

Bu iki dosyalık hedef için ek seçici çağrısı gerekli değil. Daha büyük bir işte
native alt ajan kullanılacaksa yalnızca açık görev paketi aktar; tüm geçmişi
fork etme. Model seçimi ve araç kullanılabilirliği çalıştırma ortamınca doğrulanır.
Skill içindeki model adı, çalışan otomatik seçim veya maliyet avantajı kanıtı değildir.

Gelecekte onaylı gerçek karşılaştırma için önerilen bütçe:
- Aynı hashli kaynak havuzu ve aynı kalite ölçütleri; en çok 8 dosya / 32 KiB kaynak.
- Sarılmış istek en çok 40 KiB, yanıt en çok 4000 karakter; taşmada dur.
- Aday akışta toplam en çok 2 model denemesi, baseline için 1; otomatik retry yok.
- Gerçek model, kullanım, gecikme, başarısız çağrılar, kapsama ve bağımsız kaliteyi ölç.

Bunlar önerilen sınırlar; token/fiyat tasarrufu ölçümü değildir. Bu entegrasyonda
model/benchmark çağrısı yapılmadı. Yeni harici sağlayıcıya özel proje içeriği gönderimi
için ilgili açık yetki gerekir; eski kit corpus izni proje corpus izni sayılmaz.

## Desteklenmeyen otomatik yollar

Python kitindeki `investigate_code.py` Dart desteklemez; buraya kopyalanmaz.
Projede `package:`/`dart:` import, `export`, `part`/`part of`, üretilmiş Drift kodu
ve Riverpod bağlantıları bulunur. Bir Dart adaptörü ayrı iştir: parser tabanlı
çözümleme, açık package haritası, üretilen kod politikası ve desteklenmeyen
conditional/dynamic bağlarda güvenli duruş gerekir. Tam semantik kapanış iddia edilmez.

`scripts/dispatch_task.py` salt analiz giriş noktası değildir; worktree oluşturma,
dosya uygulama ve kaldırma yan etkileri vardır. Bu akışta çalıştırılmaz.
## Çalıştırılabilir proje wrapper'ı (opt-in)

`scripts/analyze_role.py` mevcut harici kitin `scripts/run_role.py` girişini çağırır.
`--kit-root` ve `--config` zorunludur; proje model ID'si veya varsayılan pahalı config
saklamaz. Kit güvenilen kod olmalıdır; config merkezi operatör eşlemesidir.
`economical` ekonomik olduğu ölçülmüş model anlamına gelmez.

PowerShell, proje kökünden; aşağıdaki yollar bu makinedeki mevcut merkezi kit içindir:

```powershell
$kit = 'C:\Users\baba\Documents\Codex\2026-10-23\task-4\adaptive-model-routing'
$central = Join-Path $kit 'examples/routing/lean-completion-profiles.json'
python -B scripts/analyze_role.py --kit-root $kit --config $central --role economical --goal 'Dosya adı sözleşmesini ve test sınırlarını incele' --replay scripts/analysis-replay.json
```

Bu komut OFFLINE wiring kontrolüdür; replay metni gerçek analiz sonucu değildir.
`strong` rolü de desteklenir; replay fixture'ı o rol için `decision` cevabı içermelidir.
Model değişikliği yalnızca merkezi config'de yapılır. Wrapper model seçmez/rank etmez.
Kaynak listesi `scripts/analysis-files.json`: yalnızca helper ve mevcut testi içerir.
Glob, repo taraması, import çözümleme veya otomatik bağlam genişletme yoktur.
Bridge kaynakları dosya/satır etiketiyle alır; bağımlılık tamlığı iddiası yoktur.

Her invocation en çok 1 deneme, 0 fallback/escalation; cevap limiti 4000 karakter.
Bridge'in mevcut kaynak/payload sınırları uygulanır. Çoklu invocation ortak bütçe sayılmaz.
Eksik kit/config veya geçersiz profil BLOCKED olur; alternatif modele sessiz geçmez.
`--live` ayrı açık seçenektir ve wrapper zorunlu katalog kontrolü uygular.
Gerçek yetkili katalog `--catalog` ile verilmezse çağrı yapılmadan durur; katalog
uygunluk/fiyat keşfi değildir. `--require-cost` maliyet kanıtı yokluğunda durur.
Bu teslimatta canlı kullanım yetkilendirilmedi veya çalıştırılmadı.

`REVIEW_REQUIRED` + exit 0 yalnızca incelenebilir aday demektir; `answer:null`,
`quality:NOT_VERIFIED` korunur. Native sohbet, `spawn_agent` ve tüm proje görevleri
otomatik yönlenmez; wrapper bilerek çağrılmalıdır. Python resolver taşınmadı.

Offline sözleşme testleri (fixture kimlikleri gerçek sağlayıcıya gönderilmez):

```powershell
$env:ROLE_PROJECT_ROOT = (Get-Location).Path
$env:ROLE_KIT_ROOT = $kit
python -B scripts/test_project_role.py
```

Kanıt: [görev kaydı](../tasks/active/2026-10-24-role-bridge-opt-in.md).
