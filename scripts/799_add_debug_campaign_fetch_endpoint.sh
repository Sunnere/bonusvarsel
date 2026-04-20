#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_799.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

route = r'''
app.get("/v1/dev/debug-campaign-fetch", async (_, res) => {
  try {
    const campaigns = await fetchCampaigns();
    res.json({
      ok: true,
      count: Array.isArray(campaigns) ? campaigns.length : 0,
      items: Array.isArray(campaigns) ? campaigns.slice(0, 10) : [],
    });
  } catch (e) {
    res.status(500).json({
      ok: false,
      error: String(e),
    });
  }
});
'''

if '/v1/dev/debug-campaign-fetch' in text:
    print("ℹ️ Debug endpoint finnes allerede")
    raise SystemExit(0)

marker = 'app.get("/health", (_, res) => res.json({ ok: true }));'
if marker not in text:
    raise SystemExit("❌ Fant ikke health-markør i api/server.js")

text = text.replace(marker, marker + "\n" + route, 1)
p.write_text(text)
print("✅ La inn /v1/dev/debug-campaign-fetch")
PY

node --check api/server.js
echo "✅ 799 ferdig"
