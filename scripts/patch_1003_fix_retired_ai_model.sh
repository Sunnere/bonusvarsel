#!/bin/bash
set -euo pipefail

FILE="functions/index.js"
BACKUP="${FILE}.bak_1003_fix_retired_model_$(date +%Y%m%d_%H%M%S)"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE. Kjør dette scriptet fra rot-mappen i repoet."
  exit 1
fi

cp "$FILE" "$BACKUP"

python3 - "$FILE" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

old = '''    const { messages, model = "claude-sonnet-4-5", maxTokens = 1000 } = request.data;
    const fetch = require("node-fetch");'''

new = '''    const { messages, maxTokens = 1000 } = request.data;
    // NB: bruker ALLTID en fast, aktiv modell server-side her - ignorerer evt.
    // modellstreng fra klienten. "claude-sonnet-4-5" ble pensjonert av Anthropic
    // 18. mai 2026, og gamle app-versjoner kan fortsatt sende den gamle strengen.
    const model = "claude-sonnet-5";
    const fetch = require("node-fetch");'''

if old not in src:
    print("❌ Fant ikke forventet kodeblokk. Ingen endringer gjort.")
    sys.exit(1)

src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ callClaude bruker nå 'claude-sonnet-5' (aktiv modell) i stedet for den pensjonerte 'claude-sonnet-4-5'")
PYEOF

echo
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser:"
echo "  node --check $FILE"
echo "  grep -n 'claude-sonnet-5' $FILE"
echo
echo "Deploy (fra rot-mappen, krever at du er logget inn med 'firebase login'):"
echo "  firebase deploy --only functions:callClaude"
