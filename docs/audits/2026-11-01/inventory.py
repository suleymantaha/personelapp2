"""Read-only tracked-source inventory; regex counts are candidates, not bugs."""
import collections
import hashlib
import json
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT = pathlib.Path(__file__).resolve().parent


def main():
    tracked = subprocess.check_output(
        ["git", "ls-files", "-z"], cwd=ROOT
    ).decode().split("\0")
    rows = []
    for name in tracked:
        if not name or not name.startswith("lib/") or not name.endswith(".dart"):
            continue
        if "/generated/" in name or name.endswith((".g.dart", ".freezed.dart")):
            continue
        raw = (ROOT / name).read_bytes()
        source = raw.decode("utf-8-sig")
        rows.append({
            "path": name,
            "lines": len(source.splitlines()),
            "sha256": hashlib.sha256(raw).hexdigest(),
            "literal_colors": len(re.findall(r"\bColor\(0x[0-9a-fA-F]+\)", source)),
            "material_colors": len(re.findall(r"\bColors\.\w+", source)),
            "literal_text_widgets": len(re.findall(r"\bText\(\s*['\"]", source)),
            "todo_debug_candidates": len(re.findall(
                r"\b(?:TODO|FIXME|debugPrint|print|developer\.log)\b", source)),
        })
    modules = collections.Counter(
        "/".join(row["path"].split("/")[:3]) for row in rows
    )
    payload = {
        "base": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT)
        .decode().strip(),
        "method": "tracked handwritten Dart; blank lines included; lexical counts",
        "modules": dict(sorted(modules.items())),
        "files": rows,
    }
    (OUT / "inventory.json").write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    lines = ["# Kaynak envanteri", "", f"El yazımı lib Dart dosyası: {len(rows)}.",
             "Generated localization ve *.g.dart/*.freezed.dart hariç.",
             "Boş satırlar dahil; regex sayıları AST analizi veya hata kanıtı değildir.",
             "", "| Ölçüm | Değer |", "|---|---:|"]
    for label, value in [
        ("300 satırdan uzun dosya", sum(r["lines"] > 300 for r in rows)),
        ("500 ve üzeri satır", sum(r["lines"] >= 500 for r in rows)),
        ("Literal Color(...)", sum(r["literal_colors"] for r in rows)),
        ("Colors.* kullanımı", sum(r["material_colors"] for r in rows)),
        ("Literal ile başlayan Text(...) adayı", sum(r["literal_text_widgets"] for r in rows)),
    ]:
        lines.append(f"| {label} | {value} |")
    lines += ["", "## En uzun 15 dosya", "", "| Dosya | Satır |", "|---|---:|"]
    for row in sorted(rows, key=lambda r: r["lines"], reverse=True)[:15]:
        lines.append(f'| `{row["path"]}` | {row["lines"]} |')
    lines += ["", "## Modül dağılımı", "", "| Modül | Dosya |", "|---|---:|"]
    lines += [f"| `{key}` | {count} |" for key, count in sorted(modules.items())]
    (OUT / "INVENTORY.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Inventoried {len(rows)} handwritten lib files")


if __name__ == "__main__":
    main()
