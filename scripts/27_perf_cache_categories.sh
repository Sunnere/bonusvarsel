#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python3 - "$FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Legg inn cache-felt hvis ikke finnes
if "_categoriesCache" not in s:
  # prøv å sette nær filter-cache feltene
  s = re.sub(r"(String\s+_filterCacheKey\s*=.*;\s*\n)",
             r"\1  List<String> _categoriesCache = const <String>['Alle'];\n  int _categoriesCacheSourceLen = -1;\n",
             s, count=1)

# Legg inn/erstatt en helper som bygger categories og cacher på lengde
if "List<String> _getCategoriesCached(" not in s:
  s = re.sub(r"(List<String>\s+_buildCategories\([^\)]*\)\s*\{)",
             "List<String> _getCategoriesCached(List<ShopOffer> data) {\n"
             "    if (_categoriesCacheSourceLen == data.length && _categoriesCache.isNotEmpty) {\n"
             "      return _categoriesCache;\n"
             "    }\n"
             "    final set = <String>{'Alle'};\n"
             "    for (final it in data) {\n"
             "      final c = _categoryOf(it).trim();\n"
             "      if (c.isNotEmpty) set.add(c);\n"
             "    }\n"
             "    final out = set.toList()..sort((a,b)=>a.toLowerCase().compareTo(b.toLowerCase()));\n"
             "    _categoriesCache = out;\n"
             "    _categoriesCacheSourceLen = data.length;\n"
             "    return out;\n"
             "  }\n\n"
             "\\1",
             s, count=1)

p.write_text(s, encoding="utf-8")
PY

dart format "$FILE" || true
flutter analyze || true
