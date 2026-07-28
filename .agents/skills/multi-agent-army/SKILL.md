---
name: multi-agent-army
description: "Create and orchestrate a hierarchical multi-agent army with task delegation, work isolation, quality gates, and kanban tracking. Optimized for Flutter/Dart projects. Agents at different hierarchy levels (orchestrator → team leads → workers) pass tasks down without sharing code directly."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [multi-agent, orchestration, delegation, hierarchical, work-isolation, kanban, quality-gates, flutter, dart]
    category: autonomous-ai-agents
    related_skills: [flutter-apply-architecture-best-practices, dart-add-unit-test, flutter-add-widget-test, dart-fix-runtime-errors]
---

# Multi-Agent Army — Flutter/Dart Hierarchical Agent Orchestration

Bu skill **Jandarma Görev Takip Uygulaması** (Flutter + Dart + Riverpod + Drift) projesine
özel olarak yapılandırılmıştır.

Build a **multi-level agent army** where:
- **Orchestrator** (depth 0) decomposes epics → assigns to Team Leads
- **Team Leads** (depth 1) break down features → assign to Workers
- **Workers** (depth 2) execute isolated tasks in separate workdirs
- **No code sharing between agents** — each works in isolation, results flow up through structured handoffs

## Project Context

```
personelapp2/                      ← Flutter project root
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── database/              ← Drift DB (AppDatabase)
│   │   ├── navigation/            ← go_router (app_router.dart)
│   │   ├── providers/             ← Riverpod providers
│   │   ├── services/              ← SessionStorage, etc.
│   │   ├── theme/                 ← AppTheme, responsive_layout.dart
│   │   └── utils/
│   └── features/
│       ├── auth/                  ← Login screen
│       ├── dashboard/             ← Main dashboard
│       ├── personnel/             ← Personel & Tim yönetimi
│       ├── activity/              ← Faaliyet çizelgesi
│       └── matrix/                ← Aylık matris
├── test/
│   └── unit/                      ← Unit tests (dart test)
├── .agents/
│   └── skills/
│       ├── multi-agent-army/      ← Bu skill
│       └── ...                    ← Diğer Dart/Flutter skill'leri
└── pubspec.yaml                   ← Dart SDK ^3.12.2
```

**Tech Stack:** Flutter · Dart · Riverpod · Drift (SQLite) · go_router · intl · pdf · printing

## Quick Start

```python
# 1. Define your army structure for a Flutter feature
army = {
    "orchestrator": {
        "role": "orchestrator",
        "goal": "Implement 'Nöbet Listesi' (duty roster) feature with UI, state, DB, and tests",
        "team_leads": ["ui", "state_data", "tests"]
    },
    "team_leads": {
        "ui": {
            "role": "team_lead",
            "domain": "Flutter UI (Widgets & Screens)",
            "workers": ["coder-screen", "coder-widgets", "reviewer-ui"]
        },
        "state_data": {
            "role": "team_lead",
            "domain": "Riverpod Providers & Drift DAO",
            "workers": ["coder-provider", "coder-dao", "reviewer-arch"]
        },
        "tests": {
            "role": "team_lead",
            "domain": "Widget & Unit Tests",
            "workers": ["tester-widget", "tester-unit", "documenter"]
        }
    }
}

# 2. Spawn orchestrator (depth 0)
orchestrator_id = delegate_task(
    goal="Orchestrate Flutter feature build. Decompose to team leads, track progress, merge results.",
    context=build_orchestrator_context(army),
    role="orchestrator"
)
```

## Core Principles

| Principle | Implementation |
|-----------|----------------|
| **Hierarchical delegation** | `delegate_task` with `role=orchestrator` → `team_lead` → `leaf` |
| **Work isolation** | Each agent gets unique `workdir` (git worktree / temp dir) |
| **No direct code sharing** | Agents communicate ONLY via structured task results |
| **Flutter quality gates** | `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed` |
| **Real-time visibility** | Live transcripts at `cache/delegation/live/<id>/task_<n>.log` |
| **Durable task queue** | JSONL files in `tasks/<level>/<name>/queue.jsonl` |

## Agent Roles & Responsibilities

