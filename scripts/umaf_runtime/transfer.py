"""Per-file atomic publication plus conflict-aware best-effort batch rollback."""

import os
import shutil
import tempfile
from pathlib import Path

from .paths import scoped_path


class TransferFailure(RuntimeError):
    def __init__(self, recovery_required):
        super().__init__("Apply failed; inspect saved source backup")
        self.recovery_required = recovery_required


class CleanupFailure(OSError):
    def __init__(self, path):
        super().__init__("Temporary publication file needs cleanup")
        self.path = path


def current(path):
    return path.read_bytes() if path.exists() else None


def publish(path, data, *, create, on_commit=lambda: None):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=".umaf-", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        if create:
            # Hard-link creation is exclusive: a concurrently created target wins.
            os.link(temporary, path)
        else:
            shutil.copymode(path, temporary)
            os.replace(temporary, path)
        on_commit()
    finally:
        try:
            temporary.unlink(missing_ok=True)
        except OSError:
            raise CleanupFailure(temporary) from None


def rollback(root, before, changes, written):
    conflicts = []
    for relative in reversed(written):
        try:
            path = scoped_path(root, relative)
            if current(path) != changes[relative]:
                raise ValueError("Rollback conflict: preserve changed file")
            if before[relative] is None:
                path.unlink()
            else:
                publish(path, before[relative], create=False)
        except (ValueError, OSError):
            conflicts.append(relative)
    return conflicts


def transfer(root, before, changes):
    written = []
    try:
        for relative, data in changes.items():
            path = scoped_path(root, relative)
            if current(path) != before[relative]:
                raise ValueError("Concurrent source change")
            publish(path, data, create=before[relative] is None,
                    on_commit=lambda: written.append(relative))
    except Exception as error:
        conflicts = rollback(root, before, changes, written)
        if isinstance(error, CleanupFailure):
            conflicts.append(error.path.relative_to(root).as_posix())
        if conflicts:
            raise TransferFailure(conflicts) from None
        raise
