#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_782.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("api/server.js")
text = p.read_text()

pattern = re.compile(
    r'''app\.post\("/v1/push/simulate-alert",\s*\(req,\s*res\)\s*=>\s*\{[\s\S]*?\n\}\);''',
    re.MULTILINE
)

replacement = r'''app.post("/v1/push/simulate-alert", async (req, res) => {
  try {
    const now = new Date().toISOString();
    const level = req.body?.level ?? "premium";
    const campaignFlag = req.body?.campaign ?? true;

    const campaigns = await fetchCampaigns();
    const sorted = [...campaigns].sort(
      (a, b) => Number(b.multiplier || 0) - Number(a.multiplier || 0)
    );

    const selected = sorted[0] ?? {
      title: "Ingen live-kampanje funnet",
      multiplier: Number(req.body?.rate ?? 18),
      url: null,
    };

    const evaluation = evaluateCampaign(selected, req.body ?? {});

    const result = {
      simulatedAt: now,
      source: "live-feed",
      offer: {
        title: selected.title ?? "-",
        url: selected.url ?? null,
        rate: Number(selected.multiplier || req.body?.rate || 0),
        rateText: `${Number(selected.multiplier || req.body?.rate || 0)}x`,
        level,
        campaign: selected.title ?? campaignFlag,
      },
      evaluation: {
        ...evaluation,
      },
      liveCandidate: {
        title: selected.title ?? "-",
        multiplier: selected.multiplier ?? null,
        url: selected.url ?? null,
      },
      candidateCount: sorted.length,
    };

    res.json(result);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});'''

new_text, count = pattern.subn(replacement, text, count=1)

if count != 1:
    raise SystemExit("❌ Fant ikke eksisterende /v1/push/simulate-alert-route å erstatte")

p.write_text(new_text)
print("✅ Koble simulate-alert til live feed i api/server.js")
PY

node --check api/server.js
echo "✅ 782 ferdig"
