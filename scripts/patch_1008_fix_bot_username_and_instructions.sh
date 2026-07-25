#!/bin/bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_alerts_page.dart"
BACKUP="${FILE}.bak_1008_fix_bot_instructions_$(date +%Y%m%d_%H%M%S)"

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

old = '''              _step("1", "Åpne Telegram og søk etter @bonusvarsel_bot"),
              _step("2", "Trykk Start (eller send /start til boten)"),
              _step("3", "Skriv inn @bonusvarsel_bot i feltet under"),
              _step("4", "Trykk Lagre – du er klar! 🎉"),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 8),
              const Text("🇬🇧 English",
                  style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              _step("1", "Open Telegram and search for @bonusvarsel_bot"),
              _step("2", "Tap Start (or send /start to the bot)"),
              _step("3", "Enter @bonusvarsel_bot in the field below"),
              _step("4", "Tap Save – you're all set! 🎉"),'''

new = '''              _step("1", "Åpne Telegram og søk etter @bonusvarsel_varsel_bot"),
              _step("2", "Trykk Start (eller send /start til boten)"),
              _step("3", "Skriv inn DITT EGET Telegram-brukernavn i feltet under"),
              _step("4", "Trykk Lagre – du er klar! 🎉"),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 8),
              const Text("🇬🇧 English",
                  style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              _step("1", "Open Telegram and search for @bonusvarsel_varsel_bot"),
              _step("2", "Tap Start (or send /start to the bot)"),
              _step("3", "Enter YOUR OWN Telegram username in the field below"),
              _step("4", "Tap Save – you're all set! 🎉"),'''

if old not in src:
    print("❌ Fant ikke forventet hjelpetekst-blokk. Ingen endringer gjort.")
    sys.exit(1)

src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ Riktig bot-navn (@bonusvarsel_varsel_bot) og riktig instruks (brukerens EGET brukernavn) satt inn")
PYEOF

echo
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser:"
echo "  grep -n 'bonusvarsel_varsel_bot\\|EGET Telegram' $FILE"
echo "  flutter analyze"
