"""Doğrulama şeritleri: sandbox (tam izolasyon) ve host (izolasyon YOK).

İki şerit birbirine KARIŞMAMALIDIR; bu modülün varoluş sebebi budur.

* **sandbox** — `bubblewrap` içinde. Ağ yok, host mount'u yok, komut çıktısı
  devnull'a atılır. Ancak içinde yalnız WSL'in kendi dosya sistemi vardır:
  `dart`, `flutter`, `node` gibi geliştirme araçları genellikle YOKTUR.
* **host** — komut doğrudan makinede koşar, gerçek toolchain kullanılır. Ama
  izolasyon YOKTUR: aday kod makinenin tamamına erişebilir. Windows'ta araçlar
  çoğunlukla `.BAT` sarmalayıcı olduğundan `cmd.exe` üzerinden çalışır.

Bu yüzden her kanıt kaydı `lane` ve `isolation` alanlarını taşır. Host sonucu
okunduğunda "izolasyon yok" yazıyor olmalıdır; bu etiket yanlış taşınırsa
teslim kararı yanlış temele oturur.

ÖLÇÜLEMEZLİK
------------
Bir kontrol iki farklı şekilde "kötü" olabilir:

* komut koştu ve sıfır dışı döndü → **FAIL** (iş gerçekten kırık)
* komut **bulunamadı** ya da süre aştı → **NOT_RUN** (ölçemedik)

İkisi karıştırılırsa ölçemediğimiz bir iş "kırık" görünür ve kırık olmayan
teslim reddedilir.
"""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

from umaf_runtime.sandbox import invoke

# POSIX kabuğunda "komut bulunamadı" dönüş kodu. `timeout` 124, `prlimit`
# ise 137 ile döner; ikisi de ölçüm değil, çalıştırma hatasıdır.
EXIT_COMMAND_NOT_FOUND = 127
EXIT_TIMEOUT = 124
EXIT_KILLED = 137

# Host şeridinin etiketleri. Raporu okuyan kişi izolasyonun OLMADIĞINI
# görebilmelidir; "güvenli sandbox" yazısı host sonucuna sızmamalıdır.
HOST_NO_ISOLATION = "YOK — aday kod makineye erişebilir"
HOST_FALLBACK = "YOK — sandbox'ta araç yoktu, otomatik olarak hosta düşüldü"


def clip_output(text: str, limit: int = 800) -> str:
    """Çıktıyı keser ama ORTASINDAN keser.

    Test koşucularında kararı taşıyan satır sonda gelir (`All tests passed!`,
    `Some tests failed`, `No issues found!`), ilerleme çıktısı başta. Baştan
    `limit` karakter almak karar satırını atar ve kanıt işe yaramaz hale gelir:
    FAIL gördüğümüzde nedenini okuyamayız.
    """
    text = text.strip()
    if len(text) <= limit:
        return text
    head = tail = limit // 2 - 20
    atlanan = len(text) - head - tail
    return (f"{text[:head]}\n...[KIRPILDI: {atlanan} karakter atlandi]...\n"
            f"{text[-tail:]}")


def host_command(argv: list[str]) -> tuple[list[str], str, str]:
    """Host çalıştırma komutunu kurar; Windows `.bat` tuzağını da çözer.

    Windows'ta `dart`, `flutter`, `npm` gibi araçlar çoğunlukla `.BAT`
    sarmalayıcıdır, `.exe` değil. `subprocess` `shell=False` ile `.bat`
    ÇALIŞTIREMEZ (WinError 2 / WinError 193). Bu bir kusur değil, Windows'un
    davranışıdır; çözüm `cmd.exe /d /s /c` + `list2cmdline` ile tırnaklamaktır.

    DÜRÜSTLÜK: bu yol argv'yi cmd.exe'e verir, yani kabuk yorumlaması devreye
    girer. Sandbox şeridinde bu ASLA olmaz. Host şeridi zaten "izolasyon YOK"
    etiketini taşıdığı için bu ek risk `via` alanında ayrıca yazılır.
    """
    # DİKKAT: `shutil.which(cmd, path=X)` yalnız X içinde arar, PATH'e EKLEMEZ.
    # Burada `path=` vermek aramayı cwd ile değiştirir ve PATH'teki araçlar
    # bulunamaz. Daraltma yalnız argv[0] bir yol içeriyorsa (./script, sub\tool)
    # yapılır; normal komu adlarında PATH kullanılır.
    if "/" in argv[0] or "\\" in argv[0]:
        resolved = shutil.which(argv[0], path=str(Path.cwd())) or argv[0]
    else:
        resolved = shutil.which(argv[0]) or argv[0]
    if os.name == "nt" and resolved.lower().endswith((".bat", ".cmd")):
        comspec = os.environ.get("COMSPEC", "cmd.exe")
        line = subprocess.list2cmdline([resolved, *argv[1:]])
        return [comspec, "/d", "/s", "/c", line], resolved, "cmd.exe (.bat sarmalayıcı)"
    return list(argv), resolved, "doğrudan çalıştırma"


