#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/cards_page.dart"
if [[ ! -f "$FILE" ]]; then
  echo "Fant ikke $FILE (hopper over)"
  exit 0
fi

cp "$FILE" "$FILE.bak.$(date +%s)"

# Fjern "const " foran vanlige widget-kall (beholder const Text/Icon osv)
python3 - "$FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# typisk: const CardsPage( ... )  / const SomeWidget( ... )
# vi lar const Text/Icon/SizedBox/EdgeInsets stå
keep = {"Text","Icon","SizedBox","EdgeInsets","Padding","Center","Row","Column","Spacer","Divider"}

def repl(m):
  name = m.group(1)
  if name in keep:
    return m.group(0)
  return f"{name}("

s2 = re.sub(r"\bconst\s+([A-Za-z_]\w*)\s*\(", repl, s)
if s2 == s:
  print("ℹ️ Ingen const-kall å endre i cards_page.dart")
else:
  p.write_text(s2, encoding="utf-8")
  print("✅ Fjernet 'const' foran ikke-const widgets i cards_page.dart")
PY

dart format "$FILE" || true
flutter analyze || true
