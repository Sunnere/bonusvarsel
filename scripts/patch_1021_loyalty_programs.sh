#!/bin/bash
set -e

FILE="api/server.js"
BACKUP="${FILE}.bak_1021_loyalty_programs_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"
echo "Backup laget: $BACKUP"

python3 << 'PYEOF'
import sys

path = "api/server.js"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

if "LOYALTY_PROGRAMS" in content:
    print("Patch er allerede anvendt - hopper over. Ingen endring gjort.")
    sys.exit(0)

old_a = '''function pickWeeklyGeneralOffers(campaigns) {
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

new_a = '''function pickWeeklyGeneralOffers(campaigns) {
  const eligible = campaigns.filter((c) => c.slug && (c.multiplier ?? 1) > 1);
  const topTrumf = eligible
    .filter((c) => c.source === "trumf")
    .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))[0];
  const topSas = eligible
    .filter((c) => c.source === "sas")
    .sort((a, b) => (b.multiplier ?? 0) - (a.multiplier ?? 0))[0];
  return [topTrumf, topSas].filter(Boolean);
}

// Loyalty program config - legg til nytt program her (klar for Flying Blue m.fl.)
const LOYALTY_PROGRAMS = {
  trumf: { prefix: 'tn_', label: 'Trumf' },
  sas: { prefix: 'sas_', label: 'SAS EuroBonus' },
};

function stripLoyaltyPrefix(slug) {
  const s = String(slug || '');
  for (const { prefix } of Object.values(LOYALTY_PROGRAMS)) {
    if (s.startsWith(prefix)) return s.slice(prefix.length);
  }
  return s;
}

async function checkFavoritesAndNotify() {'''

old_b = '''      const allFavSlugs = [...(favs.trumf || []), ...(favs.sas || [])];'''
new_b = '''      const allFavSlugs = Object.keys(LOYALTY_PROGRAMS).flatMap((programKey) => favs[programKey] || []);'''

old_c = '''          const normalizedFavSlugs = allFavSlugs.map(s =>
            s.replace(/^tn_/, '').replace(/^sas_/, ''));
          const normalizedCampaignSlug = campaign.slug.replace(/^tn_/, '').replace(/^sas_/, '');'''
new_c = '''          const normalizedFavSlugs = allFavSlugs.map((s) => stripLoyaltyPrefix(s));
          const normalizedCampaignSlug = stripLoyaltyPrefix(campaign.slug);'''

blocks = [("A", old_a, new_a), ("B", old_b, new_b), ("C", old_c, new_c)]

for name, old, new in blocks:
    count = content.count(old)
    if count == 0:
        print(f"FEIL: Fant ikke blokk {name}. Ingen endring gjort. Sjekk om server.js er endret siden dette scriptet ble laget.")
        sys.exit(1)
    if count > 1:
        print(f"FEIL: Fant blokk {name} {count} ganger - forventet noyaktig 1. Ingen endring gjort.")
        sys.exit(1)

for name, old, new in blocks:
    content = content.replace(old, new)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("PATCH OK: LOYALTY_PROGRAMS config lagt til, matching-logikk gjort generisk (blokk A, B, C)")
PYEOF

echo ""
echo "Ferdig. Sjekk diff med:"
echo "  diff \"$BACKUP\" \"$FILE\""
