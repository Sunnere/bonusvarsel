#!/usr/bin/env bash
set -euo pipefail

echo "==> 782_fix_intro_and_add_partner_block"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_782")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# ---- 1. REMOVE BROKEN YELLOW BLOCK ----
import re

text = re.sub(
    r"Container\(\s*margin: const EdgeInsets\.only\(bottom: 16\),\s*padding: const EdgeInsets\.all\(16\),.*?borderRadius: BorderRadius\.circular\(18\),\s*\),\s*child: Column\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[.*?\]\s*\),\s*\),",
    "",
    text,
    flags=re.DOTALL
)

# ---- 2. ADD NEW CLEAN PARTNER BLOCK AFTER HERO ----
anchor = "Planlegg reisen smartere ✈️"

if anchor not in text:
    print("❌ Fant ikke hero anchor")
    raise SystemExit(1)

insert = """

          const SizedBox(height: 14),

          // 🔥 PARTNER + GUIDE
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2A32),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E4A52)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Slik bygger du poeng smart',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '1. Velg riktig kort\\n2. Kjøp via riktige partnere\\n3. Maksimer opptjening før reisen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _chip(context, 'SAS EuroBonus', const Color(0xFF2E5BFF)),
                    const SizedBox(width: 10),
                    _chip(context, 'Trumf', const Color(0xFF5FAF2D)),
                  ],
                ),
              ],
            ),
          ),
"""

text = text.replace(anchor, anchor + insert, 1)

# ---- 3. ADD SMALL CHIP HELPER ----
helper = """

  Widget _chip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

"""

if "_chip(BuildContext context" not in text:
    text = text.replace("class _TravelPageState", helper + "\nclass _TravelPageState")

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ Fjernet dårlig blokk + lagt inn partner-seksjon")
PY

echo
echo "Kjør:"
echo "  flutter analyze"
echo "  flutter run -d macos"
