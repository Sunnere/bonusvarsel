#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/pages/travel_page.dart"

echo "==> patch_797_wire_travel_value_card_exact"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_797_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

path = Path("lib/pages/travel_page.dart")
text = path.read_text()

old = """              Text(
                '$estPoints poeng',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
"""

new = """              Text(
                '$estPoints poeng',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),
              if (_selectedCardId == null) ...[
                const SizedBox(height: 10),
                Text(
                  'Velg et kort i "Kort"-siden for mer presis beregning.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
"""

if old not in text:
    raise SystemExit("❌ Fant ikke eksakt punkt å sette inn TravelValueCard")

text = text.replace(old, new, 1)
path.write_text(text)
print("✅ La inn TravelValueCard rett under poeng-estimatet")
PY

echo
echo "==> Verifisering"
sed -n '1,220p' "$TARGET"

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) flutter run"
echo "3) åpne Reise-siden og test med/uten valgt kort"