def tool_in_sandbox(argv0: str, candidate: Path) -> bool:
    """Sandbox içinde bu çalıştırılabilir var mı?

    Değer konumsal argüman olarak geçirilir (`sh -c 'command -v "$1"' sh X`),
    böylece kabuk enjeksiyonu mümkün değildir.
    """
    try:
        probe = invoke(["/bin/sh", "-c", 'command -v "$1"', "sh", argv0], candidate, 20)
    except OSError:
        # Sandbox arka ucu (WSL/bubblewrap) yoksa sandbox'ta araç da yoktur.
        return False
    return probe.returncode == 0


def tool_on_host(argv0: str) -> bool:
    """Hostta bu çalıştırılabilir var mı?

    `host_command` ile AYNI arama kuralı kullanılır; iki yer ayrışırsa "araç
    var" deyip koşturulamayan bir komuta düşülürdü.
    """
    resolved, _, _ = host_command([argv0])
    return resolved != argv0 or bool(shutil.which(argv0))


def run_host(argv: list[str], cwd: Path, timeout: int) -> dict:
    """Komutu hostta koşar. DosyaNotFound hatası = araç yok demektir."""
    command, resolved, via = host_command(argv)
    try:
        done = subprocess.run(
            command, cwd=str(cwd), capture_output=True, text=True,
            encoding="utf-8", errors="replace", timeout=timeout, check=False,
        )
    except FileNotFoundError:
        return {"exit_code": None, "status": "NOT_RUN", "reason": "command_not_found",
                "resolved": resolved, "via": via, "output": ""}
    except subprocess.TimeoutExpired:
        return {"exit_code": None, "status": "NOT_RUN", "reason": "timeout",
                "resolved": resolved, "via": via, "output": ""}
    except OSError as exc:
        return {"exit_code": None, "status": "NOT_RUN", "reason": str(exc)[:120],
                "resolved": resolved, "via": via, "output": ""}
    return {"exit_code": done.returncode,
            "status": "PASS" if done.returncode == 0 else "FAIL", "reason": None,
            "resolved": resolved, "via": via,
            "output": clip_output((done.stdout or "") + (done.stderr or ""))}


def run_sandbox(argv: list[str], candidate: Path, timeout: int) -> dict:
    """Komutu sandbox'ta koşar. 127 = araç yok, 124/137 = zaman aşımı."""
    code = invoke(argv, candidate, timeout).returncode
    # Sandbox çıktısı YOK: `invoke` stdout/stderr'i devnull'a yönlendirir. Bu,
    # izolasyonun bir parçasıdır; host şeridi çıktıyı rapora katar. İki şeridin
    # kanıt değeri bu yüzden eşit değildir.
    base = {"resolved": argv[0], "via": "bubblewrap (kabuk yok)", "output": ""}
    if code == EXIT_COMMAND_NOT_FOUND:
        return {**base, "exit_code": code, "status": "NOT_RUN",
                "reason": "command_not_found"}
    if code in (EXIT_TIMEOUT, EXIT_KILLED):
        return {**base, "exit_code": code, "status": "NOT_RUN",
                "reason": "timeout_or_killed"}
    return {**base, "exit_code": code, "status": "PASS" if code == 0 else "FAIL",
            "reason": None}


def record(argv: list[str], *, status: str, lane: str, isolation: str,
           exit_code: int | None = None, reason: str | None = None,
           resolved: str = "", via: str = "", output: str = "") -> dict:
    """Kanonik kanıt kaydı: her kontrol aynı alanları taşır.

    Alan eksikliği tüketicinin "koştu mu, koşmadı mı" ayrımını tahmin etmeye
    zorlar. `argv` olmadan rapor hangi komutun koştuğunu söylemez; `isolation`
    olmadan host sonucu sandbox sonucuyla karışır.
    """
    return {"argv": list(argv), "status": status, "lane": lane,
            "isolation": isolation, "exit_code": exit_code, "reason": reason,
            "resolved": resolved, "via": via, "output": output}


def run_one(argv: list[str], candidate: Path, lane: str, timeout: int) -> dict:
    """Tek kontrolü istenen şeritte koşar ve kanıt kaydını döndürür.

    `lane="sandbox"` ikinci şeride DÜŞMEZ: eksikse NOT_RUN kalır. Düşseydi,
    "--lane sandbox" veren bir işçi farkında olmadan izolasyonsuz koşturulurdu.
    """
    if lane == "host":
        return record(argv, lane="host", isolation=HOST_NO_ISOLATION,
                      **run_host(argv, candidate, timeout))

    if tool_in_sandbox(argv[0], candidate):
        return record(argv, lane="sandbox", isolation="tam",
                      **run_sandbox(argv, candidate, timeout))

    # Sandbox'ta araç yok. Buradan sonrası şerit politikasına bağlı.
    if lane == "sandbox":
        return record(argv, status="NOT_RUN", lane="sandbox", isolation="tam",
                      reason="sandbox'ta araç yok")
    if not tool_on_host(argv[0]):
        return record(argv, status="NOT_RUN", lane="-", isolation="-",
                      reason="araç ne sandbox'ta ne hostta")
    return record(argv, lane="host", isolation=HOST_FALLBACK,
                  **run_host(argv, candidate, timeout))