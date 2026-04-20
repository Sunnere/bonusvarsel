#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/services/offers_feed_repository.dart"

echo "==> patch_805_fix_offers_feed_repository_parsing"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_805_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

path = Path("lib/services/offers_feed_repository.dart")
text = path.read_text()

old = """      final response = await ApiService.getOffersFeed(
        program: program,
        level: level,
        category: category,
        updatedSince: updatedSince,
      );
      await _writeCache(prefs, response);
      return response;
"""

new = """      final raw = await ApiService.getOffersFeed(
        program: program,
        level: level,
        category: category,
        updatedSince: updatedSince,
      );
      final response = OffersFeedResponse.fromJson(raw);
      await _writeCache(prefs, response);
      return response;
"""

if old not in text:
    raise SystemExit("❌ Fant ikke eksakt blokk i offers_feed_repository.dart")

text = text.replace(old, new, 1)
path.write_text(text)
print("✅ Fikset parsing fra Map<String, dynamic> til OffersFeedResponse")
PY

echo
echo "==> Verifisering"
sed -n '1,220p' "$TARGET"

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
