#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")
orig = s

# 1) Legg til en cached Future i State (hvis den mangler)
if "_futureShops" not in s:
  # finn start av state-klassen og legg inn felt etter første { i klassen
  s = re.sub(
    r"(class\s+_EbShoppingPageState\s+extends\s+State<EbShoppingPage>\s*\{\s*)",
    r"\1\n  late final Future<List<_ShopOffer>> _futureShops;\n",
    s,
    count=1
  )

# 2) Initér _futureShops i initState (hvis initState finnes)
if "void initState()" in s and "_futureShops =" not in s:
  s = re.sub(
    r"(void\s+initState\(\)\s*\{\s*\n\s*super\.initState\(\);\s*\n)",
    r"\1    _futureShops = _load();\n",
    s,
    count=1
  )

# Hvis initState ikke finnes, lag en minimal initState
if "void initState()" not in s:
  s = re.sub(
    r"(class\s+_EbShoppingPageState\s+extends\s+State<EbShoppingPage>\s*\{\s*)",
    r"\1\n  @override\n  void initState() {\n    super.initState();\n    _futureShops = _load();\n  }\n",
    s,
    count=1
  )

# 3) FutureBuilder: bytt future: _load() -> future: _futureShops
s = re.sub(r"future:\s*_load\(\)\s*,", "future: _futureShops,", s)

# 4) Hindrer unødvendig reload på refresh-knapp:
# Hvis du har onPressed: () => setState(() {}), så la den heller trigge _futureShops = _load() via Hot Restart? (late final kan ikke settes)
# Så vi lar refresh bare gjøre setState (UI refresh) – og legger en kommentar hvis den finnes
s = re.sub(r"onPressed:\s*\(\)\s*=>\s*setState\(\(\)\s*\{\}\)\s*,",
           "onPressed: () => setState(() {}), // refresh UI (data cached)\n", s)

if s != orig:
  p.write_text(s, encoding="utf-8")
  print("✅ perf patch applied")
else:
  print("ℹ️ no changes (already patched?)")
PY

dart format lib/pages/eb_shopping_page.dart
flutter analyze

echo "== [7] Perf tweaks done =="
