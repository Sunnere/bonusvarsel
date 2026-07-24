#!/bin/bash
set -euo pipefail

FILE="functions/index.js"
BACKUP="${FILE}.bak_1005_fix_thinking_block_$(date +%Y%m%d_%H%M%S)"

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

old = '''      const result = await response.json();
      console.log("[callClaude] suksess");
      return { content: result.content[0].text };'''

new = '''      const result = await response.json();
      // claude-sonnet-5 kan returnere en "thinking"-blokk FØR selve tekstsvaret.
      // Hent riktig blokk basert på type, ikke bare første element i listen -
      // ellers blir "content" null/undefined og appen krasjer med en type-cast-feil.
      const textBlock = (result.content || []).find((b) => b.type === "text");
      if (!textBlock) {
        console.error("[callClaude] Fant ingen tekstblokk i svaret", { content: result.content });
        throw new functions.https.HttpsError("internal", "Claude returnerte ingen tekst.");
      }
      console.log("[callClaude] suksess");
      return { content: textBlock.text };'''

if old not in src:
    print("❌ Fant ikke forventet kodeblokk. Ingen endringer gjort.")
    sys.exit(1)

src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ callClaude henter nå riktig tekstblokk (håndterer 'thinking'-blokker fra claude-sonnet-5)")
PYEOF

echo
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser:"
echo "  node --check $FILE"
echo
echo "Deploy:"
echo "  firebase deploy --only functions:callClaude"
