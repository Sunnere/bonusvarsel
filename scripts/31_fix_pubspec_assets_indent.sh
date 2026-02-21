#!/usr/bin/env bash
set -euo pipefail

FILE="pubspec.yaml"
if [[ ! -f "$FILE" ]]; then
  echo "Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "$FILE.bak.$(date +%s)"

echo "=== Før (linje 45-80) ==="
nl -ba "$FILE" | sed -n '45,80p'

python3 - "$FILE" <<'PY'
import sys, re, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8").replace("\t", "  ")

# Fiks vanligste: assets er feil-indented etter uses-material-design
# uses-material-design: true
#     assets:
s = re.sub(
    r"(?m)^(\s*uses-material-design:\s*true\s*)\n(\s{4,}assets:\s*)$",
    r"\1\n  assets:",
    s
)

# Fiks: assets ligger under flutter men med 4 mellomrom (skal ofte være 2)
# flutter:
#     assets:
s = re.sub(
    r"(?m)^(flutter:\s*)\n(\s{4,}assets:\s*)$",
    r"\1\n  assets:",
    s
)

# Hvis assets finnes men mangler '-' (liste), så lar vi det være (du må ha -)
# Vi patcher ikke aggressivt her uten å se innholdet.

p.write_text(s, encoding="utf-8")
print("✅ Patch forsøkt (indent/tabs).")
PY

echo "=== Etter (linje 45-80) ==="
nl -ba "$FILE" | sed -n '45,80p'

echo "=== Test pub get ==="
flutter pub get
