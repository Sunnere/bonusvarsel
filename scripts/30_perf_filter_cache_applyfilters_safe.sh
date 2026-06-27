#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python3 - "$FILE" <<'PY'
import sys, pathlib

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

needle = "List<ShopOffer> _applyFilters(List<ShopOffer> data)"
i = s.find(needle)
if i == -1:
    raise SystemExit("Fant ikke _applyFilters-signaturen. Sjekk at funksjonen heter akkurat: " + needle)

# finn første { etter signaturen
open_brace = s.find("{", i)
if open_brace == -1:
    raise SystemExit("Fant ikke '{' etter _applyFilters-signaturen.")

# brace match
depth = 0
j = open_brace
while j < len(s):
    ch = s[j]
    if ch == "{":
        depth += 1
    elif ch == "}":
        depth -= 1
        if depth == 0:
            close_brace = j
            break
    j += 1
else:
    raise SystemExit("Fant ikke matchende '}' for _applyFilters.")

replacement = """List<ShopOffer> _applyFilters(List<ShopOffer> data) {
    final q = _searchCtrl.text.trim().toLowerCase();

    // Bygger en stabil cache-key uten Dart $-interpolasjon (robust i scripts)
    final key = data.length.toString() +
        '|' + q +
        '|' + _category +
        '|' + (_onlyCampaigns ? '1' : '0') +
        '|' + (_favFirst ? '1' : '0') +
        '|' + (_sortByRate ? '1' : '0') +
        '|' + (_isPremium ? '1' : '0') +
        '|' + _freeLimit.toString();

    if (_filterCacheKey == key &&
        _filterCacheSourceLen == data.length &&
        _filterCache.isNotEmpty) {
      return _filterCache;
    }

    var list = data.toList();

    if (q.isNotEmpty) {
      list = list
          .where((it) => _nameOf(it).toLowerCase().contains(q))
          .toList();
    }

    if (_category != 'Alle') {
      list = list.where((it) => _categoryOf(it) == _category).toList();
    }

    if (_onlyCampaigns) {
      list = list.where((it) => _isCampaignOf(it)).toList();
    }

    if (_sortByRate) {
      list.sort((a, b) {
        final r = _rateOf(b).compareTo(_rateOf(a));
        if (r != 0) return r;
        return _nameOf(a).toLowerCase().compareTo(_nameOf(b).toLowerCase());
      });
    }

    _filterCacheKey = key;
    _filterCacheSourceLen = data.length;
    _filterCache = list;
    return list;
  }"""

s2 = s[:i] + replacement + s[close_brace+1:]
p.write_text(s2, encoding="utf-8")
print("✅ Patchet _applyFilters (safe brace replace).")
PY

dart format "$FILE" || true
flutter analyze || true
