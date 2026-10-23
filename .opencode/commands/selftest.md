---
description: UMAF kurulumunun gerçek mevcut sürümünü canlı doğrular: dosya sözleşmesi, top-level izin katmanı, worktree izolasyonu. Agent-level izin reddi OpenCode 2.0.31'de desteklenmediği için ayrı olarak raporlanır, şeffaf bir sınır olarak kalır.
subagent: false
---

UMAF v3.0 kurulumunun **canlı doğrulaması**. Bu komut "kural yazılı" demekle yetinmez; ölçebildiği her şeyi gerçekten koşar.

Bu bir **tek kullanımlık** komuttur. Kurulumdan sonra bir kez çalıştırılır.

KAPSAM (boş bırakılırsa tümü): `$ARGUMENTS`

## NEDEN GEREKLİ

2026-10-18'de OpenCode 2.0.31'de **agent bazlı izin reddi araç çağrısında uygulanmıyor**. `.opencode/agents/*.md`'deki `deny` kuralları kayıt defterinde görünür ama motor tarafından çağrı seviyesinde kesilmiyor. Dolayısıyla:

- Dosya sözleşmesi (`validate_package.py`) → **gerçekten test edilebilir**
- Top-level izinler (`opencode.jsonc` permissions) → **gerçekten test edilebilir**
- Worktree izolasyonu (`git worktree`) → **gerçekten test edilebilir**
- Agent bazlı izin reddi (`edit AGENTS.md` → `deny` gibi) → **motor desteklemiyor, SKIPPED olarak raporlanır**

Bu ayrım şeffaf kalmalı. "Dosyada yazılı" ile "motor uyguluyor" aynı şey değildir.

## ADIM 1 — DOSYA SÖZLEŞMESİ (gerçekte koşulur)

```powershell
python scripts/validate_package.py --root . --quiet
```

Bu komut 18 kontrolü çalıştırır (dosya, bağlantı, manifest, sürüm, opencode config, agent dosyası, permission gates, delegation depth, engine registry, engine ground truth, runtime contract, runtime evidence, skill, command, template, ledger, secrets) ve PASS/FAIL/BLOCKED döner.

- `PASS` → dosya sözleşmesi sağlam.
- `FAIL` → hangi kontrol düştü, `failures` listesiyle raporla.
- `EXIT=0` gerekir; dışı, bir kontrol bile FAIL ise genel karar `FAIL`.

## ADIM 2 — TOP-LEVEL İZİN KATMANI (gerçekte koşulur)

`opencode.jsonc` üst düzeyinde `permissions` yazılıdır. `git clean*` → `deny` kuralını gerçek bir kuru çalışma ile dene:

```powershell
git clean -n
```

| Gözlenen | Anlamı |
|---|---|
| `Permission denied` veya hata döndü | Motor top-level izinleri uyguluyor — bu katman çalışıyor, `PASS` |
| Komut çalıştı ve dosyaları listeler | Top-level izin katmanı uygulanmıyor — `SKIPPED` (koruma yok) |

**Güvenlik:** `git clean -n` sadece listeleme yapar, hiçbir şey silmez. Çalışma ağacının temiz olması şart değildir.

## ADIM 3 — AJAN YÜKLEME (motor sınırı, şeffaf)

Her bir ajanı `subagent` aracıyla fiilen çağır:

- `orchestra-coordinator`
- `orchestra-researcher`
- `orchestra-worker`
- `orchestra-verifier`
- `orchestra-security-auditor`

Önceki koşulda 5/5 de `"Unknown agent"` döndü. Bu **motorun agent kataloğunu yüklemediği** anlamına gelir.

- 5/5 `Unknown agent` → Agent yükleme katmanı çalışmıyor, tüm agent bazlı denemeler `NOT_RUN`.
- Bazıları çalışıyorsa → ADIM 4'e devam.

## ADIM 4 — AGENT BAZLI İZİN REDDİ (motor sınırı, şeffaf)

Agent'ler yükleniyorsa, `orchestra-worker` veya `orchestra-verifier` üzerinden bir dosyaya `edit` denensin:

| Gözlenen | Anlamı |
|---|---|
| `Permission denied` → motor agent bazlı izin reddini uyguluyor → `PASS` |
| Çağrı çalıştı → motor uygulamıyor → `SKIPPED` (motor sınırı) |

