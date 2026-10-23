"""Snapshot and candidate boundary. Host processes remain trusted."""

import hashlib
import json
from pathlib import Path

from .paths import no_links, path_list, scoped_path
from .transfer import transfer

MAX_BYTES = 512 * 1024


def read_bytes(path):
    if not path.exists():
        return None
    if not path.is_file() or path.stat().st_size > MAX_BYTES:
        raise ValueError("Not a bounded regular file")
    if path.stat().st_nlink != 1:
        raise ValueError("Hard-linked files are not supported")
    data = path.read_bytes()
    if len(data) > MAX_BYTES:
        raise ValueError("File exceeds size limit")
    data.decode("utf-8")
    return data


class Workspace:
    def __init__(self, root, read_files, write_files):
        self.root = Path(root).absolute()
        no_links(self.root)
        self.root = self.root.resolve()
        if not self.root.is_dir():
            raise ValueError("Source directory missing")
        self.read_files = path_list(read_files)
        self.write_files = path_list(write_files)
        paths = sorted(set(self.read_files + self.write_files))
        if len({p.casefold() for p in paths}) != len(paths):
            raise ValueError("Case-alias paths")
        self.before = {p: read_bytes(scoped_path(self.root, p)) for p in paths}
        if sum(len(v or b"") for v in self.before.values()) > MAX_BYTES:
            raise ValueError("Snapshot exceeds size limit")
        self.changes = {}

    def context(self):
        return {p: v.decode("utf-8") for p, v in self.before.items() if v is not None}

    def manifest(self):
        return {p: hashlib.sha256(v).hexdigest() if v is not None else None
                for p, v in self.before.items()}

    def backup(self, folder):
        folder.mkdir(exist_ok=False)
        for path, data in self.before.items():
            if data is not None:
                target = scoped_path(folder, path)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)

    def stage(self, candidate, changes):
        if not isinstance(changes, list) or not 1 <= len(changes) <= 100:
            raise ValueError("Expected nonempty changes")
        prepared = {}
        for change in changes:
            if not isinstance(change, dict) or set(change) != {"path", "content"}:
                raise ValueError("Invalid change schema")
            path, content = change["path"], change["content"]
            if not isinstance(path, str) or path not in self.write_files or path in prepared:
                raise ValueError("Unowned or duplicate change")
            if not isinstance(content, str):
                raise ValueError("Content must be UTF-8 text")
            prepared[path] = content.encode("utf-8")
        if sum(map(len, prepared.values())) > MAX_BYTES:
            raise ValueError("Changes exceed size limit")
        candidate = Path(candidate).absolute()
        no_links(candidate)
        candidate = candidate.resolve()
        if candidate.is_relative_to(self.root) or self.root.is_relative_to(candidate):
            raise ValueError("Candidate must be separate from source")
        candidate.mkdir(parents=True, exist_ok=False)
        for path, content in (self.before | prepared).items():
            if content is not None:
                target = scoped_path(candidate, path)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(content)
        self.changes = prepared
        self.staged_digest = self.digest(candidate)

    def digest(self, candidate):
        root = Path(candidate)
        no_links(root)
        actual = {}
        for path in sorted(root.rglob("*")):
            no_links(path)
            if path.is_file():
                relative = path.relative_to(root).as_posix()
                data = read_bytes(scoped_path(root, relative))
                actual[relative] = hashlib.sha256(data).hexdigest()
        expected = {p for p, v in (self.before | self.changes).items() if v is not None}
        if set(actual) != expected:
            raise ValueError("Candidate file set changed")
        return hashlib.sha256(json.dumps(actual, sort_keys=True).encode()).hexdigest()

    def assert_source(self):
        for path, expected in self.before.items():
            if read_bytes(scoped_path(self.root, path)) != expected:
                raise ValueError("Source changed since snapshot")

    def apply(self, candidate, expected_digest):
        if (not self.changes or self.digest(candidate) != expected_digest
                or expected_digest != self.staged_digest):
            raise ValueError("Candidate hash mismatch")
        self.assert_source()
        transfer(self.root, self.before, self.changes)
