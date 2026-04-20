#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_alerts_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_868.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_alerts_page.dart")
text = p.read_text()
original = text

repls = [
    (
        "padding: const EdgeInsets.all(16),",
        "padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),"
    ),
    (
        "padding: const EdgeInsets.all(18),",
        "padding: const EdgeInsets.all(20),"
    ),
    (
        "padding: const EdgeInsets.all(14),",
        "padding: const EdgeInsets.all(16),"
    ),
    (
        "fontSize: 20,",
        "fontSize: 22,"
    ),
    (
        "fontSize: 16,",
        "fontSize: 17,"
    ),
]

changed = 0
for old, new in repls:
    if old in text:
        text = text.replace(old, new, 1)
        changed += 1

old_hero = """          const Text(
            'Aktive bonusvarsler',
            style: TextStyle(
              color: Color(0xFFECFDF5),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Se hvilke kampanjer som er valgt akkurat nå, og få rask oversikt over de mest relevante bonusmulighetene.',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
"""
new_hero = """          const Text(
            'Aktive bonusvarsler',
            style: TextStyle(
              color: Color(0xFFECFDF5),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Følg de viktigste bonuskampanjene akkurat nå, og få en enkel oversikt over varsler som er valgt ut som mest relevante.',
            style: TextStyle(
              color: Color(0xFFD1FAE5),
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
"""
if old_hero in text:
    text = text.replace(old_hero, new_hero, 1)
    changed += 1

old_empty = """          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Oppdater varsler'),
          ),
"""
new_empty = """          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Oppdater varsler'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
"""
if old_empty in text:
    text = text.replace(old_empty, new_empty, 1)
    changed += 1

if text == original or changed == 0:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print(f"✅ Gjorde {changed} screenshot-klare UI-endringer i alerts-siden")
PY

flutter analyze
echo "✅ 868 ferdig"
