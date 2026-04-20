#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/pages/eb_shopping_page.dart"

echo "==> patch_777_wire_recommendations_into_eb_shopping"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_777_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()
report = []

# 1 IMPORTS
imports = [
    "import '../services/bonus_recommendation_engine.dart';",
    "import '../models/bonus_recommendation.dart';",
]
for imp in imports:
    if imp not in text:
        text = imp + "\n" + text
        report.append(f"la til import {imp}")

# 2 STATE
if "_recommendations" not in text:
    insert_point = "class _EbShoppingPageState extends State<EbShoppingPage> {"
    replacement = insert_point + """

  List<BonusRecommendation> _recommendations = [];
  BonusRecommendation? _bestRecommendation;

"""
    text = text.replace(insert_point, replacement)
    report.append("la til recommendation state")

# 3 BUILD RECOMMENDATIONS
if "_buildRecommendations()" not in text:
    method = """

  void _buildRecommendations(List items) {
    try {
      final recs = BonusRecommendationEngine.recommendForShopping(
        offers: items.cast<Map<String, dynamic>>(),
        amountNok: 5000, // midlertidig
        selectedCardId: null,
        tier: 'free',
        favoriteIds: const {},
      );

      setState(() {
        _recommendations = recs;
        _bestRecommendation = recs.isNotEmpty ? recs.first : null;
      });
    } catch (e) {
      // fail silently
    }
  }

"""
    text = text.replace("initState() {", "initState() {" + method)
    report.append("la til _buildRecommendations")

# 4 CALL AFTER LOAD
text, n = re.subn(
    r"(setState\(\(\) \{[^}]*items = [^;]+;)",
    r"\1\n      _buildRecommendations(items);",
    text,
    count=1,
)
if n:
    report.append("koblet recommendations etter data load")

# 5 UI INSERT
if "Beste valg basert på ditt bruk" not in text:
    ui = """

      if (_bestRecommendation != null)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1F3A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2D4D7A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⭐ Beste valg basert på ditt bruk',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _bestRecommendation!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _bestRecommendation!.subtitle,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${_bestRecommendation!.estimatedPoints} poeng',
                    style: const TextStyle(
                      color: Color(0xFF8CFF64),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if ((_bestRecommendation!.upliftVsCurrent ?? 0) > 0)
                    Text(
                      '+${_bestRecommendation!.upliftVsCurrent} vs vanlig',
                      style: const TextStyle(
                        color: Color(0xFFFFC44D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

"""
    text = text.replace("return Scaffold(", "return Scaffold(" + ui)
    report.append("la til beste valg UI")

path.write_text(text)
Path("lib/services/_patch_777_report.txt").write_text("\n".join(report))
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/services/_patch_777_report.txt || true

echo
echo "Neste:"
echo "1) flutter analyze"
echo "2) åpne EB Shopping"
echo "3) se 'Beste valg' øverst"
