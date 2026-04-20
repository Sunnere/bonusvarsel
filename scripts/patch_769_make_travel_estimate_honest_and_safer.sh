#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/pages/travel_page.dart"

echo "==> patch_769_make_travel_estimate_honest_and_safer"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_769_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
report = []

# 1) Replace helper text to be more honest
text = text.replace(
    """    final cardHelp = cardName.isEmpty
        ? 'Gå til "Kort" og velg et kort'
        : 'Valgt kort: $cardName • $_cardRatePer100 poeng per 100 kr';""",
    """    final cardHelp = cardName.isEmpty
        ? 'Gå til "Kort" og velg et kort for et mer realistisk estimat'
        : 'Valgt kort: $cardName • $_cardRatePer100 poeng per 100 kr';"""
)
report.append("oppdaterte hjelpetekst for kortvalg")

# 2) Replace placeholder estimate logic
pattern = r"""  int _estimatePoints\(double amountNok\) \{
    const basePer100 = 5\.0; // placeholder base-rate
    final base = \(amountNok / 100\.0\) \* basePer100;
    final card = \(amountNok / 100\.0\) \* _cardRatePer100;
    return \(base \+ card\)\.round\(\);
  \}"""

replacement = """  int _estimatePoints(double amountNok) {
    if (amountNok <= 0) return 0;

    // Foreløpig trygt estimat:
    // Vi bruker valgt korts sats når kort faktisk er valgt.
    // Bonusprogram-valget brukes ennå ikke til en fullverdig, programspesifikk beregning.
    if (_cardRatePer100 <= 0) return 0;

    final card = (amountNok / 100.0) * _cardRatePer100;
    return card.round();
  }"""

text, n = re.subn(pattern, replacement, text)
if n:
    report.append("erstattet placeholder-beregning med tryggere kortbasert estimat")
else:
    report.append("ADVARSEL: fant ikke _estimatePoints-blokken eksakt")

# 3) Make label more honest
text = text.replace(
    "'Estimert opptjening'",
    "'Foreløpig estimat'"
)
report.append("endrede label fra 'Estimert opptjening' til 'Foreløpig estimat'")

path.write_text(text)
Path("lib/paywall/_patch_769_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/paywall/_patch_769_report.txt || true

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) test Reise-siden uten kort valgt"
echo "3) test Reise-siden med kort valgt"
