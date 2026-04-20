#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_825.$(date +%s)"
echo "✅ Backup laget: $FILE"

echo
echo "=== Treffer før endring ==="
grep -n "_diagnosticColor" "$FILE" || {
  echo "❌ Fant ikke _diagnosticColor"
  exit 1
}

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

needle = "  Color _diagnosticColor("
start = text.find(needle)
if start == -1:
    raise SystemExit("❌ Fant ikke _diagnosticColor-signaturen")

brace_start = text.find("{", start)
if brace_start == -1:
    raise SystemExit("❌ Fant ikke start-brace for _diagnosticColor")

depth = 0
end = None
for i in range(brace_start, len(text)):
    ch = text[i]
    if ch == "{":
        depth += 1
    elif ch == "}":
        depth -= 1
        if depth == 0:
            end = i
            break

if end is None:
    raise SystemExit("❌ Fant ikke slutt-brace for _diagnosticColor")

remove_to = end + 1
while remove_to < len(text) and text[remove_to] == "\n":
    remove_to += 1

removed = text[start:remove_to]
new_text = text[:start] + text[remove_to:]
p.write_text(new_text)

print("✅ Fjernet _diagnosticColor()")
print("--- START FJERNET UTSNITT ---")
print(removed[:500])
print("--- SLUTT FJERNET UTSNITT ---")
PY

echo
flutter analyze
echo "✅ 825 ferdig"
