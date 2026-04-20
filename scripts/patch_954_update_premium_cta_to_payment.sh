#!/bin/bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
BACKUP="${FILE}.bak_954_update_premium_cta_to_payment_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"

python3 - <<'PY'
from pathlib import Path

path = Path("lib/pages/premium_page.dart")
text = path.read_text()

old = """                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: const Color(0xFF111111),
                              textStyle: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            onPressed: () => _checkout(_selected),
                            child: Text(_selected == 'Elite' ? 'Elite' : 'Premium'),
                          ),
"""

new = """                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: const Color(0xFF111111),
                              textStyle: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            onPressed: () => _checkout(_selected),
                            child: Text(
                              _selected == 'Elite'
                                  ? 'Fortsett til betaling • Elite'
                                  : 'Fortsett til betaling • Premium',
                            ),
                          ),
"""

if old not in text:
    raise SystemExit("Fant ikke CTA-blokken i premium_page.dart. Avbryter.")

text = text.replace(old, new, 1)
path.write_text(text)
print("OK")
PY

echo "✅ Oppdaterte CTA i premium_page.dart"
echo "✅ Backup laget: $BACKUP"
echo
echo "Kjør nå:"
echo "  flutter analyze"
