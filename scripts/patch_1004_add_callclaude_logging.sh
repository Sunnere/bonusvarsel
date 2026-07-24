#!/bin/bash
set -euo pipefail

FILE="functions/index.js"
BACKUP="${FILE}.bak_1004_add_logging_$(date +%Y%m%d_%H%M%S)"

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

old = '''exports.callClaude = functions.https.onCall(
  { secrets: ["ANTHROPIC_API_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Logg inn først.");
    }

    const { messages, maxTokens = 1000 } = request.data;
    // NB: bruker ALLTID en fast, aktiv modell server-side her - ignorerer evt.
    // modellstreng fra klienten. "claude-sonnet-4-5" ble pensjonert av Anthropic
    // 18. mai 2026, og gamle app-versjoner kan fortsatt sende den gamle strengen.
    const model = "claude-sonnet-5";
    const fetch = require("node-fetch");

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": process.env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model,
        max_tokens: maxTokens,
        messages,
      }),
    });

    if (!response.ok) {
      const err = await response.text();
      throw new functions.https.HttpsError("internal", `Claude feil: ${err}`);
    }

    const result = await response.json();
    return { content: result.content[0].text };
  }
);'''

new = '''exports.callClaude = functions.https.onCall(
  { secrets: ["ANTHROPIC_API_KEY"] },
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Logg inn først.");
    }

    try {
      const { messages, maxTokens = 1000 } = request.data;
      const model = "claude-sonnet-5";

      console.log("[callClaude] request", {
        hasApiKey: Boolean(process.env.ANTHROPIC_API_KEY),
        model,
        maxTokens,
        messageCount: Array.isArray(messages) ? messages.length : null,
      });

      const fetch = require("node-fetch");

      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": process.env.ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model,
          max_tokens: maxTokens,
          messages,
        }),
      });

      if (!response.ok) {
        const err = await response.text();
        console.error("[callClaude] Anthropic API-feil", {
          status: response.status,
          statusText: response.statusText,
          body: err,
        });
        throw new functions.https.HttpsError("internal", `Claude feil (${response.status}): ${err}`);
      }

      const result = await response.json();
      console.log("[callClaude] suksess");
      return { content: result.content[0].text };
    } catch (e) {
      if (e instanceof functions.https.HttpsError) throw e;
      console.error("[callClaude] Uventet feil", {
        message: e && e.message,
        stack: e && e.stack,
      });
      throw new functions.https.HttpsError("internal", `Uventet feil: ${e && e.message}`);
    }
  }
);'''

if old not in src:
    print("❌ Fant ikke forventet kodeblokk (kanskje patch_1003 ikke ble kjørt først?). Ingen endringer gjort.")
    sys.exit(1)

src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ callClaude logger nå detaljert ved feil (Anthropic-svar, statuskode, og uventede feil/stack)")
PYEOF

echo
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser:"
echo "  node --check $FILE"
echo
echo "Deploy:"
echo "  firebase deploy --only functions:callClaude"
echo
echo "Test AI-funksjonen i appen igjen, vent 10-20 sek, og hent så loggen:"
echo "  firebase functions:log --only callClaude -n 30"
