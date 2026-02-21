#!/usr/bin/env bash
set -euo pipefail

# ------------------ 1) error_handling.dart: legg tilbake dart:async ------------------
EH="lib/app/error_handling.dart"
if [[ -f "$EH" ]]; then
  cp "$EH" "$EH.bak.$(date +%s)"

  python3 - "$EH" <<'PY'
import sys, pathlib, re

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Sørg for nødvendige imports:
need_async = "import 'dart:async';"
need_found = "import 'package:flutter/foundation.dart';"

# Fjern alle eksisterende import-linjer, bygg opp på nytt (trygt og enkelt)
body = "\n".join([ln for ln in s.splitlines() if not ln.strip().startswith("import ") ]).lstrip("\n")

imports = []
imports.append(need_async)
imports.append(need_found)

s2 = "\n".join(imports) + "\n\n" + body
p.write_text(s2, encoding="utf-8")
print("✅ error_handling.dart: la inn dart:async + foundation.dart")
PY

  dart format "$EH" || true
else
  echo "Hopper over: $EH finnes ikke"
fi

# ------------------ 2) main.dart: fjern unused settings_page import ------------------
MAIN="lib/main.dart"
if [[ -f "$MAIN" ]]; then
  cp "$MAIN" "$MAIN.bak.$(date +%s)"
  python3 - "$MAIN" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
s2 = s.replace("import 'pages/settings_page.dart';\n", "")
p.write_text(s2, encoding="utf-8")
print("✅ main.dart: fjernet settings_page import (hvis den fantes)")
PY
  dart format "$MAIN" || true
fi

# ------------------ 3) premium_page.dart: fallback -> bruk getShowBadges/getFreeLimit ------------------
PREM="lib/pages/premium_page.dart"
if [[ -f "$PREM" ]]; then
  cp "$PREM" "$PREM.bak.$(date +%s)"
  python3 - "$PREM" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Bytt showBadges(fallback: X) -> getShowBadges(fallback: X)
s = re.sub(r"\.showBadges\(\s*fallback\s*:", ".getShowBadges(fallback:", s)

# Bytt freeLimit(fallback: X) -> getFreeLimit(fallback: X)
s = re.sub(r"\.freeLimit\(\s*fallback\s*:", ".getFreeLimit(fallback:", s)

# Hvis det finnes debugBadgeEnabled(fallback: ...) la stå (wrapper støtter fallback)
p.write_text(s, encoding="utf-8")
print("✅ premium_page.dart: byttet fallback-kall til getShowBadges/getFreeLimit der det trengs")
PY
  dart format "$PREM" || true
else
  echo "Hopper over: $PREM finnes ikke"
fi

echo "✅ Patch ferdig"
