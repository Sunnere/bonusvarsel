#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_861.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()
original = text

# 1. Import alerts page
if "bonusvarsel_alerts_page.dart" not in text:
    text = text.replace(
        "import '../services/api_service.dart';\n",
        "import '../services/api_service.dart';\nimport 'bonusvarsel_alerts_page.dart';\n",
        1,
    )

# 2. Finn et trygt sted å legge knapp (øverst i listen etter intro)
marker = "const SizedBox(height: 16),\n          _devHubBuildInfoCard(),"
insert = """const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFECFDF5),
              border: Border.all(color: const Color(0xFF34D399)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Varsler (sluttbruker-visning)',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BonusvarselAlertsPage(),
                      ),
                    );
                  },
                  child: const Text('Åpne alerts-side'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _devHubBuildInfoCard(),"""

if marker not in text:
    raise SystemExit("❌ Fant ikke riktig sted å injecte alerts-knapp")

text = text.replace(marker, insert, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ Alerts-side koblet via Dev Hub")
PY

flutter analyze
echo "✅ 861 ferdig"
