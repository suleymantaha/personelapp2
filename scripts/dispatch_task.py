#!/usr/bin/env python3
"""Görev teslim ve worktree orkestrasyon CLI aracı.

Kullanım:
  # 1. İzole worktree aç ve zarfı yerleştir
  python scripts/dispatch_task.py create --task-file task.json [--target <dizin>]

  # 2. Adayın işini doğrula ve teslim al
  python scripts/dispatch_task.py verify --worktree <dizin> [--apply]

  # 3. Tek satırda çalıştır ve teslim et
  python scripts/dispatch_task.py run --task-file task.json --exec "python fix.py" --apply
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

_SCRIPTS = Path(__file__).resolve().parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

from umaf_runtime.checks import validate_checks  # noqa: E402
from umaf_runtime.dispatch import (  # noqa: E402
    create_worktree,
    remove_worktree,
    verify_and_finalize,
)
from umaf_runtime.paths import path_list  # noqa: E402


def _load_task(task_path: Path) -> dict:
    raw = json.loads(task_path.read_text(encoding="utf-8-sig"))
    if not isinstance(raw, dict) or "checks" not in raw:
        raise ValueError("Zarfta `checks` alanı zorunludur")
    for field in ("read_files", "write_files"):
        if field in raw:
            path_list(raw[field])
    validate_checks(raw["checks"])
    return raw


def cmd_create(args: argparse.Namespace) -> int:
    plan = _load_task(args.task_file)
    root = Path(args.root).resolve()
    wt_dir = Path(args.target or (root / ".worktrees" / f"task-{Path(args.task_file).stem}")).resolve()

    try:
        created = create_worktree(root, wt_dir)
        task_dest = created / "task.json"
        task_dest.write_text(json.dumps(plan, indent=2, ensure_ascii=False), encoding="utf-8")
        report = {
            "status": "READY",
            "worktree": str(created),
            "goal": plan.get("goal", ""),
            "write_files": plan.get("write_files", []),
        }
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return 0
    except Exception as exc:
        print(f"BLOCKED: worktree oluşturulamadı -> {exc}", file=sys.stderr)
        return 2


def cmd_verify(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    wt_dir = Path(args.worktree).resolve()
    task_file = Path(args.task_file).resolve() if args.task_file else (wt_dir / "task.json")

    if not wt_dir.is_dir():
        print(f"BLOCKED: worktree dizini bulunamadı: {wt_dir}", file=sys.stderr)
        return 2
    if not task_file.is_file():
        print(f"BLOCKED: zarf dosyası bulunamadı: {task_file}", file=sys.stderr)
        return 2

    plan = _load_task(task_file)
    report = verify_and_finalize(
        root, wt_dir, plan,
        lane=args.lane, timeout=args.timeout,
        apply=args.apply, keep_worktree=args.keep_worktree,
    )
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report["status"] in {"ACCEPTED", "VERIFIED"} else 1


def cmd_run(args: argparse.Namespace) -> int:
    plan = _load_task(args.task_file)
    root = Path(args.root).resolve()
    wt_dir = Path(args.target or (root / ".worktrees" / f"run-{Path(args.task_file).stem}")).resolve()

    try:
        created = create_worktree(root, wt_dir)
    except Exception as exc:
        print(f"BLOCKED: worktree oluşturulamadı -> {exc}", file=sys.stderr)
        return 2

    (created / "task.json").write_text(json.dumps(plan, indent=2, ensure_ascii=False), encoding="utf-8")

    # Ajan/işçi komutunu worktree içinde çalıştır
    if args.exec:
        subprocess.run(args.exec, shell=True, cwd=str(created), check=False)

    report = verify_and_finalize(
        root, created, plan,
        lane=args.lane, timeout=args.timeout,
        apply=args.apply, keep_worktree=args.keep_worktree,
    )
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report["status"] in {"ACCEPTED", "VERIFIED"} else 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="dispatch_task", description=__doc__)
    parser.add_argument("--root", default=".", help="Ana repo kökü")
    sub = parser.add_subparsers(dest="command", required=True)

    p_create = sub.add_parser("create", help="İzole worktree kurar ve zarfı yerleştirir")
    p_create.add_argument("--task-file", type=Path, required=True, help="Zarf JSON dosyası")
    p_create.add_argument("--target", type=Path, help="Özel worktree hedef dizini")

    p_verify = sub.add_parser("verify", help="Adayın işini doğrular ve teslim alır")
    p_verify.add_argument("--worktree", type=Path, required=True, help="Doğrulanacak worktree dizini")
    p_verify.add_argument("--task-file", type=Path, help="Zarf JSON (varsayılan: worktree/task.json)")
    p_verify.add_argument("--lane", choices=("auto", "sandbox", "host"), default="auto")
    p_verify.add_argument("--timeout", type=int, default=60)
    p_verify.add_argument("--apply", action="store_true", help="Geçerse ana depoya aktar")
    p_verify.add_argument("--keep-worktree", action="store_true", help="Başarısız olsa da silme")

    p_run = sub.add_parser("run", help="Worktree açar, komutu koşar, doğrular ve teslim eder")
    p_run.add_argument("--task-file", type=Path, required=True)
    p_run.add_argument("--exec", type=str, help="Worktree içinde koşulacak komut")
    p_run.add_argument("--target", type=Path)
    p_run.add_argument("--lane", choices=("auto", "sandbox", "host"), default="auto")
    p_run.add_argument("--timeout", type=int, default=60)
    p_run.add_argument("--apply", action="store_true")
    p_run.add_argument("--keep-worktree", action="store_true")

    args = parser.parse_args(argv)
    if args.command == "create":
        return cmd_create(args)
    if args.command == "verify":
        return cmd_verify(args)
    if args.command == "run":
        return cmd_run(args)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
