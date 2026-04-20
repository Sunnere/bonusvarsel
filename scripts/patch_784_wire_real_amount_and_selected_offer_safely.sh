#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_784_wire_real_amount_and_selected_offer_safely"

TARGET="lib/pages/eb_shopping_page.dart"
WIDGET="lib/widgets/best_recommendation_card.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

if [ ! -f "$WIDGET" ]; then
  echo "❌ Fant ikke $WIDGET"
  echo "Kjør først patch_783."
  exit 1
fi

cp "$TARGET" "$TARGET.bak_784_$(date +%Y%m%d_%H%M%S)"
cp "$WIDGET" "$WIDGET.bak_784_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

widget_path = Path("lib/widgets/best_recommendation_card.dart")
widget = widget_path.read_text()
wreport = []

# 1) make sure widget forwards currentSelection into engine
if "currentSelection: currentSelection," not in widget:
    widget = widget.replace(
        "              favoriteIds: state.favoriteIds,\n            );",
        "              favoriteIds: state.favoriteIds,\n"
        "              currentSelection: currentSelection,\n"
        "            );",
        1,
    )
    wreport.append("wiret currentSelection inn i BonusRecommendationEngine")

widget_path.write_text(widget)
Path("lib/services/_patch_784_widget_report.txt").write_text("\n".join(wreport) + "\n")

page_path = Path("lib/pages/eb_shopping_page.dart")
text = page_path.read_text()
report = []

# 2) add local selection state safely
state_marker = "class _EbShoppingPageState extends State<EbShoppingPage> {"
if "_currentRecommendationSelection" not in text and state_marker in text:
    insertion = """

  Map<String, dynamic>? _currentRecommendationSelection;

"""
    text = text.replace(state_marker, state_marker + insertion, 1)
    report.append("la til _currentRecommendationSelection state")

# 3) try to detect a real amount source already present in page
amount_expr = None
amount_candidates = [
    r"_shoppingAmount",
    r"_amountCtrl",
    r"_purchaseAmount",
    r"_selectedAmount",
    r"_simAmount",
    r"_amount",
]
for cand in amount_candidates:
    if re.search(rf"\b{cand}\b", text):
        amount_expr = cand
        break

if amount_expr is None:
    amount_expr = "5000"
    report.append("fant ikke ekte shopping-beløp i eb_shopping_page.dart; beholdt 5000 som trygg fallback")
else:
    report.append(f"fant mulig beløpskilde: {amount_expr}")

# 4) replace SmartBestRecommendationCard block to pass currentSelection + amount expr
pattern = re.compile(
    r"""SmartBestRecommendationCard\(
                futureOffers:\s*_futureShops,
                amountNok:\s*[^,]+,
                onTapPaywall:\s*\(\)\s*=>\s*_openPremiumPage\(context\),
              \),""",
    re.DOTALL,
)

replacement = f"""SmartBestRecommendationCard(
                futureOffers: _futureShops,
                amountNok: {amount_expr},
                currentSelection: _currentRecommendationSelection,
                onTapPaywall: () => _openPremiumPage(context),
              ),"""

text2, n = pattern.subn(replacement, text, count=1)
if n:
    text = text2
    report.append("oppdaterte recommendation-widget med amountNok + currentSelection")
else:
    report.append("ADVARSEL: fant ikke eksisterende SmartBestRecommendationCard-kall")

# 5) try to wire selected offer from a tap callback in a very narrow, safe way
tap_patterns = [
    (
        r"(onTap:\s*\(\)\s*\{\s*)([^}]*?_openPremiumPage\(context\);)",
        r"\1setState(() => _currentRecommendationSelection = s.toJson());\n                      \2",
        "wiret valgt offer fra onTap med s.toJson()"
    ),
    (
        r"(onTap:\s*\(\)\s*=>\s*)([^,\n;]+)",
        None,
        "ingen trygg arrow-onTap patch brukt"
    ),
]

patched_tap = False
for p, r, msg in tap_patterns:
    if r is None:
        continue
    text2, n = re.subn(p, r, text, count=1)
    if n:
        text = text2
        report.append(msg)
        patched_tap = True
        break

# 6) safe fallback: if we render list items from variable s, store latest visible item as baseline
if not patched_tap and "_currentRecommendationSelection ??= s.toJson();" not in text:
    fallback_pattern = r"(final rate = _rateOf\(s\);\n)"
    text2, n = re.subn(
        fallback_pattern,
        r"\1                _currentRecommendationSelection ??= s.toJson();\n",
        text,
        count=1,
    )
    if n:
        text = text2
        report.append("la inn trygg fallback: første synlige item brukes som currentSelection")
    else:
        report.append("ADVARSEL: fant ikke trygt sted å wire valgt offer")

page_path.write_text(text)
Path("lib/services/_patch_784_page_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Widget-rapport"
cat lib/services/_patch_784_widget_report.txt || true

echo
echo "==> Page-rapport"
cat lib/services/_patch_784_page_report.txt || true

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) flutter run"
echo "3) åpne EB Shopping og test om recommendation-kortet reagerer bedre"
echo
echo "Merk:"
echo "- hvis rapporten sier fallback 5000, finnes det ikke et tydelig ekte beløp i siden ennå"
echo "- da bør vi legge til et eksplisitt shopping-beløp senere, i stedet for å gjette"