### Orchestrator (Depth 0)
- Owns the Flutter feature epic/roadmap
- Decomposes into team-level tasks (UI, State/Data, Tests, Docs)
- Tracks progress across teams
- Merges worktrees, runs `flutter analyze` + `flutter test` integration
- **Tools**: `delegate_task`, `dart_mcp_server/analyze_files`, `dart_mcp_server/hot_reload`, `read_file`, `write_file`, terminal

### Team Lead (Depth 1)
- Owns a domain (UI widgets, Riverpod providers, Drift DAOs, tests, etc.)
- Breaks features into worker-sized tasks
- Assigns to workers, monitors via live transcripts
- Runs quality gates before accepting work: `flutter analyze`, `flutter test`
- **Tools**: Same as orchestrator + `dart_mcp_server/lsp`, `dart_mcp_server/widget_inspector`

### Worker (Depth 2 — Leaf)
- Executes ONE well-defined Flutter/Dart task
- Works in isolated `workdir`
- Runs quality gates for their role
- Returns structured result (files changed, tests, notes)
- **Tools**: Role-specific subset (coder: Read/Write/Edit/terminal/dart_mcp_server; tester: Read/terminal/dart_mcp_server)

## Quality Gates (Flutter/Dart)

```bash
# Per role — Workers MUST pass before marking task `done`

# CODER gates
flutter analyze                          # Static analysis (0 warnings)
dart format --set-exit-if-changed .      # Format check
flutter test                             # All tests pass
dart fix --dry-run                       # No auto-fixable issues

# TESTER gates
flutter test --coverage                  # Coverage report
flutter test test/unit/                  # Unit tests pass
flutter test test/widget/                # Widget tests pass

# REVIEWER gates
flutter analyze --fatal-warnings         # No warnings allowed
dart analyze --fatal-warnings

# REFACTORER gates
flutter test                             # Tests pass before AND after
dart format --set-exit-if-changed .      # Formatting preserved

# DOCUMENTER gates
dart doc --dry-run                       # Doc generation check
```

```python
ROLE_GATES = {
    "coder":      ["flutter analyze", "dart format --set-exit-if-changed .", "flutter test"],
    "tester":     ["flutter test --coverage", "flutter test test/widget/"],
    "reviewer":   ["flutter analyze --fatal-warnings"],
    "refactorer": ["flutter test", "dart format --set-exit-if-changed ."],
    "documenter": ["dart doc --dry-run"]
}
```

Worker MUST pass gates before marking task `done`. Team Lead verifies.

## Isolation Strategy: Git Worktrees (Windows Compatible)

**Critical:** Never share a working directory between agents.

```powershell
# Before spawning team leads, orchestrator creates worktrees (Windows PowerShell)
cd C:\Users\baba\personelapp2

git worktree add ..\worktree-ui main
git worktree add ..\worktree-state main
git worktree add ..\worktree-tests main

# Delegate with workdir (use forward slashes in context)
delegate_task(tasks=[{
    "goal": "Build Nöbet Listesi screen widgets",
    "context": "...",
    "role": "team_lead",
    "workdir": "C:/Users/baba/worktree-ui"
}])
```

Each team lead then creates sub-worktrees for their workers.

> **Windows Note:** Use `%TEMP%\agent-worker-N` for ephemeral temp dirs instead of `/tmp/`.

## Available Dart/Flutter Skills

Agents can use these `.agents/skills/` entries:

| Skill | When to Use |
|-------|-------------|
| `dart-add-unit-test` | Writing unit tests for functions/classes |
| `dart-fix-runtime-errors` | Fixing runtime errors via MCP |
| `dart-run-static-analysis` | Running `dart analyze` + auto-fix |
| `flutter-add-widget-test` | Widget testing with WidgetTester |
| `flutter-apply-architecture-best-practices` | Layered architecture (UI/Logic/Data) |
| `flutter-build-responsive-layout` | LayoutBuilder, MediaQuery |
| `flutter-fix-layout-issues` | RenderFlex overflow, unbounded height |
| `flutter-setup-declarative-routing` | go_router configuration |
| `dart-use-pattern-matching` | Switch expressions, pattern matching |
| `dart-use-primary-constructors` | Primary constructor syntax |

## Live Monitoring

```powershell
# Watch any worker in real-time (Windows)
Get-Content -Wait cache\delegation\live\<delegation_id>\task_1.log

# Cross-platform (via dart_mcp_server)
# Use dart_mcp_server/get_runtime_errors to monitor active errors
```

