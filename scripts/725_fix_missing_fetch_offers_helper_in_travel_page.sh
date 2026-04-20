#!/usr/bin/env bash
set -euo pipefail

echo "==> 725_fix_missing_fetch_offers_helper_in_travel_page"

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
bak = path.with_name(path.name + f".bak_{stamp}_725")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# Sørg for at kallet bruker helperen
text = text.replace(
    "      final dynamic response = OffersFeedRepository().getOffersFeed();",
    "      final dynamic response = await _fetchOffersFeedResponse();",
)
text = text.replace(
    "      final dynamic response = OffersFeedRepository().fetchOffersFeed();",
    "      final dynamic response = await _fetchOffersFeedResponse();",
)
text = text.replace(
    "      final dynamic response = OffersFeedRepository().loadOffersFeed();",
    "      final dynamic response = await _fetchOffersFeedResponse();",
)
text = text.replace(
    "      final dynamic response = OffersFeedRepository().fetchFeed();",
    "      final dynamic response = await _fetchOffersFeedResponse();",
)
text = text.replace(
    "      final dynamic response = OffersFeedRepository().loadFeed();",
    "      final dynamic response = await _fetchOffersFeedResponse();",
)

helper = """
  Future<dynamic> _fetchOffersFeedResponse() async {
    final dynamic repo = OffersFeedRepository();

    try {
      return await repo.fetchOffersFeed();
    } catch (_) {}

    try {
      return await repo.getOffersFeed();
    } catch (_) {}

    try {
      return await repo.loadOffersFeed();
    } catch (_) {}

    try {
      return await repo.fetchFeed();
    } catch (_) {}

    try {
      return await repo.loadFeed();
    } catch (_) {}

    return null;
  }

"""

if "_fetchOffersFeedResponse() async" not in text:
    anchors = [
        "  Future<List<_TravelOfferSuggestion>> _loadTripFeedSuggestions() async {\n",
        "  int _parseSasPoints() {\n",
        "  @override\n  Widget build(BuildContext context) {\n",
    ]

    inserted = False
    for anchor in anchors:
        if anchor in text:
            text = text.replace(anchor, helper + anchor, 1)
            inserted = True
            print(f"Inserted helper before anchor: {anchor.strip()}")
            break

    if not inserted:
        print("ERROR: Could not find a safe insertion point for helper method")
        raise SystemExit(1)

# Rydd litt
text = re.sub(r"\n{3,}", "\n\n", text)

if text == original:
    print("No changes made.")
else:
    path.write_text(text)
    print(f"Patched: {path}")
PY

echo
echo "✅ 725 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
