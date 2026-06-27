#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [[ ! -f "$FILE" ]]; then
  echo "Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "$FILE.bak.$(date +%s)"

python3 - "$FILE" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

if "kDebugMode" not in s:
    print("ℹ️ kDebugMode brukes ikke i filen.")
    raise SystemExit(0)

if "package:flutter/foundation.dart" in s:
    print("ℹ️ foundation.dart er allerede importert.")
    raise SystemExit(0)

# legg til import rett etter material.dart hvis mulig
s2 = re.sub(
    r"(import\s+'package:flutter/material\.dart';\s*\n)",
    r"\1import 'package:flutter/foundation.dart';\n",
    s,
    count=1
)

if s2 == s:
    # fallback: legg øverst etter første import-blokk
    m = re.search(r"^(import\s+['\"].+?;\s*\n)+", s, flags=re.M)
    if m:
        s2 = s[:m.end()] + "import 'package:flutter/foundation.dart';\n" + s[m.end():]
    else:
        s2 = "import 'package:flutter/foundation.dart';\n" + s

p.write_text(s2, encoding="utf-8")
print("✅ La til foundation.dart import for kDebugMode")
PY

dart format "$FILE" || true
flutter analyze || true