## File Structure

```
personelapp2/
├── tasks/
│   ├── orchestrator/queue.jsonl, active.jsonl, done.jsonl
│   ├── team-lead-ui/queue.jsonl, active.jsonl, done.jsonl
│   ├── team-lead-state/...
│   └── team-lead-tests/...
├── worktrees/           (created outside project root on Windows)
│   ├── C:\Users\baba\worktree-ui\
│   ├── C:\Users\baba\worktree-state\
│   └── C:\Users\baba\worktree-tests\
└── cache/delegation/live/<delegation_id>/
    ├── task_1.log (worker 1)
    ├── task_2.log (worker 2)
    └── ...
```

## Prerequisites

- Git repository (for worktrees) — ✅ already initialized
- `delegation.max_spawn_depth >= 2`
- `delegation.max_concurrent_children` set to 5+ for parallel workers
- Flutter SDK installed and on PATH
- Dart MCP server available (`dart_mcp_server`)
- Hermes v0.19.0 — ✅ kurulu (`C:\Users\baba\AppData\Local\hermes\`)
- NVIDIA NIM API — ✅ `nvidia/nemotron-3-ultra-550b-a55b`

---

## 🔗 Hibrit İş Akışı: Hermes + Antigravity

Bu projede **iki katmanlı** bir agent sistemi kullanılır:

```
SEN
 │
 ▼
Antigravity (Bu agent)          ← Koordinatör, implementatör
 │   "Büyük analiz/dağıtım görevi"
 ▼
hermes-bridge.ps1               ← Köprü scripti
 │   hermes chat -q "..." -m nemotron-550b --provider nvidia -Q
 ▼
Hermes + sub-ajanlar            ← Paralel analiz / özet üretimi
 │   delegate_task ile worker'lar spawner
 ▼
JSON Özet (hermes_output.json)
 │
 ▼
Antigravity                     ← Özeti okur, kodu yazar, flutter analyze + test çalıştırır
```

### Ne Zaman Hermes Kullanılır?

| Görev Tipi | Kim Yapar |
|-----------|-----------|
| Tüm `lib/` taraması | **Hermes** (paralel, 550B analiz) |
| Büyük feature decomposition | **Hermes** (orchestrator → team leads) |
| Güvenlik / kod kalite taraması | **Hermes** |
| Refactor planı çıkarma | **Hermes** (özet → Antigravity uygular) |
| Tek dosya düzenleme | **Antigravity** (direkt) |
| Bug fix, test ekleme | **Antigravity** (direkt) |
| `flutter analyze` düzeltme | **Antigravity** (direkt) |

### Kullanım — Hermes Bridge

```powershell
# Proje kökünden çalıştır:
.\.agents\skills\multi-agent-army\hermes-bridge.ps1 `
    -Task "lib/features/personnel/ klasörünü analiz et, mimari sorunları listele" `
    -OutputFile "hermes_output.json"

# Sonra Antigravity JSON'u okur ve implementasyonu yapar
```

### Çıktı Formatı (hermes_output.json)
```json
{
  "hermes_meta": {
    "model": "nvidia/nemotron-3-ultra-550b-a55b",
    "elapsed_s": 12.4,
    "task": "..."
  },
  "result": {
    "status": "completed",
    "summary": "2-3 cümle özet",
    "findings": ["bulgu 1", "bulgu 2"],
    "files_to_change": ["lib/features/personnel/presentation/..."],
    "recommended_actions": [
      {"priority": "high", "action": "yapılacak iş", "file": "dosya"}
    ],
    "quality_gates": {"flutter_analyze_ok": true, "tests_pass": true},
    "estimated_complexity": "medium"
  }
}
```

## Karar Matrisi: Ne Zaman Devreye Girer?

Bu klasor **varsayilan giris noktasi degildir**. `multi-agent-army`, sadece
is parcaciklara ayrildiginda gercek fayda uretiyorsa devreye alinmalidir.

### Varsayilan Politika

- **Varsayilan:** Antigravity dogrudan calisir
- **Esik asilinca:** `multi-agent-army` devreye girer
- **Tek dosya / kucuk fix / hizli lint temizligi:** dogrudan calis
- **Bagimsiz alt islere bolunebilen buyuk is:** orkestrasyon kullan

### Hizli Karar Tablosu

| Gorev tipi | Tercih edilen yol | Neden |
|-----------|-------------------|------|
| 1-3 dosyada bug fix | **Direkt** | Orkestrasyon maliyeti gereksiz |
| Lint / type / format duzeltmesi | **Direkt** | Hizli geri bildirim gerekir |
| Kucuk UI duzeltmesi | **Direkt** | Tek akis yeterli |
| Tek test ekleme veya duzeltme | **Direkt** | Paralelizasyon kazanci dusuk |
| Buyuk feature gelistirme | **Multi-agent army** | UI / state / test ayristirilabilir |
| Geniş kod taramasi | **Multi-agent army** | Hermes ozet ve paralel analiz faydali |
| Mimari refactor plani | **Multi-agent army** | Alanlara bolunup raporlanabilir |
| Birden cok modulu etkileyen is | **Multi-agent army** | Koordinasyon ve kalite kapisi gerekir |

### Pratik Esik Kurallari

Asagidaki kosullardan **en az biri** saglaniyorsa `multi-agent-army`
kullanimi dusunulmelidir:

1. Is en az **2-3 bagimsiz workstream**'e ayrilabiliyorsa
2. UI, data/state ve test katmanlari **paralel** ilerleyebiliyorsa
3. Gorev **4+ dosya / 2+ modulu** anlamli sekilde etkiliyorsa
4. Once **Hermes analizi / ozet cikarma** fayda saglayacaksa
5. Sonucta team-level kalite kapisi ve aggregation gerekiyorsa

Asagidaki durumlarda ise **dogrudan uygulama** tercih edilir:

1. Hedef net ve cerrahi ise
2. Degisiklik tek akisla rahatca tamamlanabiliyorsa
3. Ana deger hiz ve izlenebilirlik ise
4. Ayni dosyaya birden fazla ajanin dokunmasi gereksiz risk yaratacaksa

### Calisma Politikasi

1. **Kucuk is:** Antigravity dogrudan uygular, `dart analyze` / `flutter analyze`
   ve gerekli testlerle kapatir.
2. **Orta is:** Gerekirse Hermes Bridge ile once analiz alinir, ama implementasyon
   yine tek ajan tarafinda tamamlanabilir.
3. **Buyuk is:** Orchestrator -> Team Lead -> Worker hiyerarsisi kullanilir.

### Bu Repo Icin Ozet

- **Gunluk varsayilan:** Direkt calis
- **Istisna:** Buyuk feature, kapsamli refactor, genis tarama, paralel alt isler
- **Amaç:** Kucuk islerde hiz kaybetmemek, buyuk islerde ise kontrolu kaybetmemek

## Zorunlu Guncelleme Disiplini

Bu klasor sus amacli tutulmaz. Bu klasordeki bilgi mimarisi, yapilan isin aktif
rehberi sayilir.

Bir degisiklik yapildiginda, etkilenen yerler burada da gozden gecirilmelidir:

- `SKILL.md`
- `orchestrator.md`
- `references/orchestrator.md`
- `flutter-project-context.md`
- `leaf-workers.md`
- `task-queue.md`

### Zorunlu Kural

Kodda, is akisinda, agent rollerinde, kalite kapilarinda veya repo kullanma
sekillerinde degisiklik varsa; bu klasorde etkilenmis belge(ler) ayni is
kapsaminda guncellenmelidir.

### Minimum Beklenti

1. Kod degisikligi yap
2. Ilgili kalite kapilarini calistir
3. Bu klasorde etkilenmis belgeleri guncelle
4. Son durumda `git` ile degisiklik yuzeyini kontrol et

## Git Calisma Kurali

Bu repo icin `git` kontrolleri kucuk/buyuk is ayrimi olmadan isletilmelidir.

### Minimum Git Rutini

Her anlamli degisiklik turunda en az su kontrol uygulanir:

1. Calisma sonunda `git status`
2. Gerekliyse `git diff -- <ilgili_dosyalar>`
3. Kullanici acikca istemedikce otomatik commit yok

### Neden

- Degisiklik yuzeyi gorunsun
- Dokumantasyon/kod birlikte guncellendi mi anlasilsin
- Yan etkiler erken fark edilsin
- Multi-agent veya direkt akis fark etmeksizin ayni disiplin korunsun

## Anti-Patterns to Avoid

❌ Multiple agents editing same `.dart` file simultaneously
❌ Workers committing to main branch directly
❌ Vague goals ("fix the UI") — be surgical ("Fix overflow in `_MenuCard` widget on tablet viewport")
❌ Skipping `flutter analyze` before marking done
❌ Workers making architecture decisions (Riverpod vs Bloc) — escalate up
❌ Workers running `flutter pub add` without Team Lead approval
❌ Using `print()` for logging — use `debugPrint()` or a logger

## Example: Deploy This Army Now

```powershell
# 1. Ensure config allows depth 2
hermes config set delegation.max_spawn_depth 2
hermes config set delegation.max_concurrent_children 5

# 2. Create worktrees (Windows)
cd C:\Users\baba\personelapp2
git worktree add ..\wt-ui main
git worktree add ..\wt-state main
git worktree add ..\wt-tests main

# 3. Spawn orchestrator
hermes chat -q "You are the ORCHESTRATOR for personelapp2 (Flutter/Dart).
  Goal: Implement [YOUR FEATURE] following .agents/skills/multi-agent-army/flutter-project-context.md.
  Team leads: ui (Widgets/Screens), state_data (Riverpod/Drift), tests (flutter_test).
  Use delegate_task to spawn team leads with workdirs pointing to wt-*.
  Quality gates: flutter analyze + flutter test must pass.
  Track progress in tasks/orchestrator/*.jsonl.
  Report final summary when all teams done."
```

---

## Cost & Token Optimization (Auto-Applied)

The multi-agent army automatically applies 5 optimization strategies that reduce API costs by **60-95%** while maintaining quality:

### 1. Dynamic Model Routing (Per Task)
Every delegated task is analyzed and routed to the optimal model tier:
| Tier | Model | Cost/1M tokens | Use Cases |
|------|-------|----------------|-----------|
| **LOCAL** | Ollama/Llama.cpp | **FREE** | File ops, `dart format`, `flutter pub get`, git |
| **CHEAP** | Haiku/GPT-4o-mini | $0.25 | Test writing, widget tests, doc updates |
| **STANDARD** | Sonnet/GPT-4o | $3-5 | Widget implementation, Riverpod providers, Drift DAOs |
| **PREMIUM** | Opus/o1 | $15-60 | Architecture decisions, security, complex state |

**Typical distribution**: 40% LOCAL, 30% CHEAP, 20% STANDARD, 10% PREMIUM

### 2. Per-Role Thinking Budgets
Hard caps on reasoning tokens prevent overthinking:
| Role | Thinking Budget |
|------|----------------|
| Flutter Coder | 2000 tokens |
| Flutter Tester | 500 tokens |
| Flutter Reviewer | 3000 tokens |
| Flutter Refactorer | 1500 tokens |
| Documenter | 300 tokens |
| Team Lead | 2500 tokens |
| Orchestrator | 4000 tokens |

### 3. Context Compression
- Worker outputs auto-compressed to structured JSON summaries (max 3000 chars)
- Sliding window history (last 10 messages) for long conversations
- Full history preserved in live transcripts only

### 4. Structured Inter-Agent Communication
- Workers return strict JSON per `WORKER_RESULT_SCHEMA`
- Team Leads report via `TEAM_LEAD_REPORT_SCHEMA`
- No free-form text between agents — reduces output tokens **40%**

### 5. Tool Output Caching
- `read_file`, `dart_mcp_server/analyze_files`, terminal results cached 1 hour
- Cache hits tracked and reported in final stats (~30% hit rate)

### Cost Tracking in Final Report
```json
{
  "cost_usd": 0.42,
  "total_tokens": 185000,
  "api_calls": 47,
  "cache_hit_rate": 0.35,
  "model_tier_distribution": {"local": 12, "cheap": 8, "standard": 5, "premium": 2}
}
```

**Expected savings**: 60-95% cost reduction vs. all-Sonnet baseline.

---

**See `leaf-workers.md` for worker role definitions, `task-queue.md` for the full queue/kanban system, and `flutter-project-context.md` for full project context.**
