"""Proje adaptasyonu (adopt): kit dosyalarını ve kurallarını hedef depoya kurar.

Mevcut hedef mimariyi, talimatları ve yapılandırmaları ezmeden (merge_never_clobber)
cerrahi birleştirme ve dosya kopyalama yürütür.
"""

from __future__ import annotations

import json
import re
import shutil
from pathlib import Path
from typing import Any

START_MARKER = "<!-- universal-agent-kit:start -->"
END_MARKER = "<!-- universal-agent-kit:end -->"

ORCHESTRA_BLOCK = f"""{START_MARKER}
# Universal Agent Kit 3.0 — UMAF Active Orchestra

Bu blok bu projede ortak \u00e7al\u0131\u015fma ve orkestrasyon disiplinini tan\u0131mlar.
Mevcut mimari kurallar\u0131, DI ve state yap\u0131s\u0131 ile birlikte harmanlanarak uygulan\u0131r.

## Hibrit Ak\u0131ll\u0131 Orkestrasyon Karar Matrisi
- **Tier 1 (`native_fast`):** Tek dosya, <30 dk, k\u00f6k nedeni a\u00e7\u0131k d\u00fczeltmelerde do\u011frudan y\u00fcr\u00fctme.
- **Tier 2 (`orchestrated_research_worker_verifier`):** \u00c7oklu dosya, yeni \u00f6zellik veya ba\u011f\u0131ms\u0131z i\u015flerde
  Orkestra \u015eefi olarak 5-rol ajan ordusunu (`researcher` -> `worker` -> `verifier`) g\u00f6revlendir.
- **Tier 3 (`full_army_with_security_audit`):** Yetki, g\u00fcvenlik, \u00f6deme veya canl\u0131 yay\u0131n i\u015flerinde
  `orchestra-security-auditor` denetimini zorunlu ekle.

## Hata Ba\u011f\u0131\u015f\u0131kl\u0131k Muhaf\u0131zlar\u0131
- **`root_cause_before_patch`:** Ham veri ve \u00e7a\u011fr\u0131 zincirini do\u011frulamadan tahmini yama yazma.
- **`merge_never_clobber_agents_md`:** Mevcut mimariyi ve kurallar\u0131 ezme; orkestra kurallar\u0131yla harmanla.
- **`single_writer_file_ownership`:** Ayn\u0131 dosyaya iki yaz\u0131c\u0131 atama; 200 sat\u0131r\u0131 a\u015fan dosya \u00fcretme.
- **`zero_qa_runtime_verification`:** Kullan\u0131c\u0131 QA eleman\u0131 de\u011fildir; ger\u00e7ek kontrolleri \u00f6l\u00e7.
{END_MARKER}"""

AGENTS = (
    "orchestra-coordinator.md",
    "orchestra-researcher.md",
    "orchestra-worker.md",
    "orchestra-verifier.md",
    "orchestra-security-auditor.md",
)
COMMANDS = ("tier.md", "verify.md", "selftest.md", "adopt.md")


def merge_agents_markdown(existing: str | None) -> str:
    """Mevcut AGENTS.md içeriğini koruyarak orkestra bloğunu cerrahi olarak birleştirir."""
    if not existing or not existing.strip():
        return f"# Proje Mimari ve Ajan Kurallar\u0131\n\n{ORCHESTRA_BLOCK}\n"

    pattern = re.compile(
        rf"{re.escape(START_MARKER)}.*?{re.escape(END_MARKER)}",
        re.DOTALL,
    )
    if pattern.search(existing):
        return pattern.sub(ORCHESTRA_BLOCK, existing)
    clean_existing = existing.rstrip()
    return f"{clean_existing}\n\n{ORCHESTRA_BLOCK}\n"


def _copy_asset(src: Path, dst: Path, dry_run: bool, actions: dict[str, list[str]]) -> None:
    existed = dst.is_file()
    if existed and dst.read_bytes() == src.read_bytes():
        actions["skipped"].append(str(dst))
        return
    if not dry_run:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    actions["updated" if existed else "created"].append(str(dst))


