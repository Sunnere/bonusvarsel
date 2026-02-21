#!/usr/bin/env bash
set -euo pipefail

python - <<'PY'
from pathlib import Path
import re, math

# 1) Fix deprecated withOpacity -> withAlpha(int)
p = Path("lib/widgets/premium_card.dart")
if p.exists():
    s = p.read_text(encoding="utf-8")
    def repl(m):
        val = float(m.group(1))
        a = int(round(max(0.0, min(1.0, val)) * 255))
        return f".withAlpha({a})"
    s2 = re.sub(r"\.withOpacity\(\s*([0-9]*\.?[0-9]+)\s*\)", repl, s)
    if s2 != s:
        p.write_text(s2, encoding="utf-8")
        print("Updated:", p)

# 2) Remove unused fields in eb_shopping_page.dart
p = Path("lib/pages/eb_shopping_page.dart")
if p.exists():
    s = p.read_text(encoding="utf-8").splitlines(True)
    out = []
    for line in s:
        if re.search(r"\bfinal\s+EbRepository\s+_repo\s*=", line):
            continue
        if re.search(r"\bList<\s*dynamic\s*>\s+_shops\s*=", line):
            continue
        if re.search(r"\bbool\s+_loading\s*=", line):
            continue
        out.append(line)
    s2 = "".join(out)
    if s2 != "".join(s):
        p.write_text(s2, encoding="utf-8")
        print("Cleaned:", p)

PY

dart format lib/widgets/premium_card.dart lib/pages/eb_shopping_page.dart
flutter analyze
