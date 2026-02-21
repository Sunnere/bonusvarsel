#!/usr/bin/env bash
set -euo pipefail

FILE="lib/main.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/main.dart")
s = p.read_text(encoding="utf-8")

# Fjern duplicate named parameters i ThemeData
params = ["surface:", "cardTheme:", "listTileTheme:", "inputDecorationTheme:"]

for param in params:
    matches = list(re.finditer(param, s))
    if len(matches) > 1:
        # Behold første, fjern resten
        first = matches[0].start()
        s = s[:first] + s[first:].replace(param, "", len(matches)-1)

p.write_text(s, encoding="utf-8")
print("✅ Fjernet duplicate ThemeData-parametere")
PY

echo "== FORMAT =="
dart format lib/main.dart

echo "== ANALYZE =="
flutter analyze

echo "== RUN =="
kill $(lsof -ti :8080) 2>/dev/null || true
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
