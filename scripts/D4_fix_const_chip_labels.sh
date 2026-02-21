#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# 1) Fjern "const Text(" bare for de to label-tekstene
# Kun kampanjer
s, n1 = re.subn(
    r"label:\s*const\s+Text\(\s*'Kun kampanjer'",
    "label: Text('Kun kampanjer'",
    s
)

# Favoritter først (kan være 'Favoritter først' eller 'Favoritter først ' osv)
s, n2 = re.subn(
    r"label:\s*const\s+Text\(\s*'Favoritter først'",
    "label: Text('Favoritter først'",
    s
)

# 2) Hvis patchen tidligere har laget const TextStyle(...) inni disse labelene,
# fjern const på TextStyle i nærheten av disse to labelene (trygt/smalt)
def relax_const_textstyle_near(label_text: str, text: str) -> tuple[str,int]:
    # finn en "label: Text('...'" blokk og fjern "const TextStyle(" inni en liten radius
    idx = text.find(f"label: Text('{label_text}'")
    if idx == -1:
        return text, 0
    start = max(0, idx-200)
    end = min(len(text), idx+800)
    block = text[start:end]
    block2, n = re.subn(r"const\s+TextStyle\(", "TextStyle(", block)
    if n:
        text = text[:start] + block2 + text[end:]
    return text, n

s, n3 = relax_const_textstyle_near("Kun kampanjer", s)
s, n4 = relax_const_textstyle_near("Favoritter først", s)

p.write_text(s, encoding="utf-8")
print(f"✅ Patched chip label consts: Kun kampanjer={n1}, Favoritter først={n2}, TextStyle fixes={n3+n4}")
PY

dart format "$FILE"

echo "✅ Done. Nå kan du kjøre flutter run igjen."
