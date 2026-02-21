#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [[ ! -f "$FILE" ]]; then
  echo "Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "$FILE.bak.$(date +%s)"

python3 - "$FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

def has(name: str) -> bool:
    return re.search(rf"\b{name}\b", s) is not None

changed = False

# 1) Sørg for at _filterKey finnes (om ikke: legg den inn i helper-seksjonen)
if not re.search(r"\bString\s+_filterKey\s*\(", s):
    # Prøv å legge inn etter _applyFilters (eller etter en tydelig helpers header hvis den finnes)
    insert_pos = None
    m = re.search(r"\bList<ShopOffer>\s+_applyFilters\s*\(\s*List<ShopOffer>\s+data\s*\)\s*\{", s)
    if m:
        # sett inn etter hele _applyFilters body (brace-match)
        i = s.find("{", m.end()-1)
        depth = 0
        j = i
        while j < len(s):
            ch = s[j]
            if ch == "{": depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    insert_pos = j + 1
                    break
            j += 1
    if insert_pos is None:
        # fallback: etter første "helpers" kommentar, ellers etter imports
        mh = re.search(r"//\s*-+\s*UI helpers\s*-+\s*\n", s)
        if mh:
            insert_pos = mh.start()
        else:
            mi = re.search(r"^(import\s+['\"].+?;\s*\n)+", s, flags=re.M)
            insert_pos = mi.end() if mi else 0

    helper = (
        "\n\n"
        "  // Perf: samlet cache-key for filter-cache\n"
        "  String _filterKey(List<ShopOffer> data) {\n"
        "    final q = _searchCtrl.text.trim().toLowerCase();\n"
        "    return '${data.length}|$q|$_category|$_onlyCampaigns|$_favFirst|$_sortByRate|$_isPremium|$_freeLimit';\n"
        "  }\n"
    )
    s = s[:insert_pos] + helper + s[insert_pos:]
    changed = True

# 2) Sørg for at _getCategoriesCached finnes (om ikke: legg den inn)
if not re.search(r"\bList<String>\s+_getCategoriesCached\s*\(", s):
    insert_pos = None
    mh = re.search(r"//\s*-+\s*UI helpers\s*-+\s*\n", s)
    if mh:
        insert_pos = mh.end()
    else:
        # legg etter _filterKey hvis den finnes
        mk = re.search(r"\bString\s+_filterKey\s*\(.*?\n\s*\}\s*\n", s, flags=re.S)
        insert_pos = mk.end() if mk else 0

    helper = (
        "\n"
        "  // Perf: cache categories-list (unngår rebuild-kost)\n"
        "  String _categoriesCacheKey = '';\n"
        "  List<String> _categoriesCache = const <String>[];\n"
        "\n"
        "  List<String> _getCategoriesCached(List<ShopOffer> data) {\n"
        "    final key = '${data.length}|${_category}|${_onlyCampaigns}|${_favFirst}|${_sortByRate}';\n"
        "    if (_categoriesCacheKey == key && _categoriesCache.isNotEmpty) return _categoriesCache;\n"
        "    final cats = _buildCategories(data);\n"
        "    _categoriesCacheKey = key;\n"
        "    _categoriesCache = cats;\n"
        "    return cats;\n"
        "  }\n"
    )
    s = s[:insert_pos] + helper + s[insert_pos:]
    changed = True

# 3) Wire _applyFilters til å bruke _filterKey(data)
m = re.search(r"\bList<ShopOffer>\s+_applyFilters\s*\(\s*List<ShopOffer>\s+data\s*\)\s*\{", s)
if m:
    body_start = s.find("{", m.end()-1) + 1
    # ta litt av toppen av body for å patch'e nøkkel-linjen
    head = s[body_start:body_start+900]

    # A) hvis det finnes "final key = '...';" så bytt til _filterKey(data)
    new_head = re.sub(
        r"final\s+key\s*=\s*['\"].*?['\"]\s*;",
        "final key = _filterKey(data);",
        head,
        flags=re.S
    )
    if new_head != head:
        s = s[:body_start] + new_head + s[body_start+900:]
        changed = True
    else:
        # B) hvis det finnes "final key =" men ikke string, la det være
        if "final key =" not in head:
            # insert rett etter (mulig) q-linje, ellers helt først
            # prøv etter første linje som setter q
            qline = re.search(r"final\s+q\s*=.*?;\n", head)
            ins_at = qline.end() if qline else 0
            new_head = head[:ins_at] + ("    final key = _filterKey(data);\n") + head[ins_at:]
            s = s[:body_start] + new_head + s[body_start+900:]
            changed = True

# 4) Wire categories builder call til å bruke cache (dersom vi finner _buildCategories(data) brukt direkte)
# Vanlig pattern: final categories = _buildCategories(data);
s2 = re.sub(r"(_buildCategories\s*\(\s*data\s*\))", r"_getCategoriesCached(data)", s)
if s2 != s:
    s = s2
    changed = True

p.write_text(s, encoding="utf-8")
print("✅ Perf wire-up: _filterKey + _getCategoriesCached koblet på" if changed else "ℹ️ Ingen endringer nødvendig")
PY

dart format "$FILE" || true
flutter analyze || true
