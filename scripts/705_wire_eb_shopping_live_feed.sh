#!/usr/bin/env bash
set -euo pipefail

echo "==> 705_wire_eb_shopping_live_feed"

python3 <<'PY'
from pathlib import Path
import shutil
from datetime import datetime
import re

FILE = "lib/pages/eb_shopping_page.dart"
stamp = datetime.now().strftime("%Y%m%d_%H%M%S")

p = Path(FILE)
if not p.exists():
    print("ERROR: eb_shopping_page.dart not found")
    exit(1)

bak = p.with_name(p.name + f".bak_{stamp}_705")
shutil.copy2(p, bak)
print(f"Backup: {bak}")

text = p.read_text()

# --------------------------------------------------
# 1. Add imports if missing
# --------------------------------------------------

if "eb_shopping_offers_datasource.dart" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\n"
        "import '../features/offers/eb_shopping_offers_datasource.dart';\n"
        "import '../features/offers/eb_shopping_offer_vm.dart';"
    )

# --------------------------------------------------
# 2. Add datasource field
# --------------------------------------------------

if "_offersDataSource" not in text:
    text = re.sub(
        r'class\s+_.*State\s+extends\s+State<.*>\s*{',
        lambda m: m.group(0) + "\n"
        "  late final EbShoppingOffersDataSource _offersDataSource;\n",
        text,
        count=1
    )

# --------------------------------------------------
# 3. Init datasource in initState
# --------------------------------------------------

if "_offersDataSource =" not in text:
    text = re.sub(
        r'@override\s+void\s+initState\(\)\s*{\s*super\.initState\(\);',
        lambda m: m.group(0) + "\n"
        "    _offersDataSource = EbShoppingOffersDataSource(\n"
        "      offersFeedRepository: OffersFeedRepository(),\n"
        "      legacyFallbackLoader: _loadLegacyEbShoppingOffers,\n"
        "    );\n",
        text,
        count=1
    )

# --------------------------------------------------
# 4. Add loader method (safe)
# --------------------------------------------------

if "_loadLiveOrFallbackOffers" not in text:
    insert_point = text.rfind("}")
    method = """

  Future<List<EbShoppingOfferVm>> _loadLiveOrFallbackOffers() async {
    return _offersDataSource.load();
  }

"""
    text = text[:insert_point] + method + text[insert_point:]

# --------------------------------------------------
# 5. Try to replace existing load call
# --------------------------------------------------

# replace common patterns
text = re.sub(
    r'_loadLegacyEbShoppingOffers\(\)',
    '_loadLiveOrFallbackOffers()',
    text
)

text = re.sub(
    r'await\s+_loadLegacyEbShoppingOffers\(\)',
    'await _loadLiveOrFallbackOffers()',
    text
)

# --------------------------------------------------

p.write_text(text)
print("Patched eb_shopping_page.dart")
PY

echo
echo "✅ 705 ferdig"
echo
echo "Kjør:"
echo "  flutter analyze"
echo
echo "TEST:"
echo "  - EB Shopping page åpner"
echo "  - Offers vises"
echo "  - Slå av nett → fallback fungerer"
