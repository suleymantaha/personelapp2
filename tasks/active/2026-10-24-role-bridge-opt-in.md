# Proje-yerel role bridge opt-in

- ID: 2026-10-24-role-bridge-opt-in; Tier 2, yeni CLI entegrasyonu.
- Amaç/kabul: economical/strong merkezi config üzerinden; iki Dart dosyası;
  offline replay, config değişimi, fail-closed; uygulama/model ayarı değişmez.
- Koordinatör/tek yazar: mevcut görev ajanı; native sıralı yürütme.
- Ek model/ajan çağrısı yok: kullanıcı bu turu offline doğrulamayla sınırladı.
- Cwd: F:\personelapp2; base: 32c36711321a541263531f2784c4e498641765b7.
- Başlangıç: AGENTS.md ve eşzamanlı Nizam theme/dashboard/l10n/test/ledger
  değişiklikleri vardı. Bunlar korunur; ledger yalnızca bu kayda bağlantı eklenir.
- Sözleşme: harici kit docs/role-bridge.md, run_role.py CLI; değişiklik yok.
- Sahiplik: scripts/analyze_role.py, analysis-files.json, analysis-replay.json,
  test_project_role.py; docs/bounded-analysis.md; bu kayıt ve ledger ek satırı.
- Bütçe: sıfır canlı çağrı, rol başına en çok 1 replay denemesi; fallback/escalation 0.
- Durum: DONE (offline kapsam); merge/yayın NOT_REQUESTED.
- Başlangıç: 2026-10-23; güncelleme: 2026-10-24 UTC.

## Kanıt

Cwd aşağıdaki komutların tümünde F:\personelapp2; Python -B kullanıldı.
1. Test-first: yeni wrapper yokken test_project_role.py başarısız oldu
   (5 assertion failure, 1 missing-wrapper error, exit 1). İlk sandbox denemesi
   geçici fixture yazma izni nedeniyle BLOCKED; native scoped onayla tekrarlandı.
2. `python -B scripts/test_project_role.py`: 6/6 PASS, exit 0,
   2026-10-24T00:00 UTC. ROLE_PROJECT_ROOT=F:\personelapp2,
   ROLE_KIT_ROOT=C:\Users\baba\Documents\Codex\2026-10-23\task-4\adaptive-model-routing.
   Gerçek bridge subprocess/replay kullanıldı; merkezi config substitution,
   strong role, missing config/profile, unavailable no-fallback, catalog preflight.
3. Son merkezi-config replay ve diff/hash kontrolü: aşağıya sonuç eklenir.

SHA256 korunmuş kaynaklar:
- AGENTS.md: 4AE9A5F5AD38AEFF28D8EFC754B85A7FF696BAFEB98D60D71D738645EE14E7BC
- helper: A39410057FA5CD1FD0B8FEB24EBF075734A9AF897BE4B2823030A5CD3FE694DB
- test: 20C3067968045607C0E419276E34A5D952C0B319E755B648C1CA975698871CDA

## Sınırlar / kapanış

- Yeni uygulama davranışı yok; Flutter kontrolleri bu wrapper değişikliği için N/A.
  Önceki dar analizde 0 issue ve 3 test PASS vardı; yeni tam suite iddiası yok.
- Bağımsız model incelemesi NOT_RUN: bu görev ek canlı model çağrısını yasaklıyor.
  Kaynak öz denetimi bağımsız inceleme diye sunulmaz.
- Canlı model uygunluğu, kalite, token/ücret tasarrufu NOT_VERIFIED.
- Native otomatik sohbet routing yok; opt-in dış executable entegrasyonu var.
- Güvenilen kit/config yaşam döngüsü operatöre ait; taşınırsa CLI yolu güncellenir.
- Commit/merge/deploy/silme yapılmadı. Geçici offline fixture klasörleri saklandı.
## Son doğrulama — 2026-10-24T00:02 UTC

`python -B scripts/analyze_role.py --kit-root C:\Users\baba\Documents\Codex\2026-10-23\task-4\adaptive-model-routing --config C:\Users\baba\Documents\Codex\2026-10-23\task-4\adaptive-model-routing\examples\routing\lean-completion-profiles.json --role economical --goal "Inspect filename contract and existing tests only." --replay scripts/analysis-replay.json`

PASS exit 0: offline-replay, REVIEW_REQUIRED, calls_used=1 (replay attempt,
NOT a live model launch), answer=null, quality=NOT_VERIFIED; helper/tests citations.
`git diff --check`: PASS exit 0. Yeni dosyalar ayrıca whitespace ve <200 satır
kontrolünden geçti. Kullanıcının AGENTS/helper/test hashleri yukarıdakiyle aynı.
Son Git durumunda mevcut Nizam değişiklikleri korunuyor; bu göreve ait ekler
4 scripts dosyası, görev kaydı, bounded-analysis rehberi ve ledger bağlantısıdır.

SHA256:
- scripts/analyze_role.py: 2D95A5C0239F895B1CDA6C58F2249500996F3F39B20AB7CBE0FA86366B72E309
- scripts/analysis-files.json: ED002ADC8D0ABE426F0BC054D3444E226FB37901E305DFE21DA03F2B61B9E5BC
- scripts/analysis-replay.json: 05A6379C4FD471AAD144A27491E287EC4C6B3C5D70B340B076B19192871EA9EC
- scripts/test_project_role.py: FE69103228796B7BC73B667EA9F5F9F2882D5F5A98876B060A8C5A60C664EC3C
- docs/bounded-analysis.md: 35AA828C59954EB06CE79C6DC8D90AEC7462A990E9582A96D1F6EB600B8CDC57

Kullanıcı daha sonra tasarruf karşılaştırması istedi. Canlı deneme başlatılmadı;
aynı iki kaynakla strong baseline 1 + economical/strong aday 2, toplam en çok 3
çağrı önerilir. Ayrı proje corpus aktarım yetkisi, güvenilir katalog ve gerçek
usage/fiyat telemetrisi henüz tamamlanmadı. Mevcut codex_provider stdout/stderr
çıktılarını DEVNULL'a yönlendirip yalnızca result döndürüyor; bu rapor tek başına
parasal tasarruf kanıtı vermez. Bu eksikleri gizlemek için yeni framework eklenmedi.
