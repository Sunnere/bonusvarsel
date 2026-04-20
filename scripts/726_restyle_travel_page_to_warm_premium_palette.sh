#!/usr/bin/env bash
set -euo pipefail

echo "==> 726_restyle_travel_page_to_warm_premium_palette"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: lib/pages/travel_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_726")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

palette_helpers = """
  static const Color _travelPageBg = Color(0xFFF7F3EC);
  static const Color _heroOcean = Color(0xFF0F6B73);
  static const Color _heroOceanSoft = Color(0xFFDCEFF0);
  static const Color _sandCard = Color(0xFFF5E7CF);
  static const Color _skyCard = Color(0xFFE7F1F7);
  static const Color _warmCard = Color(0xFFF6EEE3);
  static const Color _highlightGold = Color(0xFFE7C98B);
  static const Color _textDark = Color(0xFF183038);
  static const Color _textSoft = Color(0xFF4F666D);

  TextStyle _sectionTitleStyle(BuildContext context) {
    return (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w800,
      color: _textDark,
    );
  }

  TextStyle _heroTitleStyle(BuildContext context) {
    return (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w900,
      color: Colors.white,
    );
  }

  TextStyle _heroBodyStyle(BuildContext context) {
    return (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: const Color(0xFFEAF7F8),
      height: 1.3,
    );
  }

"""

if "_travelPageBg" not in text:
    anchor = "  @override\n  Widget build(BuildContext context) {\n"
    if anchor not in text:
        print("ERROR: Could not find build anchor for palette helpers")
        raise SystemExit(1)
    text = text.replace(anchor, palette_helpers + "\n" + anchor, 1)

replacements = [
    (
        "    return Scaffold(",
        "    return Scaffold(\n"
        "      backgroundColor: _travelPageBg,",
    ),
    (
        "              Text(\n"
        "                'Familietur-planlegger',\n"
        "                style: Theme.of(context).textTheme.headlineSmall?.copyWith(\n"
        "                      fontWeight: FontWeight.w900,\n"
        "                    ),\n"
        "              ),",
        "              Text(\n"
        "                'Familietur-planlegger',\n"
        "                style: Theme.of(context).textTheme.headlineSmall?.copyWith(\n"
        "                      fontWeight: FontWeight.w900,\n"
        "                      color: _textDark,\n"
        "                    ),\n"
        "              ),",
    ),
    (
        "              Text(\n"
        "                'Planlegg familiebehov, estimer poeng og finn hvilke butikktyper som passer best i appen.',\n"
        "                style: Theme.of(context).textTheme.bodyMedium,\n"
        "              ),",
        "              Text(\n"
        "                'Planlegg familiebehov, estimer poeng og finn hvilke butikktyper som passer best i appen.',\n"
        "                style: Theme.of(context).textTheme.bodyMedium?.copyWith(\n"
        "                      color: _textSoft,\n"
        "                      height: 1.35,\n"
        "                    ),\n"
        "              ),",
    ),
    (
        "              Card(\n"
        "                child: Padding(",
        "              Card(\n"
        "                color: Colors.white,\n"
        "                elevation: 0,\n"
        "                shape: RoundedRectangleBorder(\n"
        "                  borderRadius: BorderRadius.circular(20),\n"
        "                ),\n"
        "                child: Padding(",
    ),
    (
        "              Card(\n"
        "                color: Theme.of(context).colorScheme.primaryContainer,",
        "              Card(\n"
        "                color: _heroOcean,",
    ),
    (
        "                              style: Theme.of(context).textTheme.titleMedium?.copyWith(\n"
        "                                    fontWeight: FontWeight.w900,\n"
        "                                  ),",
        "                              style: _heroTitleStyle(context),",
    ),
    (
        "                      Text(\n"
        "                        'Denne blokken skal være synlig høyt oppe på siden.',\n"
        "                        style: Theme.of(context).textTheme.bodySmall,\n"
        "                      ),",
        "                      Text(\n"
        "                        'Denne blokken skal være synlig høyt oppe på siden.',\n"
        "                        style: _heroBodyStyle(context),\n"
        "                      ),",
    ),
    (
        "                                  decoration: BoxDecoration(\n"
        "                                    color: Theme.of(context).colorScheme.surface,\n"
        "                                    borderRadius: BorderRadius.circular(12),\n"
        "                                  ),",
        "                                  decoration: BoxDecoration(\n"
        "                                    color: Colors.white,\n"
        "                                    borderRadius: BorderRadius.circular(16),\n"
        "                                  ),",
    ),
    (
        "              Card(\n"
        "                color: Theme.of(context).colorScheme.surfaceContainerHighest,",
        "              Card(\n"
        "                color: _sandCard,\n"
        "                elevation: 0,\n"
        "                shape: RoundedRectangleBorder(\n"
        "                  borderRadius: BorderRadius.circular(20),\n"
        "                ),",
    ),
]

for old, new in replacements:
    text = text.replace(old, new)

# targeted section styling
text = text.replace(
    "                      Text(\n"
    "                        'Reiseprofil',\n"
    "                        style: Theme.of(context).textTheme.titleMedium?.copyWith(\n"
    "                              fontWeight: FontWeight.w800,\n"
    "                            ),\n"
    "                      ),",
    "                      Text(\n"
    "                        'Reiseprofil',\n"
    "                        style: _sectionTitleStyle(context),\n"
    "                      ),"
)

