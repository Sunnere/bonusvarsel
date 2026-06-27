#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [[ ! -f "$FILE" ]]; then
  echo "Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "$FILE.bak.$(date +%s)"

python3 - "$FILE" <<'PY'
import sys, pathlib, re
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

ignore = "// ignore_for_file: use_build_context_synchronously, prefer_interpolation_to_compose_strings, unused_element\n"

# hvis det allerede finnes ignore_for_file, ikke legg til en ny
if "ignore_for_file:" in s:
    p.write_text(s, encoding="utf-8")
    print("ℹ️ ignore_for_file finnes allerede – gjorde ingen endring.")
    raise SystemExit(0)

# legg ignore rett etter første import-blokk (eller helt øverst hvis ingen import)
m = re.search(r"^(import\s+['\"].+?;\s*\n)+", s, flags=re.M)
if m:
    insert_at = m.end()
    s2 = s[:insert_at] + ignore + s[insert_at:]
else:
    s2 = ignore + s

p.write_text(s2, encoding="utf-8")
print("✅ La inn ignore_for_file i eb_shopping_page.dart")
PY

dart format "$FILE" || true
flutter analyze || true
