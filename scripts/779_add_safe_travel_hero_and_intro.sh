#!/usr/bin/env bash
set -euo pipefail

echo "==> 779_add_safe_travel_hero_and_intro"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_779")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()

# ---- SAFE INSERT: find first Column in build ----
anchor = "child: Column("

if anchor not in text:
    print("❌ Fant ikke Column() i build")
    raise SystemExit(1)

insert_block = """

              // 🔥 HERO + INTRO (SAFE INSERT)
              Container(
                height: 180,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/travel/hero_beach.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xCC0D1B2A),
                        Color(0x880D1B2A),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Planlegg reisen smartere ✈️',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Se hva du mangler av poeng før du bestiller',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF7F8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Familietur-planlegger',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Planlegg familiebehov, estimer poeng og finn hvilke kjøp som gir mest verdi.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
"""

# insert right after first Column(
text = text.replace(anchor, anchor + insert_block, 1)

path.write_text(text)
print("✅ Hero + intro lagt til trygt")
PY

echo
echo "Kjør:"
echo "  flutter analyze"
echo "  flutter run -d macos"
