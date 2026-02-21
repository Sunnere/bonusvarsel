#!/usr/bin/env bash
set -euo pipefail

python - <<'PY'
from pathlib import Path
import re, time

ROOT = Path("lib")
ts = str(int(time.time()))

def backup(p: Path):
    b = p.with_suffix(p.suffix + f".bak.{ts}")
    b.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")

def patch_file(p: Path) -> bool:
    s = p.read_text(encoding="utf-8")
    orig = s

    # 1) withOpacity(x) -> withValues(alpha: (x*255).round())
    # (Vi bruker runtime-regning i Dart for å være safe)
    s = re.sub(
        r"\.withOpacity\(\s*([0-9]*\.?[0-9]+)\s*\)",
        r".withValues(alpha: ((\1) * 255).round())",
        s,
    )

    # 2) ColorScheme copyWith(background: ...) -> surface: ...
    # (kun nøkkelnavn, ikke semantikk)
    s = re.sub(r"\bbackground\s*:", "surface:", s)

    # 3) Switch(activeColor: ...) -> activeThumbColor:
    s = re.sub(r"\bactiveColor\s*:", "activeThumbColor:", s)

    # 4) TextFormField(value: ...) -> initialValue:
    # NB: Vi bytter bare selve parameter-navnet.
    s = re.sub(r"\bTextFormField\(\s*([\s\S]*?)\bvalue\s*:", r"TextFormField(\1initialValue:", s)

    if s != orig:
        backup(p)
        p.write_text(s, encoding="utf-8")
        return True
    return False

changed = []
for p in ROOT.rglob("*.dart"):
    if patch_file(p):
        changed.append(str(p))

print("✅ Patchet filer:")
if changed:
    for c in changed:
        print(" -", c)
else:
    print(" - (ingen endringer nødvendig)")
PY

dart format lib >/dev/null
echo "✅ Formatert"

flutter analyze || true
