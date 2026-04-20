#!/usr/bin/env bash
set -euo pipefail

echo "==> 723_fix_travel_page_offers_repo_method"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

repo_path = Path("lib/services/offers_feed_repository.dart")
travel_path = Path("lib/pages/travel_page.dart")

if not repo_path.exists():
    print("ERROR: lib/services/offers_feed_repository.dart not found")
    raise SystemExit(1)

if not travel_path.exists():
    print("ERROR: lib/pages/travel_page.dart not found")
    raise SystemExit(1)

repo_text = repo_path.read_text()
travel_text = travel_path.read_text()

preferred = [
    "fetchOffersFeed",
    "getOffersFeed",
    "loadOffersFeed",
    "fetchFeed",
    "loadFeed",
]

found = None
for name in preferred:
    if re.search(rf"\b{name}\s*\(", repo_text):
        found = name
        break

if found is None:
    methods = re.findall(
        r"(?:Future<[^>]+>|Future|Stream<[^>]+>|Stream|[A-Za-z_][A-Za-z0-9_<>,? ]+)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(",
        repo_text,
    )
    methods = [m for m in methods if not m.startswith("_") and m != "OffersFeedRepository"]
    if methods:
        found = methods[0]

if found is None:
    print("ERROR: Could not determine OffersFeedRepository method")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = travel_path.with_name(travel_path.name + f".bak_{stamp}_723")
shutil.copy2(travel_path, bak)
print(f"Backup: {bak}")
print(f"Using repository method: {found}()")

updated = travel_text

# Bytt alle vanlige varianter til riktig metode
updated = re.sub(
    r"OffersFeedRepository\(\)\.(fetchOffersFeed|getOffersFeed|loadOffersFeed|fetchFeed|loadFeed)\(\)",
    f"OffersFeedRepository().{found}()",
    updated,
)

if updated == travel_text:
    print("No changes made; method call pattern not found.")
else:
    travel_path.write_text(updated)
    print(f"Patched: {travel_path}")
PY

echo
echo "✅ 723 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
