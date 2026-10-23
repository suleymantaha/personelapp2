#!/usr/bin/env python3
"""Aday (candidate) doğrulama: gerçek komutları koş, gözleneni raporla.

Bu araç MODEL ÇAĞIRMAZ. Doğruluğun garantisi sağlayıcıya bağlı değildir.

KATMANLAR
--------
* `verify_lanes.py` — komutu HANGI ŞERİTTE koşacağımızı ve kanıt kaydını üretir.
* bu dosya — zarfın geçerli olup olmadığına ve toplam karara karar verir.

ZARF
----
    {"goal": "...",
     "read_files": [...], "write_files": [...],
     "checks": [["dart", "analyze", "lib"]]}

`checks` en az bir, en çok 20 gerçek komut olmalıdır; kabuk sarmalayıcısı
(`sh -c`, `cmd /c`, `powershell`) reddedilir. `read_files`/`write_files` glob
DEĞER, som göreli yol olmalıdır.

KARAR
-----
| Durum | Anlam | Exit |
|---|---|---|
| `PASS` | ölçülebilen kontrollerin hepsi geçti | 0 |
| `FAIL` | en az bir kontrol koştu ve sıfır dışı döndü | 1 |
| `NOT_RUN` | hiçbir kontrol ölçülemedi (araç yok, süre aştı) | 2 |
| `BLOCKED` | zarf geçersiz; hiçbir komut koşmadı (stderr) | 2 |

`FAIL` ile `NOT_RUN` ayrımı teslim kararını doğrudan etkiler: ölçemediğimiz bir
iş "kırık" gibi görünürse, kırık olmayan bir teslim reddedilir.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True

_SCRIPTS = Path(__file__).resolve().parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

from umaf_runtime.checks import validate_checks  # noqa: E402
from umaf_runtime.paths import path_list  # noqa: E402
from verify_lanes import run_one  # noqa: E402

MAX_TIMEOUT = 3600
"""Kontrol başına üst süre.

Sandbox kontrolleri kısa olmalı; host şeridinde gerçek toolchain süreleri
(`flutter test` gibi) dakikalar sürebilir. 300 saniyelik bir tavan Windows
toolchain'ini hiçbir projede koşturamıyordu.
"""


def _load_plan(task: Path) -> dict:
    """Zarfı okur ve sözleşmeyi doğrular; bozulursa `ValueError` yükseltir.

    `utf-8-sig`: PowerShell'in `Out-File -Encoding utf8` dosyaya BOM yazar.
    Reddetmek hatayı kodda değil dosyanın ilk üç baytında kaybettirir.
    """
    plan = json.loads(task.read_text(encoding="utf-8-sig"))
    if not isinstance(plan, dict) or "checks" not in plan:
        raise ValueError("Zarfta `checks` alanı yok")
    for field in ("read_files", "write_files"):
        if field in plan:
            path_list(plan[field])
    validate_checks(plan["checks"])
    return plan


def _verdict(evidence: list[dict]) -> str:
    """Toplam karar: FAIL baskıdır, hiç ölçülemediyse NOT_RUN."""
    failed = [c for c in evidence if c["status"] == "FAIL"]
    if failed:
        return "FAIL"
    if any(c["status"] == "PASS" for c in evidence):
        return "PASS"
    return "NOT_RUN"


EXIT_FOR = {"PASS": 0, "FAIL": 1, "NOT_RUN": 2}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="verify_candidate", description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--candidate", type=Path, required=True, help="Aday dizin")
    parser.add_argument("--task", type=Path, required=True, help="Zarf JSON")
    parser.add_argument("--timeout", type=int, default=60,
                        help=f"Kontrol başına süre (1..{MAX_TIMEOUT})")
    parser.add_argument("--lane", choices=("auto", "sandbox", "host"), default="auto",
                        help="auto: sandbox dene, araç yoksa hosta düş. "
                             "sandbox: asla hosta düşmez")
    args = parser.parse_args(argv)

    if not 1 <= args.timeout <= MAX_TIMEOUT:
        print(f"BLOCKED: timeout 1..{MAX_TIMEOUT} aralığında olmalı", file=sys.stderr)
        return 2

    try:
        plan = _load_plan(args.task)
    except (OSError, ValueError, UnicodeError, json.JSONDecodeError) as exc:
        print(f"BLOCKED: zarf reddedildi -> {exc}", file=sys.stderr)
        return 2

    candidate = args.candidate.expanduser()
    if not candidate.is_dir():
        print(f"BLOCKED: aday dizini yok: {candidate}", file=sys.stderr)
        return 2

    evidence = [run_one(check, candidate, args.lane, args.timeout)
                for check in plan["checks"]]
    verdict = _verdict(evidence)
    report = {
        "candidate": str(candidate),
        "lane_policy": args.lane,
        "checks": evidence,
        "verdict": verdict,
        "summary": {
            "total": len(evidence),
            "passed": sum(c["status"] == "PASS" for c in evidence),
            "failed": sum(c["status"] == "FAIL" for c in evidence),
            "unmeasured": sum(c["status"] == "NOT_RUN" for c in evidence),
        },
    }
    print(json.dumps(report, indent=2, ensure_ascii=True))
    return EXIT_FOR[verdict]


if __name__ == "__main__":
    raise SystemExit(main())