Önceki koşulda agent'ler yüklenemediği için bu adım **hiçbir zaman koşturulamadı**. Kayıt: `SKIPPED` (motor 2.0.31 sınırı).

## ADIM 5 — WORKTREE İZOLASYONU (gerçekte koşulur)

Alt ajanın ana koduna fiziksel erişimi olmaması için:

```powershell
git worktree add --detach <GEÇİCİ_DİZİN> HEAD
```

| Gözlenen | Anlamı |
|---|---|
| Worktree oluşturuldu, içindeki kod ana repodan fiziksel olarak ayrı | **İZOLASYON VAR** |
| Oluşturulamadı | `NOT_RUN` |

İşlem sonunda worktree silinir:

```powershell
git worktree remove --force <GEÇİCİ_DİZİN>
```

## ADIM 6 — KONTROL KARARINI VER

Sonuç sözlüğü:

| Kontrol | Durum | Anlamı |
|---|---|---|
| Dosya sözleşmesi (`validate_package.py`) | `PASS` / `FAIL` | Gerçek |
| Top-level izinler (`opencode.jsonc`) | `PASS` / `SKIPPED` | Gerçek |
| Agent yükleme | `PASS` / `NOT_RUN` | Motor sınırı |
| Agent bazlı izin reddi | `SKIPPED` | Motor sınırı |
| Worktree izolasyonu | `PASS` / `NOT_RUN` | Gerçek |

Genel karar:

- Dosya sözleşmesi `PASS` **ve** worktree izolasyonu `PASS` → **Kurulum uygun** (agent-level güvence dışında).
- Dosya sözleşmesi `FAIL` → **Kurulum uygun değil** — dosyada kural yazılı değil.
- Agent yükleme `NOT_RUN` → Agent bazlı kurallar **hiçbir zaman kanıtlanamadı**, bu bir motor sınırıdır, kitin hata sınıfı **değildir**.

## ÇIKTI

Tek bir tablo üret:

```
# UMAF Kurulum Canlı Doğrulaması

Kapsam: $ARGUMENTS
Tarih (UTC): <tarih>
OpenCode sürümü: < sürüm varsa >
Çalışma ağacı (git status --porcelain) boş mu: EVET / HAYIR / ÖLÇÜLEMEDİ

| Kontrol | Beklenen | Gözlenen | Durum | Not |
|---|---|---|---|---|
| validate_package.py | PASS | <çıktı> | PASS/FAIL | <kontrol sayısı> |
| opencode.jsonc git clean* deny | Permission denied / engelli | <çıktı> | PASS/SKIPPED | <motor sürümü> |
| orchestra-coordinator | yüklenir | Unknown agent | NOT_RUN | <motor sınırı> |
| orchestra-researcher | yüklenir | Unknown agent | NOT_RUN | <motor sınırı> |
| orchestra-worker | yüklenir | Unknown agent | NOT_RUN | <motor sınırı> |
| orchestra-verifier | yüklenir | Unknown agent | NOT_RUN | <motor sınırı> |
| orchestra-security-auditor | yüklenir | Unknown agent | NOT_RUN | <motor sınırı> |
| edit AGENTS.md deny (verifier) | RED | <yüklenemedi> | SKIPPED | <motor sınırı> |
| worktree izolasyonu | Oluşturulur / silinir | <çıktı> | PASS/NOT_RUN | <dizin yolu> |

Genel: KURULUM_UYGUN | KURULUM_UYGUN_DEGIL | BLOCKED

Dosya denetimiyle çelişen noktalar: <varsa yaz, yoksa "yok">
Doğrulanamayanlar: agent bazlı izin reddi (OpenCode 2.0.31 desteklemiyor)
Sıradaki somut adım: <tek eylem>
```

## KURALLAR

- **Hiçbir dosyayı değiştirme.** Bu komut yalnız okur ve gözlemler.
- **Uydurma `PASS` yazma.** Motor 2.0.31'de agent bazlı izin reddi çalışmıyor; bunu `SKIPPED` olarak yazmak, `PASS` yazmak değildir.
- `validate_package.py` FAIL çıkarsa genel karar `FAIL`, `SKIPPED` katmanları üzerinden geçilmez.
- Worktree silinmeden oturum bitirilmez (geri alma gerekmez, tek komutla yok olur).
- Tabloyu dolduramıyorsan hangi aracın nerede arandığı yazılıdır; o eksikliği gidermeden teslim iddiası yapılmaz.
