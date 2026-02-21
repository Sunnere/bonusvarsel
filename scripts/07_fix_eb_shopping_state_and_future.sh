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

# --- Finn returtypen til _load() ---
# Eks: Future<List<Map<String, dynamic>>> _load() async {
m = re.search(r'Future<\s*([^>]+(?:>[^>]*)?)\s*>\s+_load\s*\(', s)
# fallback: Future<List<dynamic>> hvis vi ikke finner
load_inner = (m.group(1).strip() if m else "List<dynamic>")

# --- Finn State-klassen ---
state_decl = re.search(r'class\s+_EbShoppingPageState\s+extends\s+State<EbShoppingPage>\s*\{', s)
if not state_decl:
  raise SystemExit("Fant ikke _EbShoppingPageState. Stoppet.")

# Hjelper: sjekk om et felt allerede finnes
def has(pattern: str) -> bool:
  return re.search(pattern, s) is not None

insert_bits = []

# 1) _futureShops med riktig type
if not has(r'\b_futureShops\b'):
  insert_bits.append(f'  late final Future<{load_inner}> _futureShops;\n')

# 2) Nødvendige state-felter (kun hvis de mangler)
if not has(r'\b_searchCtrl\b'):
  insert_bits.append('  final TextEditingController _searchCtrl = TextEditingController();\n')

if not has(r'\b_category\b'):
  insert_bits.append("  String _category = 'Alle';\n")

if not has(r'\b_onlyCampaigns\b'):
  insert_bits.append('  bool _onlyCampaigns = false;\n')

if not has(r'\b_favFirst\b'):
  insert_bits.append('  bool _favFirst = false;\n')

if not has(r'\b_fav\b'):
  insert_bits.append('  final Set<String> _fav = <String>{};\n')

# Sett inn feltene rett etter class { linja
if insert_bits:
  s = re.sub(
    r'(class\s+_EbShoppingPageState\s+extends\s+State<EbShoppingPage>\s*\{\s*)',
    r'\1\n' + ''.join(insert_bits) + '\n',
    s,
    count=1
  )

# --- initState ---
if "void initState()" in s:
  # hvis initState finnes men ikke setter _futureShops
  if "_futureShops" in s and re.search(r'initState\([\s\S]*?_futureShops\s*=\s*_load\(\)\s*;', s) is None:
    s = re.sub(
      r'(void\s+initState\(\)\s*\{\s*\n\s*super\.initState\(\);\s*\n)',
      r'\1    _futureShops = _load();\n',
      s,
      count=1
    )
else:
  # lag initState
  s = re.sub(
    r'(class\s+_EbShoppingPageState\s+extends\s+State<EbShoppingPage>\s*\{\s*)',
    r'\1\n  @override\n  void initState() {\n    super.initState();\n    _futureShops = _load();\n  }\n\n',
    s,
    count=1
  )

# --- dispose: sørg for _searchCtrl.dispose() ---
if "void dispose()" in s:
  if "_searchCtrl.dispose()" not in s:
    s = re.sub(
      r'(void\s+dispose\(\)\s*\{\s*\n)',
      r'\1    _searchCtrl.dispose();\n',
      s,
      count=1
    )
else:
  # legg til dispose rett før første @override Widget build (best effort)
  s = re.sub(
    r'(\n\s*@override\s*\n\s*Widget\s+build\s*\()',
    r'\n  @override\n  void dispose() {\n    _searchCtrl.dispose();\n    super.dispose();\n  }\n\1',
    s,
    count=1
  )

# --- FutureBuilder: future: _load() -> future: _futureShops ---
s = re.sub(r'future:\s*_load\(\)\s*,', 'future: _futureShops,', s)

# --- Hvis FutureBuilder generics matcher gammel "List<Map...>" men _load er annerledes:
# Vi lar det være; Dart aksepterer ofte uten generics, og formatter rydder.
# (Hvis du har eksplisitt FutureBuilder<List<Map...>> kan det gi mismatch, men da patcher vi neste.)
p.write_text(s, encoding="utf-8")
print("Patched eb_shopping_page.dart")
print("Detected _load return inner type:", load_inner)
PY

dart format lib/pages/eb_shopping_page.dart
flutter analyze
