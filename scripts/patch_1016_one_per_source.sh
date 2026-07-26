#!/bin/bash
set -euo pipefail

FILE="api/server.js"
BACKUP="${FILE}.bak_1016_one_per_source_$(date +%Y%m%d_%H%M%S)"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE. Kjør dette scriptet fra rot-mappen i repoet."
  exit 1
fi

cp "$FILE" "$BACKUP"

python3 - "$FILE" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

edits = []

old_anchor = "async function checkFavoritesAndNotify() {"
new_anchor = '''function pickWeeklyGeneralOffers(campaigns) {
  const eligible = campaigns.filter((c) => c.slug && (c.multiplier ?? 1) > 1);
  const topTrumf = eligible
    .filter((c) => c.source === "trumf")
    .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))[0];
  const topSas = eligible
    .filter((c) => c.source === "sas")
    .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))[0];
  return [topTrumf, topSas].filter(Boolean);
}

async function checkFavoritesAndNotify() {'''
edits.append((old_anchor, new_anchor))

old_prod = '''      if (isFreeTier) {
        if (!isWeeklyFallbackWindow()) continue;
        const topGeneral = campaigns
          .filter(c => c.slug && (c.multiplier ?? 1) > 1)
          .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
          .slice(0, 2);
        for (const campaign of topGeneral) {'''
new_prod = '''      if (isFreeTier) {
        if (!isWeeklyFallbackWindow()) continue;
        const topGeneral = pickWeeklyGeneralOffers(campaigns);
        for (const campaign of topGeneral) {'''
edits.append((old_prod, new_prod))

old_test = '''    const campaigns = await fetchAllCampaigns("elite");
    const topGeneral = campaigns
      .filter((c) => c.slug && (c.multiplier ?? 1) > 1)
      .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))
      .slice(0, 2);'''
new_test = '''    const campaigns = await fetchAllCampaigns("elite");
    const topGeneral = pickWeeklyGeneralOffers(campaigns);'''
edits.append((old_test, new_test))

missing = []
for old, new in edits:
    if old not in src:
        missing.append(old[:80])
    else:
        src = src.replace(old, new, 1)

if missing:
    print("❌ Fant ikke følgende kodeblokk(er), ingen endringer lagret:")
    for m in missing:
        print("   -", m)
    sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("✅ Garanterer nå ett tilbud fra Trumf OG ett fra SAS")
PYEOF

echo "✅ Backup laget: $BACKUP"
echo "Verifiser: node --check $FILE"
