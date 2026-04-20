#!/usr/bin/env bash
set -euo pipefail

echo "==> 708_revert_broken_eb_live_feed_wiring"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

page = Path("lib/pages/eb_shopping_page.dart")
if not page.exists():
    print("ERROR: lib/pages/eb_shopping_page.dart not found")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = page.with_name(page.name + f".bak_{stamp}_708")
shutil.copy2(page, bak)
print(f"Backup: {bak}")

text = page.read_text()

original = text

# ------------------------------------------------------------
# 1) Fjern imports lagt til av broken live-feed patch
# ------------------------------------------------------------
text = re.sub(
    r"^import\s+'\.\./features/offers/eb_shopping_offers_datasource\.dart';\n?",
    "",
    text,
    flags=re.MULTILINE,
)
text = re.sub(
    r"^import\s+'\.\./features/offers/eb_shopping_offer_vm\.dart';\n?",
    "",
    text,
    flags=re.MULTILINE,
)

# Fjern eventuelt OffersFeedRepository-import hvis den ble lagt til av patchen
text = re.sub(
    r"^import\s+'.*offers_feed_repository\.dart';\n?",
    "",
    text,
    flags=re.MULTILINE,
)

# ------------------------------------------------------------
# 2) Fjern feltet _offersDataSource hvis det finnes
# ------------------------------------------------------------
text = re.sub(
    r"^[ \t]*late final EbShoppingOffersDataSource _offersDataSource;\n?",
    "",
    text,
    flags=re.MULTILINE,
)

# ------------------------------------------------------------
# 3) Fjern assignment-blokk i initState hvis den finnes
# ------------------------------------------------------------
text = re.sub(
    r"\n?[ \t]*_offersDataSource\s*=\s*EbShoppingOffersDataSource\(\n(?:[ \t].*\n)*?[ \t]*\);\n?",
    "\n",
    text,
    flags=re.MULTILINE,
)

# ------------------------------------------------------------
# 4) Fjern broken metode _loadLiveOrFallbackOffers helt
#    Den ligger tydeligvis feil plassert og gir undefined name.
# ------------------------------------------------------------
text = re.sub(
    r"\n[ \t]*Future<List<EbShoppingOfferVm>> _loadLiveOrFallbackOffers\(\) async \{\n"
    r"[ \t]*return _offersDataSource\.load\(\);\n"
    r"[ \t]*\}\n?",
    "\n",
    text,
    flags=re.MULTILINE,
)

# Hvis metoden ble laget med litt annen spacing
text = re.sub(
    r"\n[ \t]*Future<\s*List<\s*EbShoppingOfferVm\s*>\s*>\s*_loadLiveOrFallbackOffers\(\)\s*async\s*\{"
    r"(?:.|\n)*?"
    r"\n[ \t]*\}\n?",
    "\n",
    text,
    count=1,
)

# ------------------------------------------------------------
# 5) Bytt tilbake eventuelle kall hvis de finnes
# ------------------------------------------------------------
# Kun hvis legacy loader faktisk finnes i filen
if "_loadLegacyEbShoppingOffers(" in text:
    text = text.replace("_loadLiveOrFallbackOffers()", "_loadLegacyEbShoppingOffers()")

# ------------------------------------------------------------
# 6) Fjern eventuelle noop-klasser hvis de ble injisert nederst i filen
# ------------------------------------------------------------
text = re.sub(
    r"\nclass _NoopOffersFeedRepository \{(?:.|\n)*?\n\}\n\nclass _NoopOffersFeedResponse \{(?:.|\n)*?\n\}\n?",
    "\n",
    text,
    count=1,
)

# ------------------------------------------------------------
# 7) Rydd opp tomme linjer
# ------------------------------------------------------------
text = re.sub(r"\n{3,}", "\n\n", text)

if text != original:
    page.write_text(text)
    print(f"Patched: {page}")
else:
    print("No changes made; file already looked reverted.")

PY

echo
echo "✅ 708 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
