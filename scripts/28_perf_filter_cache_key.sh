#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python3 - "$FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Finn _applyFilters og gi den cache-key basert på inputs
pat = r"List<ShopOffer>\s+_applyFilters\(\s*List<ShopOffer>\s+data\s*\)\s*\{.*?\n\s*\}"
m = re.search(pat, s, flags=re.S)
if m:
  repl = (
    "List<ShopOffer> _applyFilters(List<ShopOffer> data) {\n"
    "    final q = _searchCtrl.text.trim().toLowerCase();\n"
    "    final key = '${data.length}|$q|$_category|$_onlyCampaigns|$_favFirst|$_sortByRate|$_isPremium|$_freeLimit';\n"
    "    if (_filterCacheKey == key && _filterCacheSourceLen == data.length && _filterCache.isNotEmpty) {\n"
    "      return _filterCache;\n"
    "    }\n"
    "\n"
    "    var list = data;\n"
    "    if (q.isNotEmpty) {\n"
    "      list = list.where((it) => _nameOf(it).toLowerCase().contains(q)).toList();\n"
    "    } else {\n"
    "      list = list.toList();\n"
    "    }\n"
    "\n"
    "    if (_category != 'Alle') {\n"
    "      list = list.where((it) => _categoryOf(it) == _category).toList();\n"
    "    }\n"
    "    if (_onlyCampaigns) {\n"
    "      list = list.where((it) => _isCampaignOf(it)).toList();\n"
    "    }\n"
    "\n"
    "    if (_sortByRate) {\n"
    "      list.sort((a, b) {\n"
    "        final r = _rateOf(b).compareTo(_rateOf(a));\n"
    "        if (r != 0) return r;\n"
    "        return _nameOf(a).toLowerCase().compareTo(_nameOf(b).toLowerCase());\n"
    "      });\n"
    "    } else if (_favFirst) {\n"
    "      // behold rekkefølge – favoritt-rad sorteres evt annet sted hvis du har det\n"
    "    }\n"
    "\n"
    "    _filterCacheKey = key;\n"
    "    _filterCacheSourceLen = data.length;\n"
    "    _filterCache = list;\n"
    "    return list;\n"
    "  }"
  )
  s = re.sub(pat, repl, s, flags=re.S)

p.write_text(s, encoding="utf-8")
PY

dart format "$FILE" || true
flutter analyze || true
