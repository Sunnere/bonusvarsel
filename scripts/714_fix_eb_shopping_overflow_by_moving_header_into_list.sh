#!/usr/bin/env bash
set -euo pipefail

echo "==> 714_fix_eb_shopping_overflow_by_moving_header_into_list"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/eb_shopping_page.dart")
if not path.exists():
    print("ERROR: lib/pages/eb_shopping_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_714")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# ------------------------------------------------------------
# 1) Fjern broken live-feed metode som fortsatt gir analyze-feil
# ------------------------------------------------------------
text = re.sub(
    r"\n[ \t]*Future<List<EbShoppingOfferVm>> _loadLiveOrFallbackOffers\(\) async \{\n"
    r"[ \t]*return _offersDataSource\.load\(\);\n"
    r"[ \t]*\}\n?",
    "\n",
    text,
    flags=re.MULTILINE,
)

# fallback hvis spacing er litt annerledes
text = re.sub(
    r"\n[ \t]*Future<\s*List<\s*EbShoppingOfferVm\s*>\s*>\s*_loadLiveOrFallbackOffers\(\)\s*async\s*\{(?:.|\n)*?\n[ \t]*\}\n?",
    "\n",
    text,
    count=1,
)

# ------------------------------------------------------------
# 2) Finn body Column og fjern toppseksjonen før Expanded(...)
# ------------------------------------------------------------
body_anchor = "body: Column("
body_idx = text.find(body_anchor)
if body_idx == -1:
    print("ERROR: Could not find body: Column(")
    raise SystemExit(1)

children_anchor = "children: ["
children_idx = text.find(children_anchor, body_idx)
if children_idx == -1:
    print("ERROR: Could not find body Column children: [")
    raise SystemExit(1)

expanded_idx = text.find("Expanded(", children_idx)
if expanded_idx == -1:
    print("ERROR: Could not find Expanded( inside body Column")
    raise SystemExit(1)

body_top_chunk = text[children_idx + len(children_anchor):expanded_idx]
if "_PremiumHeader()" not in body_top_chunk and "SmartBestRecommendationCard(" not in body_top_chunk:
    print("ERROR: Expected top header chunk not found between body children and Expanded(")
    raise SystemExit(1)

# behold bare Expanded som første child i outer Column
text = text[:children_idx + len(children_anchor)] + "\n          " + text[expanded_idx:]

# ------------------------------------------------------------
# 3) Prepend toppseksjonen inn i den eksisterende ListView children
# ------------------------------------------------------------
listview_idx = text.find("return ListView(", body_idx)
if listview_idx == -1:
    print("ERROR: Could not find return ListView(")
    raise SystemExit(1)

list_children_idx = text.find("children: [", listview_idx)
if list_children_idx == -1:
    print("ERROR: Could not find ListView children: [")
    raise SystemExit(1)

insert_block = """
              const _PremiumHeader(),
              SmartBestRecommendationCard(
                futureOffers: _futureShops,
                amountNok: 5000,
                onTapPaywall: () => _openPremiumPage(context),
              ),
              // BV_SOURCE_FILTER
              const SizedBox(height: 4),
              const SizedBox(height: 8),
              _buildSourceFilter(context),
              if (_source == 'Alle')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Toppbutikker akkurat nå',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
"""

existing_after = text[list_children_idx:list_children_idx + 1200]
if "_PremiumHeader()" in existing_after or "SmartBestRecommendationCard(" in existing_after:
    print("Top widgets already appear inside ListView. Skipping insert.")
else:
    insert_at = list_children_idx + len("children: [")
    text = text[:insert_at] + "\n" + insert_block + text[insert_at:]
    print("Inserted top header section into ListView.")

# ------------------------------------------------------------
# 4) Rydd opp noen blanklinjer
# ------------------------------------------------------------
text = re.sub(r"\n{3,}", "\n\n", text)

# ------------------------------------------------------------
# 5) Sikkerhetssjekk
# ------------------------------------------------------------
if "body: Column(" not in text:
    print("ERROR: body Column disappeared unexpectedly.")
    raise SystemExit(1)

if "Expanded(" not in text[body_idx:body_idx + 3000]:
    print("ERROR: Expanded missing from body after patch.")
    raise SystemExit(1)

if "return ListView(" not in text:
    print("ERROR: ListView missing after patch.")
    raise SystemExit(1)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "✅ 714 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
