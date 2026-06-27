#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[ -f "$FILE" ] || { echo "Fant ikke $FILE"; exit 1; }
cp "$FILE" "$FILE.bak.$(date +%s)" || true

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# 0) Sikre dart:async (Timer)
if "import 'dart:async';" not in s:
    s = "import 'dart:async';\n" + s

# 1) Finn State
if "_EbShoppingPageState" not in s:
    raise SystemExit("Fant ikke _EbShoppingPageState i eb_shopping_page.dart")

# 2) Felter (kun hvis de mangler)
if "_filterCacheKey" not in s:
    fields_block = """
  // PRO performance: debounce + filter cache
  Timer? _searchDebounce;
  String _filterCacheKey = '';
  List<ShopOffer> _filterCache = const <ShopOffer>[];
  int _filterCacheSourceLen = -1;
""".rstrip() + "\n"

    m = re.search(r"(final\s+TextEditingController\s+_searchCtrl\s*=\s*TextEditingController\(\)\s*;)", s)
    if m:
        s = s[:m.end()] + "\n" + fields_block + s[m.end():]
    else:
        m2 = re.search(r"(class\s+_EbShoppingPageState\s+extends\s+State<[^>]+>\s*\{)", s)
        if not m2:
            raise SystemExit("Fant ikke header til _EbShoppingPageState")
        s = s[:m2.end()] + "\n" + fields_block + s[m2.end():]

# 3) _onSearchChanged() (kun hvis den mangler)
if "void _onSearchChanged()" not in s:
    method = """
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      // Trigger rebuild -> filter-cache gjør at dette er billig
      setState(() {});
    });
  }
""".rstrip() + "\n"

    anchor = re.search(r"\n\s*Future<.*?>\s+_openUrl\(", s)
    if not anchor:
        anchor = re.search(r"\n\s*@override\s*\n\s*Widget\s+build\(", s)
    if not anchor:
        raise SystemExit("Fant ikke trygt innsettingspunkt for _onSearchChanged()")
    s = s[:anchor.start()] + "\n" + method + s[anchor.start():]

# 4) initState addListener (kun hvis mangler)
if "initState()" in s:
    if "_searchCtrl.addListener(_onSearchChanged)" not in s:
        s2, n = re.subn(
            r"(void\s+initState\(\)\s*\{\s*\n\s*super\.initState\(\)\s*;\s*)",
            r"\1\n    _searchCtrl.addListener(_onSearchChanged);\n",
            s,
            count=1
        )
        s = s2 if n else s
else:
    m = re.search(r"class\s+_EbShoppingPageState\s+extends\s+State<[^>]+>\s*\{", s)
    if not m:
        raise SystemExit("Fant ikke state header for å lage initState")
    init = """
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

""".lstrip()
    s = s[:m.end()] + "\n" + init + s[m.end():]

# 5) dispose: cancel + removeListener + dispose (idempotent)
if "void dispose()" in s:
    if "_searchDebounce?.cancel()" not in s or "_searchCtrl.removeListener(_onSearchChanged)" not in s:
        s = re.sub(
            r"(void\s+dispose\(\)\s*\{\s*)",
            r"\1\n    _searchDebounce?.cancel();\n    _searchCtrl.removeListener(_onSearchChanged);\n",
            s,
            count=1
        )
    if "_searchCtrl.dispose();" not in s:
        # legg inn dispose før super.dispose();
        s = re.sub(r"(super\.dispose\(\)\s*;)", r"_searchCtrl.dispose();\n    \1", s, count=1)
else:
    m = re.search(r"\n\s*@override\s*\n\s*Widget\s+build\(", s)
    if not m:
        raise SystemExit("Fant ikke build() for å sette inn dispose()")
    dispose = """
  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

""".lstrip()
    s = s[:m.start()] + "\n" + dispose + s[m.start():]

# 6) Memoize _applyFilters(List<ShopOffer> data)
pat = r"(List<ShopOffer>\s+_applyFilters\s*\(\s*List<ShopOffer>\s+data\s*\)\s*\{)"
m = re.search(pat, s)
if not m:
    m = re.search(r"(List<ShopOffer>\s+_applyFilters\s*\([^\)]*\)\s*\{)", s)

if m and "if (key == _filterCacheKey" not in s:
    inject = """
    final key =
        '${_searchCtrl.text}|${_category}|${_onlyCampaigns}|${_favFirst}|${_isPremium}|${data.length}';
    if (key == _filterCacheKey && _filterCacheSourceLen == data.length) {
      return _filterCache;
    }
""".rstrip() + "\n"
    s = s[:m.end()] + "\n" + inject + s[m.end():]

    returns = list(re.finditer(r"\n\s*return\s+list\s*;\s*", s))
    if returns:
        last = returns[-1]
        cache_set = """
    _filterCacheKey = key;
    _filterCacheSourceLen = data.length;
    _filterCache = list;
""".rstrip() + "\n"
        s = s[:last.start()] + "\n" + cache_set + s[last.start():]

p.write_text(s, encoding="utf-8")
print("✅ PRO P: debounce + filter-cache patch lagt inn")
PY

dart format lib/pages/eb_shopping_page.dart >/dev/null || true
flutter analyze || true
echo "✅ PRO P ferdig. Restart web-server."
