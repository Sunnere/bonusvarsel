#!/bin/bash
set -e
TARGET="scripts/build-tier-messages.mjs"
cp "$TARGET" "$TARGET.bak_$(date +%Y%m%d_%H%M%S)"

python3 - << 'PYTHON'
with open('scripts/build-tier-messages.mjs', 'r') as f:
    content = f.read()

old = """const activeCampaigns = campaigns
  .filter(c => c.has_campaign === 1 && c.points_campaign > 0)
  .sort((a, b) => b.points_campaign - a.points_campaign);"""

new = """// Dagens dato for å filtrere bort utløpte tilbud
const TODAY = new Date().toISOString().slice(0, 10);

const activeCampaigns = campaigns
  .filter(c => c.has_campaign === 1 && c.points_campaign > 0)
  // Kun tilbud som IKKE er utløpt (eller mangler dato)
  .filter(c => !c.campaign_ends_iso || c.campaign_ends_iso >= TODAY)
  .sort((a, b) => b.points_campaign - a.points_campaign);"""

if old in content:
    content = content.replace(old, new)
    with open('scripts/build-tier-messages.mjs', 'w') as f:
        f.write(content)
    print('✅ Utløps-filter lagt til')
else:
    print('⚠️  Fant ikke koden – sjekk manuelt')
PYTHON
