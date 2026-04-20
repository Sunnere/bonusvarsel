#!/usr/bin/env bash
set -euo pipefail

echo "==> 729_add_sas_trumf_branding_to_travel_page"

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
bak = path.with_name(path.name + f".bak_{stamp}_729")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# 1) Add optional asset bundle helper note comment near imports if not present
imports_anchor = "import '../widgets/travel_value_card.dart';"
optional_comment = """
// Optional brand assets supported by UI fallback:
// - assets/brands/sas_eurobonus.png
// - assets/brands/trumf.png
"""
if optional_comment.strip() not in text and imports_anchor in text:
    text = text.replace(imports_anchor, imports_anchor + "\n" + optional_comment, 1)

# 2) Add brand section helper methods inside _TravelPageState if missing
brand_helpers = """
  Widget _buildBrandStrip(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonuspartnere i planen din',
            style: _sectionTitleStyle(context),
          ),
          const SizedBox(height: 6),
          Text(
            'Inspirert av følelsen fra SAS og Trumf-universet, med tydelig bonusfokus i reiseplanleggingen.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _textSoft,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _BrandBadge(
                label: 'SAS EuroBonus',
                assetPath: 'assets/brands/sas_eurobonus.png',
                bgColor: Color(0xFFF3F7FB),
                borderColor: Color(0xFFD7E3F2),
                textColor: Color(0xFF153E75),
              ),
              _BrandBadge(
                label: 'Trumf',
                assetPath: 'assets/brands/trumf.png',
                bgColor: Color(0xFFF2F8EA),
                borderColor: Color(0xFFD9E9C2),
                textColor: Color(0xFF2F6B2F),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF103E74),
                  Color(0xFF0F6B73),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Slik tenker planen',
                  style: _heroTitleStyle(context),
                ),
                const SizedBox(height: 6),
                Text(
                  '1. Se hva familien trenger\\n2. Finn hvilke butikktyper som passer\\n3. Estimer poeng via SAS EuroBonus og Trumf-lignende kjøpsflyt',
                  style: _heroBodyStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsGapHero(
    BuildContext context,
    int currentSasPoints,
    int projectedSasPoints,
    int targetPoints,
    int pointsGap,
  ) {
    final bool onTrack = pointsGap <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F6B73),
            Color(0xFF1B8FA0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            onTrack ? 'Du er på rett kurs ✈️' : 'Du mangler poeng til reisen ✈️',
            style: _heroTitleStyle(context),
          ),
          const SizedBox(height: 6),
          Text(
            onTrack
                ? 'Planen din ser sterk ut allerede.'
                : 'Dette er gapet mellom dagens saldo og et forsiktig mål for familien.',
            style: _heroBodyStyle(context),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                label: 'Nå',
                value: _formatInt(currentSasPoints),
              ),
              _MetricPill(
                label: 'Etter kjøp',
                value: _formatInt(projectedSasPoints),
              ),
              _MetricPill(
                label: 'Mål',
                value: _formatInt(targetPoints),
              ),
              _MetricPill(
                label: onTrack ? 'Status' : 'Mangler',
                value: onTrack ? 'Klar' : _formatInt(pointsGap),
                highlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
"""
if "_buildBrandStrip(BuildContext context)" not in text:
    build_anchor = "  @override\n  Widget build(BuildContext context) {\n"
    if build_anchor not in text:
        print("ERROR: Could not find build anchor in travel_page.dart")
        raise SystemExit(1)
    text = text.replace(build_anchor, brand_helpers + "\n" + build_anchor, 1)

# 3) Insert brand strip + gap hero high on page
old_block = """              Text(
                'Familietur-planlegger',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Planlegg familiebehov, estimer poeng og finn hvilke butikktyper som passer best i appen.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _textSoft,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 16),"""

new_block = """              Text(
                'Familietur-planlegger',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Planlegg familiebehov, estimer poeng og finn hvilke butikktyper som passer best i appen.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _textSoft,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 16),
              _buildPointsGapHero(
                context,
                currentSasPoints,
                projectedSasPoints,
                targetPoints,
                pointsGap,
              ),
              const SizedBox(height: 14),
              _buildBrandStrip(context),
              const SizedBox(height: 16),"""

if old_block in text and "_buildBrandStrip(context)" not in text:
    text = text.replace(old_block, new_block, 1)

# 4) Make offers feed section feel more branded and less generic
text = text.replace(
    "                              'Butikkforslag fra offers feed',",
    "                              'Butikkforslag fra SAS / Trumf-inspirert feed',",
)

text = text.replace(
    "                        'Denne blokken skal være synlig høyt oppe på siden.',",
    "                        'Live forslag med fallback når feed ikke gir direkte treff.',",
)

# 5) Add helper widgets near end of file if missing
helper_widgets = """
class _BrandBadge extends StatelessWidget {
  final String label;
  final String assetPath;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _BrandBadge({
    required this.label,
    required this.assetPath,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            height: 20,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return Icon(
                Icons.workspace_premium,
                size: 18,
                color: textColor,
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _MetricPill({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted
        ? const Color(0xFFE7C98B)
        : Colors.white.withOpacity(0.18);

    final fg = highlighted ? const Color(0xFF183038) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg.withOpacity(highlighted ? 0.95 : 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
"""
if "class _BrandBadge extends StatelessWidget" not in text:
    # insert before _NeedTile if present, else append
    anchor = "class _NeedTile extends StatelessWidget {"
    if anchor in text:
        text = text.replace(anchor, helper_widgets + "\n" + anchor, 1)
    else:
        text = text.rstrip() + "\n\n" + helper_widgets + "\n"

# 6) Tone down washed-out sections by restoring text contrast in specific weak texts
text = text.replace(
    "style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                              color: _textSoft,\n                              height: 1.3,\n                            ),",
    "style: Theme.of(context).textTheme.bodySmall?.copyWith(\n                              color: _textSoft,\n                              height: 1.3,\n                              fontWeight: FontWeight.w500,\n                            ),",
)

# 7) Make store list tiles more visible if previously washed out
text = text.replace(
    "                          leading: const Icon(Icons.storefront_outlined),",
    "                          leading: const Icon(Icons.storefront_outlined, color: Color(0xFF0F6B73)),",
)

if text == original:
    print("No changes made.")
    raise SystemExit(0)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 729 ferdig"
echo
echo "Valgfritt for ekte logoer senere:"
echo "  assets/brands/sas_eurobonus.png"
echo "  assets/brands/trumf.png"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
