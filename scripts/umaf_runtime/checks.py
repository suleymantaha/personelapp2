"""Execute only the trusted task author's argv, never model-generated commands."""

import subprocess
from datetime import datetime, timezone
from pathlib import Path

from .sandbox import invoke

# Shell yorumlayıcıları reddedilir.
#
# Gerekçe GÜVENLİK DEĞİL, DENETLENEBİLİRLİKTİR: `["pytest", "-q"]` ne yapacağı
# okunabilir; `["sh", "-c", "..."]` opaktır ve argv denetimi anlamını yitirir.
# Görev yazarına GÜVENİLİR ve gerçek sınır sandbox'tır; bu kural kaçışı
# değil, belgelenen "sabit argv" sözleşmesini fiilen uygular.
#
# KALAN BOŞLUK (bilinçli, gizlenmiyor): `["python3", "-c", "..."]` ve
# `["node", "-e", "..."]` gibi satır içi betik argümanları keyfi kod
# çalıştırır ve reddedilmez. Bunları reddetmek gerçek projelerde kullanımı
# imkânsız kılardı. Yani bu kural "shell YOK" değil, "kabuk sarmalayıcı YOK"
# garantisidir. İçerik yine de sandbox içinde ve yetkili yazara aittir.
SHELL_INTERPRETERS = frozenset({
    "sh", "bash", "zsh", "dash", "ksh", "mksh", "csh", "tcsh",
    "busybox", "env", "xargs", "eval", "su", "nohup", "setsid",
    "cmd", "cmd.exe", "powershell", "powershell.exe", "pwsh",
})


def _executable_name(argv0):
    """argv[0] dosya adı; yol ve uzantı gürültüsünden arındırılmış."""
    name = Path(argv0.replace("\\", "/")).name.lower()
    for suffix in (".exe", ".cmd", ".bat", ".com"):
        if name.endswith(suffix):
            name = name[: -len(suffix)]
    return name


def validate_checks(checks):
    if not isinstance(checks, list) or not 1 <= len(checks) <= 20:
        raise ValueError("At least one real check is required")
    for argv in checks:
        if (not isinstance(argv, list) or not argv or len(argv) > 100
                or any(not isinstance(v, str) or not v or "\0" in v for v in argv)):
            raise ValueError("Checks must be explicit argv lists")
        if _executable_name(argv[0]) in SHELL_INTERPRETERS:
            raise ValueError(
                f"Shell sarmalayıcı kullanılamaz: {argv[0]!r}. Kontroller sabit bir "
                "çalıştırılabilir olmalı (örn. ['pytest', '-q']) ki denetim anlam "
                "kaybolmasın. Not: satır içi betik argümanları (python3 -c) "
                "kasıtlı olarak engellenmez; güven sınırı sandbox'tır."
            )


def run_checks(checks, candidate, timeout=60):
    validate_checks(checks)
    evidence = []
    for argv in checks:
        record = {"argv": argv, "cwd": str(candidate),
                  "sandbox_cwd": "/work", "sandbox": "bubblewrap-unshare-all",
                  "utc": datetime.now(timezone.utc).isoformat()}
        try:
            if not evidence and invoke(["/usr/bin/true"], candidate, timeout).returncode != 0:
                record.update(exit_code=None, status="BLOCKED", reason="sandbox_unavailable")
                evidence.append(record)
                break
            result = invoke(argv, candidate, timeout)
            record.update(exit_code=result.returncode, status="PASS" if result.returncode == 0 else "FAIL")
        except (OSError, subprocess.TimeoutExpired):
            record.update(exit_code=None, status="BLOCKED")
        evidence.append(record)
        if record["status"] != "PASS":
            break
    return evidence
