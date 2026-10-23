"""Conservative portable paths; no link or Windows alias traversal."""

import re
import stat
from pathlib import Path

PROTECTED = {"agents.md", ".git", ".agents", ".opencode", ".env", ".ssh"}
RESERVED = re.compile(r"^(con|prn|aux|nul|com[0-9]|lpt[0-9])(?:\.|$)", re.I)


def relative_path(value):
    if not isinstance(value, str) or not value or len(value) > 240:
        raise ValueError("Invalid relative path")
    parts = value.split("/")
    for part in parts:
        if (not part or part in {".", ".."} or part.endswith((".", " "))
                or any(ord(c) < 32 or c in '\\:*?"<>|' for c in part)
                or part.lower() in PROTECTED or part.lower().startswith(".env.")
                or RESERVED.match(part)):
            raise ValueError("Protected or ambiguous path")
    return value


def no_links(path):
    """Check ancestors too: resolve() alone would hide a junction."""
    for item in [path, *path.parents]:
        try:
            info = item.lstat()
        except FileNotFoundError:
            continue
        if (stat.S_ISLNK(info.st_mode)
                or getattr(info, "st_file_attributes", 0) & 0x400):
            raise ValueError("Links and reparse points are not supported")


def scoped_path(root, value):
    relative_path(value)
    path = root / value
    no_links(path)
    if not path.resolve().is_relative_to(root.resolve()):
        raise ValueError("Path escapes workspace")
    return path


def path_list(values):
    if not isinstance(values, list) or not values or len(values) > 100:
        raise ValueError("Expected 1..100 explicit paths")
    paths = [relative_path(value) for value in values]
    if len({p.casefold() for p in paths}) != len(paths):
        raise ValueError("Duplicate or case-alias paths")
    return paths