def adopt_project(
    kit_root: Path,
    target_root: Path,
    set_default_agent: bool = True,
    include_runtime: bool = False,
    dry_run: bool = False,
) -> dict[str, Any]:
    """Hedef projeye UMAF kit bileşenlerini kurar veya günceller."""
    kit_root = kit_root.resolve()
    target_root = target_root.resolve()
    actions: dict[str, list[str]] = {"created": [], "updated": [], "skipped": []}

    # 1. AGENTS.md harmanlama
    target_agents = target_root / "AGENTS.md"
    existing_content = target_agents.read_text("utf-8") if target_agents.is_file() else None
    merged_content = merge_agents_markdown(existing_content)
    if existing_content != merged_content:
        if not dry_run:
            target_agents.parent.mkdir(parents=True, exist_ok=True)
            target_agents.write_text(merged_content, "utf-8")
        action_key = "updated" if existing_content is not None else "created"
        actions[action_key].append(str(target_agents))
    else:
        actions["skipped"].append(str(target_agents))

    # 2. .opencode ajanları ve komutları
    for agent in AGENTS:
        _copy_asset(kit_root / ".opencode/agents" / agent, target_root / ".opencode/agents" / agent, dry_run, actions)
    for cmd in COMMANDS:
        _copy_asset(kit_root / ".opencode/commands" / cmd, target_root / ".opencode/commands" / cmd, dry_run, actions)
    _copy_asset(
        kit_root / ".opencode/skills/umaf/SKILL.md",
        target_root / ".opencode/skills/umaf/SKILL.md",
        dry_run,
        actions,
    )

    # 3. opencode.jsonc
    cfg_target = target_root / ".opencode/opencode.jsonc"
    cfg_src = kit_root / ".opencode/opencode.jsonc"
    if not cfg_target.is_file():
        cfg_content = cfg_src.read_text("utf-8")
        if not set_default_agent:
            cfg_content = re.sub(r'(\s*)"default_agent":\s*"[^"]*",?', "", cfg_content)
        if not dry_run:
            cfg_target.parent.mkdir(parents=True, exist_ok=True)
            cfg_target.write_text(cfg_content, "utf-8")
        actions["created"].append(str(cfg_target))
    else:
        actions["skipped"].append(str(cfg_target))

    # 4. İskelet dosyaları (varsa asla ezme)
    checks_file = target_root / "CHECKS.md"
    if not checks_file.is_file():
        if not dry_run:
            checks_file.write_text("# Do\u011frulama Kontrolleri (CHECKS.md)\n\n| Kontrol | Komut | CWD | Beklenen | Durum |\n|---|---|---|---|---|\n| Testler | `echo 'test'` | . | exit 0 | NOT_RUN |\n", "utf-8")
        actions["created"].append(str(checks_file))
    project_file = target_root / "PROJECT.md"
    if not project_file.is_file():
        if not dry_run:
            project_file.write_text(f"# Proje Tan\u0131m\u0131 (PROJECT.md)\n\n## Hedef ve Kapsam\n- Proje: {target_root.name}\n- Durum: Haz\u0131rlan\u0131yor\n", "utf-8")
        actions["created"].append(str(project_file))

    # 5. İsteğe bağlı runtime kopyalama
    if include_runtime:
        _copy_asset(kit_root / "scripts/verify_candidate.py", target_root / "scripts/verify_candidate.py", dry_run, actions)
        _copy_asset(kit_root / "scripts/verify_lanes.py", target_root / "scripts/verify_lanes.py", dry_run, actions)
        _copy_asset(kit_root / "scripts/dispatch_task.py", target_root / "scripts/dispatch_task.py", dry_run, actions)
        runtime_pkg = kit_root / "scripts/umaf_runtime"
        for py_file in runtime_pkg.glob("*.py"):
            _copy_asset(py_file, target_root / "scripts/umaf_runtime" / py_file.name, dry_run, actions)

    return {"status": "SUCCESS", "dry_run": dry_run, "target": str(target_root), "actions": actions}
