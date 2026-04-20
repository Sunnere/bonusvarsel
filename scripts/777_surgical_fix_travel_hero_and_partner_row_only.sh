#!/usr/bin/env bash
set -euo pipefail

echo "==> 777_surgical_fix_travel_hero_and_partner_row_only"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_777")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# --- helpers: only for top section ---
helpers = r"""

  Widget _travelHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 205,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        image: const DecorationImage(
          image: AssetImage('assets/images/travel/hero_beach.jpg'),
          fit: BoxFit.cover,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xD9102036),
              Color(0xA8043E52),
              Color(0x33000000),
            ],
            stops: [0.0, 0.58, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Familietur-planlegger',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF13313A),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Planlegg reisen smartere',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Se hva du mangler av poeng før du bestiller, og finn hvilke butikker som passer best for familien.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFF4F8FB),
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _travelPartnerChip({
    required BuildContext context,
    required String label,
    required Color accent,
    String? assetPath,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2EBEF),
          width: 1.15,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (assetPath != null)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(assetPath),
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon ?? Icons.workspace_premium, color: accent, size: 20),
            ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }

  Widget _travelTopPartnerPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE7EEF1),
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonuspartnere i planen din',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF112A32),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inspirert av følelsen fra SAS og Trumf-universet, med tydelig bonusfokus i reiseplanleggingen.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5B7077),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _travelPartnerChip(
                context: context,
                label: 'SAS EuroBonus',
                accent: const Color(0xFF224A8D),
                assetPath: 'assets/brands/sas_eurobonus.png',
                icon: Icons.flight_takeoff_rounded,
              ),
              _travelPartnerChip(
                context: context,
                label: 'Trumf',
                accent: const Color(0xFF4E8B2D),
                assetPath: 'assets/brands/trumf.png',
                icon: Icons.savings_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1B3771),
                  Color(0xFF1D8C97),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Slik tenker planen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '1. Se hva familien trenger\\n2. Finn hvilke butikktyper som passer\\n3. Estimer poeng via SAS EuroBonus og Trumf-lignende kjøpsflyt',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFF5FAFC),
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

"""

anchor = "  @override\n  Widget build(BuildContext context) {"
if helpers not in text:
    if anchor not in text:
        print("❌ Fant ikke build()-anker")
        raise SystemExit(1)
    text = text.replace(anchor, helpers + "\n" + anchor, 1)

# --- replace hero only ---
hero_patterns = [
    r"""Container\(\s*width:\s*double\.infinity,\s*height:\s*205,.*?const SizedBox\(height:\s*14\),""",
    r"""Card\(\s*.*?Planlegg reisen smartere.*?const SizedBox\(height:\s*14\),""",
]
hero_replaced = False
for pat in hero_patterns:
    new_text, count = re.subn(
        pat,
        "_travelHeroBanner(context),\n              const SizedBox(height: 14),",
        text,
        count=1,
        flags=re.DOTALL,
    )
    if count:
        text = new_text
        hero_replaced = True
        break

# --- replace partner section only ---
partner_patterns = [
    r"""Container\(\s*width:\s*double\.infinity,\s*padding:\s*const EdgeInsets\.fromLTRB\(20,\s*20,\s*20,\s*18\),.*?const SizedBox\(height:\s*14\),\s*Card\(\s*color:\s*Colors\.white,\s*elevation:\s*0,\s*shape:\s*RoundedRectangleBorder\(\s*borderRadius:\s*BorderRadius\.circular\(20\),\s*\),\s*child:\s*Padding\(\s*padding:\s*const EdgeInsets\.all\(14\),\s*child:\s*Column\(""",
    r"""Text\(\s*'Bonuspartnere i planen din'.*?const SizedBox\(height:\s*14\),\s*Card\(\s*color:\s*Colors\.white,\s*elevation:\s*0,\s*shape:\s*RoundedRectangleBorder\(\s*borderRadius:\s*BorderRadius\.circular\(20\),\s*\),\s*child:\s*Padding\(\s*padding:\s*const EdgeInsets\.all\(14\),\s*child:\s*Column\(""",
]

partner_replaced = False
for pat in partner_patterns:
    new_text, count = re.subn(
        pat,
        "_travelTopPartnerPanel(context),\n              const SizedBox(height: 14),\n              Card(\n                color: Colors.white,\n                elevation: 0,\n                shape: RoundedRectangleBorder(\n                  borderRadius: BorderRadius.circular(20),\n                ),\n                child: Padding(\n                  padding: const EdgeInsets.all(14),\n                  child: Column(",
        text,
        count=1,
        flags=re.DOTALL,
    )
    if count:
        text = new_text
        partner_replaced = True
        break

if text == orig:
    print("❌ Ingen endringer gjort.")
    print("Send dette:")
    print("  sed -n '1030,1165p' lib/pages/travel_page.dart")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ Hero + partnerrad oppdatert i: {path}")
print(f"Hero erstattet: {hero_replaced}")
print(f"Partnerpanel erstattet: {partner_replaced}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
