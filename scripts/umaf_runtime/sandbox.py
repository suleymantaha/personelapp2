"""Fail-closed Linux namespace runner, native Linux or Windows WSL backend."""

import os
import platform
import subprocess
from pathlib import Path


def guest_path(path):
    path = Path(path).resolve()
    if platform.system() != "Windows":
        return str(path)
    drive = path.drive
    if len(drive) != 2 or drive[1] != ":":
        raise ValueError("Only local drive paths supported by WSL runner")
    return "/mnt/" + drive[0].lower() + path.as_posix()[2:]


def command(argv, candidate, timeout):
    """No shell, host root/home/socket mounts, network or inherited credentials."""
    prefix = ["wsl.exe", "--exec"] if platform.system() == "Windows" else []
    return prefix + [
        "/usr/bin/timeout", "--signal=KILL", str(timeout),
        "/usr/bin/bwrap", "--unshare-all", "--unshare-user", "--die-with-parent", "--new-session",
        "--disable-userns", "--assert-userns-disabled", "--cap-drop", "ALL",
        "--clearenv", "--ro-bind", "/usr", "/usr",
        "--symlink", "usr/bin", "/bin", "--symlink", "usr/lib", "/lib",
        "--symlink", "usr/lib64", "/lib64", "--proc", "/proc", "--dev", "/dev",
        "--size", "67108864", "--tmpfs", "/tmp",
        "--ro-bind", guest_path(candidate), "/work", "--chdir", "/work",
        "--setenv", "PATH", "/usr/bin:/bin", "--setenv", "HOME", "/tmp",
        "--setenv", "PYTHONDONTWRITEBYTECODE", "1", "--",
        "/usr/bin/prlimit", "--as=536870912", "--cpu=30", "--nofile=128",
        "--fsize=10485760", "--nproc=64", "--", *argv]


def invoke(argv, candidate, timeout):
    """No host root/home/socket mounts, no network, minimal inherited environment.

    Ortam sizintisi hakkında ÖLÇÜLMÜŞ GERÇEK (2026-10-18): çalıştırılan sürecin
    ortamı temizdir (`HOME=/tmp`, `PATH=/usr/bin:/bin`), ancak PID 1 olan bwrap'in
    kendi init süreci `--clearenv`'den ÖNCE doğar ve `/proc/1/environ` üzerinden
    host PATH'i ile kullanıcı adı okunabilir. Kimlik bilgisi sızmaz (sır
    taraması temiz) ve erişilebilir bir hedefe bağlı değildir: `/mnt/c`, `/home`
    ve `/run/WSL` mount edilmediği için interop soketine ulaşılamaz. Bu kaçış
    değil, ölçülmüş ve kabul edilmiş bir bilgi sızıntısıdır.
    """
    allowed = {"PATH", "SYSTEMROOT", "WINDIR", "TEMP", "TMP", "COMSPEC"}
    env = {k: v for k, v in os.environ.items() if k.upper() in allowed}
    # WSLENV ve tüm provider sırları bilinçli olarak dışarıda bırakılır.
    return subprocess.run(command(argv, candidate, timeout), env=env, shell=False,
                          stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL, timeout=timeout + 5, check=False)
