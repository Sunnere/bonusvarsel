#!/usr/bin/env bash
set -euo pipefail

patch_const_constructor_cards() {
  local FILE="lib/pages/cards_page.dart"
  [[ -f "$FILE" ]] || return 0
  cp "$FILE" "$FILE.bak.$(date +%s)" || true

  python3 - "$FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Gjør constructor const hvis den finnes
# CardsPage({super.key});
s2 = re.sub(r"(\n\s*)(CardsPage)\(\{super\.key\}\);", r"\1const \2({super.key});", s, count=1)

# også håndter evt: CardsPage({Key? key}) : super(key: key);
s2 = re.sub(r"(\n\s*)(CardsPage)\(\{([^}]*)\}\)\s*:\s*super\(([^)]*)\);\s*",
            lambda m: f"{m.group(1)}const {m.group(2)}({{{m.group(3)}}}) : super({m.group(4)});\n",
            s2, count=1)

if s2 != s:
    p.write_text(s2, encoding="utf-8")
    print("✅ cards_page.dart: constructor gjort const")
else:
    print("ℹ️ cards_page.dart: fant ikke constructor å endre (kan allerede være const)")
PY
}

patch_home_remove_const_list() {
  local FILE="lib/pages/home_page.dart"
  [[ -f "$FILE" ]] || return 0
  cp "$FILE" "$FILE.bak.$(date +%s)" || true

  python3 - "$FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Typisk feil: final pages = const [ ... ];  -> final pages = [ ... ];
# Dette fjerner både "const_with_non_const" og "non_constant_list_element"
s2 = re.sub(r"=\s*const\s*\[", "= [", s)

if s2 != s:
    p.write_text(s2, encoding="utf-8")
    print("✅ home_page.dart: fjernet const foran liste-literal")
else:
    print("ℹ️ home_page.dart: fant ingen '= const [' å endre")
PY
}

patch_premium_kdebug_import() {
  local FILE="lib/pages/premium_page.dart"
  [[ -f "$FILE" ]] || return 0
  cp "$FILE" "$FILE.bak.$(date +%s)" || true

  python3 - "$FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

if "kDebugMode" not in s:
    print("ℹ️ premium_page.dart: kDebugMode brukes ikke (hopper over)")
    raise SystemExit(0)

if "package:flutter/foundation.dart" in s:
    print("ℹ️ premium_page.dart: foundation.dart allerede importert")
    raise SystemExit(0)

# Sett import etter material.dart hvis finnes
s2 = re.sub(
    r"(import\s+['\"]package:flutter/material\.dart['\"];\s*\n)",
    r"\1import 'package:flutter/foundation.dart';\n",
    s,
    count=1
)

# fallback: putt øverst blant imports
if s2 == s:
    m = re.search(r"^(import\s+['\"].+?;\s*\n)+", s, flags=re.M)
    if m:
        s2 = s[:m.end()] + "import 'package:flutter/foundation.dart';\n" + s[m.end():]
    else:
        s2 = "import 'package:flutter/foundation.dart';\n" + s

p.write_text(s2, encoding="utf-8")
print("✅ premium_page.dart: la til import for kDebugMode")
PY
}

patch_const_constructor_cards
patch_home_remove_const_list
patch_premium_kdebug_import

dart format lib/pages/cards_page.dart lib/pages/home_page.dart lib/pages/premium_page.dart || true
flutter analyze || true
