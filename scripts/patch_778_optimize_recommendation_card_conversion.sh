#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/pages/eb_shopping_page.dart"

echo "==> patch_778_optimize_recommendation_card_conversion"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_778_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()
report = []

# 1) Add helper if missing
if "_openRecommendationPaywall()" not in text:
    state_marker = "class _EbShoppingPageState extends State<EbShoppingPage> {"
    helper = """

  void _openRecommendationPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallPreviewPage(),
      ),
    );
  }

"""
    if state_marker in text:
        text = text.replace(state_marker, state_marker + helper, 1)
        report.append("la til _openRecommendationPaywall()")

# 2) Ensure import exists
imp = "import '../paywall/paywall_preview_page.dart';"
if imp not in text:
    imports = list(re.finditer(r"^import .+?;\n", text, flags=re.MULTILINE))
    if imports:
        last = imports[-1]
        text = text[:last.end()] + imp + "\n" + text[last.end():]
    else:
        text = imp + "\n" + text
    report.append("la til paywall-preview import")

# 3) Replace the earlier simple best-card block if present
pattern = re.compile(
    r"""
\s*if\s*\(_bestRecommendation\s*!=\s*null\)\s*
        Container\(
.*?
        \),
""",
    re.DOTALL | re.VERBOSE,
)

replacement = """

      if (_bestRecommendation != null)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1931),
                Color(0xFF102B4F),
                Color(0xFF0C1E38),
              ],
            ),
            border: Border.all(color: const Color(0xFF2F5B92)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2200A3FF),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '⭐ Beste valg akkurat nå',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17365F),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF3E6FB0)),
                    ),
                    child: const Text(
                      'Smart forslag',
                      style: TextStyle(
                        color: Color(0xFF9ED1FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _bestRecommendation!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _bestRecommendation!.subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102842),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF234B77)),
                    ),
                    child: Text(
                      '${_bestRecommendation!.estimatedPoints} poeng',
                      style: const TextStyle(
                        color: Color(0xFF8CFF64),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if ((_bestRecommendation!.upliftVsCurrent ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A2B10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF7A5A1E)),
                      ),
                      child: Text(
                        '+${_bestRecommendation!.upliftVsCurrent} vs vanlig',
                        style: const TextStyle(
                          color: Color(0xFFFFC44D),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (_bestRecommendation!.favorite)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2D20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF365C3F)),
                      ),
                      child: const Text(
                        'Favoritt',
                        style: TextStyle(
                          color: Color(0xFFB8F5A9),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Dette valget kan gi deg mer verdi enn standardvalget ditt.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _openRecommendationPaywall,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF4975B3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Se hvorfor',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _openRecommendationPaywall,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF69AEFF),
                        foregroundColor: const Color(0xFF04152A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Lås opp Premium',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
"""

new_text, n = pattern.subn(replacement, text, count=1)
if n:
    text = new_text
    report.append("oppgraderte Beste valg-kortet til konverteringsversjon")
else:
    report.append("ADVARSEL: fant ikke eksisterende Beste valg-kort å erstatte")

path.write_text(text)
Path("lib/services/_patch_778_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/services/_patch_778_report.txt || true

echo
echo "Neste:"
echo "1) flutter analyze"
echo "2) åpne EB Shopping"
echo "3) test 'Se hvorfor' og 'Lås opp Premium'"
