#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_869.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()
original = text

# sørg for import
if "bonusvarsel_alerts_page.dart" not in text:
    text = text.replace(
        "import '../services/api_service.dart';\n",
        "import '../services/api_service.dart';\nimport 'bonusvarsel_alerts_page.dart';\n",
        1
    )

# legg til AppBar action
old = """appBar: AppBar(
        title: const Text('Dev Hub'),
      ),"""

new = """appBar: AppBar(
        title: const Text('Dev Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Varsler',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BonusvarselAlertsPage(),
                ),
              );
            },
          ),
        ],
      ),"""

if old not in text:
    raise SystemExit("❌ Fant ikke AppBar å oppdatere")

text = text.replace(old, new, 1)

if text == original:
    raise SystemExit("❌ Ingen endring gjort")

p.write_text(text)
print("✅ Alerts-knapp lagt til i AppBar")
PY

flutter analyze
echo "✅ 869 ferdig"
