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

# Fjern fallback bare der det ikke støttes:
# getIsPremium(fallback: X) -> getIsPremium()
s = re.sub(r"\.getIsPremium\(\s*fallback\s*:\s*[^)]+\)", ".getIsPremium()", s)

# debugBadgeEnabled(fallback: X) -> debugBadgeEnabled()
s = re.sub(r"\.debugBadgeEnabled\(\s*fallback\s*:\s*[^)]+\)", ".debugBadgeEnabled()", s)

p.write_text(s, encoding="utf-8")
print("✅ premium_page.dart: fjernet fallback: for getIsPremium/debugBadgeEnabled")
PY

dart format "$FILE" || true
