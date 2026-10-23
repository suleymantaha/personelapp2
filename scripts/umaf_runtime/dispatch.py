"""Görev teslim akışı ve worktree izolasyonu motoru.

`AGENTS.md` içerisindeki 'İş ver, doğru yapılsın, teslim edilsin' ilkesini
fiziksel dosya sistemi izolasyonu ve kapsam denetimiyle uygular.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

_SCRIPTS = Path(__file__).resolve().parents[1]
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

try:
    from verify_lanes import run_one
except ImportError:
    from ..verify_lanes import run_one  # type: ignore[no-redef]


def _is_dirty_status_line(line: str) -> bool:
    """Orkestrasyonun kendi geçici zarf/worktree dosyaları dışındaki kirli satırları saptar."""
    if not line.strip():
        return False
    if line.startswith("?? "):
        rel = line[3:].strip().strip('"').replace("\\", "/")
        if rel in {"task.json", ".umaf_task.json", ".worktrees"} or rel.startswith(".worktrees/"):
            return False
    return True


def create_worktree(root: Path, target_dir: Path) -> Path:
    """Temiz çalışma ağacından izole bir git worktree oluşturur."""
    root = Path(root).resolve()
    target_dir = Path(target_dir).resolve()

    status = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=str(root), capture_output=True, text=True, check=True,
    )
    if any(_is_dirty_status_line(line) for line in status.stdout.splitlines()):
        raise ValueError("Çalışma ağacı temiz değil; worktree açılamaz")

    target_dir.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["git", "worktree", "add", "--detach", str(target_dir), "HEAD"],
        cwd=str(root), capture_output=True, text=True, check=True,
    )
    return target_dir


def remove_worktree(root: Path, target_dir: Path) -> None:
    """Worktree'yi güvenle kaldırır ve ardında iz bırakmaz."""
    root = Path(root).resolve()
    target_dir = Path(target_dir).resolve()
    subprocess.run(
        ["git", "worktree", "remove", "--force", str(target_dir)],
        cwd=str(root), capture_output=True, text=True,
    )
    if target_dir.exists():
        shutil.rmtree(target_dir, ignore_errors=True)
    subprocess.run(["git", "worktree", "prune"], cwd=str(root), capture_output=True)


def inspect_scope(worktree_dir: Path, allowed_write_files: list[str]) -> dict[str, list[str]]:
    """Worktree'deki değişiklikleri tarar ve zarf kapsamı dışındaki taşmaları yakalar."""
    worktree_dir = Path(worktree_dir).resolve()
    allowed_set = {Path(p).as_posix() for p in allowed_write_files}

    # Değiştirilen dosyalar (tracked)
    diff = subprocess.run(
        ["git", "diff", "--name-only", "HEAD"],
        cwd=str(worktree_dir), capture_output=True, text=True, check=True,
    )
    tracked_modified = [line.strip().replace("\\", "/") for line in diff.stdout.splitlines() if line.strip()]

    # Yeni eklenen dosyalar (untracked)
    untracked = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard"],
        cwd=str(worktree_dir), capture_output=True, text=True, check=True,
    )
    untracked_files = [line.strip().replace("\\", "/") for line in untracked.stdout.splitlines() if line.strip()]

    # Zarf dosyaları muaf tutulur
    ignored = {"task.json", ".umaf_task.json"}
    all_modified = sorted(set(
        f for f in (tracked_modified + untracked_files)
        if f not in ignored and not f.startswith(".git")
    ))

    violations = sorted(f for f in all_modified if f not in allowed_set)
    return {"modified": all_modified, "violations": violations}


def apply_changes(source_root: Path, worktree_dir: Path, files: list[str]) -> list[str]:
    """İzinli değiştirilen dosyaları ana depoya güvenle aktarır."""
    source_root = Path(source_root).resolve()
    worktree_dir = Path(worktree_dir).resolve()
    applied: list[str] = []

    for rel_path in files:
        src = worktree_dir / rel_path
        dst = source_root / rel_path
        if src.is_file():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            applied.append(rel_path)
    return applied


def verify_and_finalize(
    source_root: Path,
    worktree_dir: Path,
    plan: dict[str, Any],
    *,
    lane: str = "auto",
    timeout: int = 60,
    apply: bool = False,
    keep_worktree: bool = False,
) -> dict[str, Any]:
    """Kapsam kontrolü yapar, testleri koşar ve kesin teslimat kararını verir."""
    source_root = Path(source_root).resolve()
    worktree_dir = Path(worktree_dir).resolve()
    allowed_write = plan.get("write_files", [])

    scope = inspect_scope(worktree_dir, allowed_write)
    if scope["violations"]:
        if not keep_worktree:
            remove_worktree(source_root, worktree_dir)
        return {
            "status": "REJECTED",
            "reason": f"Kapsam dışı dosya değiştirildi: {scope['violations']}",
            "scope": scope,
            "checks": [],
            "applied": False,
        }

    evidence = [run_one(chk, worktree_dir, lane, timeout) for chk in plan.get("checks", [])]
    any_failed = any(c["status"] == "FAIL" for c in evidence)
    all_not_run = bool(evidence) and all(c["status"] == "NOT_RUN" for c in evidence)

    if any_failed or all_not_run or not evidence:
        if not keep_worktree:
            remove_worktree(source_root, worktree_dir)
        return {
            "status": "REJECTED",
            "reason": "Kontroller başarısız veya hiç koşulamadı",
            "scope": scope,
            "checks": evidence,
            "applied": False,
        }

    applied_files: list[str] = []
    if apply:
        applied_files = apply_changes(source_root, worktree_dir, scope["modified"])
        status = "ACCEPTED"
        reason = "Kontroller geçti ve değişiklikler uygulandı"
    else:
        status = "VERIFIED"
        reason = "Kontroller geçti (uygulama istenmedi)"

    if not keep_worktree:
        remove_worktree(source_root, worktree_dir)

    return {
        "status": status,
        "reason": reason,
        "scope": scope,
        "checks": evidence,
        "applied": apply,
        "applied_files": applied_files,
    }
