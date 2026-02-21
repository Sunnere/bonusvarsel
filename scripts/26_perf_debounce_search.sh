#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python3 - "$FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# 1) Sørg for dart:async import
if "import 'dart:async';" not in s:
  s = re.sub(r"^import\s+'dart:async';\s*\n", "import 'dart:async';\n", s, flags=re.M)
  # legg før første flutter/material import hvis mulig
  s = re.sub(r"^(import\s+'package:flutter/)", "import 'dart:async';\n\n\\1", s, flags=re.M)

# 2) Finn PRO performance-blokken og sikre debounce-felt + handler
# Vi bruker marker som du allerede har i filen:
#   // PRO performance: debounce + filter cache
marker = r"//\s*PRO performance:\s*debounce\s*\+\s*filter cache"
m = re.search(marker, s)
if not m:
  # fallback: legg felt nær _searchCtrl hvis den finnes
  pass

# 2a) Legg inn felt om de mangler
if "_searchDebounce" not in s:
  s = re.sub(marker,
             lambda mm: mm.group(0) + "\n  Timer? _searchDebounce;\n",
             s, count=1)

# 2b) Definer _onSearchChanged hvis den mangler
if "void _onSearchChanged()" not in s:
  insert_after = marker
  # prøv å legge etter marker/feltblokk
  s = re.sub(insert_after,
             lambda mm: mm.group(0) + "\n\n  void _onSearchChanged() {\n"
                                     "    _searchDebounce?.cancel();\n"
                                     "    _searchDebounce = Timer(const Duration(milliseconds: 180), () {\n"
                                     "      if (!mounted) return;\n"
                                     "      setState(() {\n"
                                     "        // invalidér filter-cache når søk endrer seg\n"
                                     "        _filterCacheKey = '';\n"
                                     "      });\n"
                                     "    });\n"
                                     "  }\n",
             s, count=1)

# 3) Koble listener i initState (hvis ikke)
# Finn initState body
if "initState()" in s and "_searchCtrl.addListener(_onSearchChanged)" not in s:
  s = re.sub(r"@override\s+void\s+initState\(\)\s*\{\s*\n",
             "@override\n  void initState() {\n    super.initState();\n",
             s, count=1)
  # legg inn etter super.initState();
  s = re.sub(r"super\.initState\(\);\s*\n",
             "super.initState();\n    _searchCtrl.addListener(_onSearchChanged);\n",
             s, count=1)

# 4) Cancel timer i dispose (hvis ikke)
if "dispose()" in s and "_searchDebounce?.cancel()" not in s:
  # legg inn i starten av dispose-body
  s = re.sub(r"@override\s+void\s+dispose\(\)\s*\{\s*\n",
             "@override\n  void dispose() {\n    _searchDebounce?.cancel();\n",
             s, count=1)

p.write_text(s, encoding="utf-8")
PY

dart format "$FILE" || true
flutter analyze || true