text = text.replace(
    "                      Text(\n"
    "                        'SAS EuroBonus-saldo',\n"
    "                        style: Theme.of(context).textTheme.titleMedium?.copyWith(\n"
    "                              fontWeight: FontWeight.w800,\n"
    "                            ),\n"
    "                      ),",
    "                      Text(\n"
    "                        'SAS EuroBonus-saldo',\n"
    "                        style: _sectionTitleStyle(context),\n"
    "                      ),"
)

text = text.replace(
    "                      Text(\n"
    "                        'Planlagt kjøp før reisen',\n"
    "                        style: Theme.of(context).textTheme.titleMedium?.copyWith(\n"
    "                              fontWeight: FontWeight.w800,\n"
    "                            ),\n"
    "                      ),",
    "                      Text(\n"
    "                        'Planlagt kjøp før reisen',\n"
    "                        style: _sectionTitleStyle(context),\n"
    "                      ),"
)

text = text.replace(
    "                      Text(\n"
    "                        'Poengplan for familien',\n"
    "                        style: Theme.of(context).textTheme.titleMedium?.copyWith(\n"
    "                              fontWeight: FontWeight.w800,\n"
    "                            ),\n"
    "                      ),",
    "                      Text(\n"
    "                        'Poengplan for familien',\n"
    "                        style: _sectionTitleStyle(context),\n"
    "                      ),"
)

text = text.replace(
    "                      Text(\n"
    "                        'Anbefalt pakkeliste',\n"
    "                        style: Theme.of(context).textTheme.titleMedium?.copyWith(\n"
    "                              fontWeight: FontWeight.w800,\n"
    "                            ),\n"
    "                      ),",
    "                      Text(\n"
    "                        'Anbefalt pakkeliste',\n"
    "                        style: _sectionTitleStyle(context),\n"
    "                      ),"
)

text = text.replace(
    "                      Text(\n"
    "                        'Butikktyper som passer best',\n"
    "                        style: Theme.of(context).textTheme.titleMedium?.copyWith(\n"
    "                              fontWeight: FontWeight.w800,\n"
    "                            ),\n"
    "                      ),",
    "                      Text(\n"
    "                        'Butikktyper som passer best',\n"
    "                        style: _sectionTitleStyle(context),\n"
    "                      ),"
)

# Make cards more consistently premium
text = re.sub(
    r"(\n\s+Card\(\n)(\s+child: Padding\()",
    r"\1                color: _warmCard,\n                elevation: 0,\n                shape: RoundedRectangleBorder(\n                  borderRadius: BorderRadius.circular(20),\n                ),\n\2",
    text
)

# tidy specific cards to avoid duplicate color blocks for hero/points card
text = text.replace(
    "              Card(\n                color: _sandCard,\n                elevation: 0,\n                shape: RoundedRectangleBorder(\n                  borderRadius: BorderRadius.circular(20),\n                ),\n                child: Padding(",
    "              Card(\n                color: _sandCard,\n                elevation: 0,\n                shape: RoundedRectangleBorder(\n                  borderRadius: BorderRadius.circular(20),\n                ),\n                child: Padding("
)

# Soften explanatory text blocks
text = text.replace(
    "                        style: Theme.of(context).textTheme.bodySmall,",
    "                        style: Theme.of(context).textTheme.bodySmall?.copyWith(\n"
    "                              color: _textSoft,\n"
    "                              height: 1.3,\n"
    "                            ),"
)

# Improve hero item title contrast
text = text.replace(
    "                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(\n"
    "                                              fontWeight: FontWeight.w800,\n"
    "                                            ),",
    "                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(\n"
    "                                              fontWeight: FontWeight.w800,\n"
    "                                              color: _textDark,\n"
    "                                            ),"
)

# Restyle NeedTile colors directly in helper widget
text = text.replace(
    "    final bg = isHigh\n"
    "        ? colorScheme.errorContainer\n"
    "        : isMedium\n"
    "            ? colorScheme.secondaryContainer\n"
    "            : colorScheme.surfaceContainerHighest;",
    "    final bg = isHigh\n"
    "        ? const Color(0xFFF7DEC2)\n"
    "        : isMedium\n"
    "            ? const Color(0xFFE5F0EE)\n"
    "            : const Color(0xFFF4EEE4);"
)

text = text.replace(
    "      decoration: BoxDecoration(\n"
    "        color: bg,\n"
    "        borderRadius: BorderRadius.circular(14),\n"
    "      ),",
    "      decoration: BoxDecoration(\n"
    "        color: bg,\n"
    "        borderRadius: BorderRadius.circular(18),\n"
    "      ),"
)

# add text color in NeedTile
text = text.replace(
    "                  fontWeight: FontWeight.w800,\n"
    "                ),",
    "                  fontWeight: FontWeight.w800,\n"
    "                  color: const Color(0xFF183038),\n"
    "                ),"
)

if text == original:
    print("No changes made.")
    raise SystemExit(0)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 726 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
