#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_799_1.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

route = '''
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

if 'app.get("/v1/dev/debug-campaign-fetch"' in text:
    print("ℹ️ Route finnes allerede i api/server.js")
else:
    marker = 'app.listen(port, () => {'
    if marker not in text:
        raise SystemExit("❌ Fant ikke app.listen-markør i api/server.js")
    text = text.replace(marker, route + marker, 1)
    p.write_text(text)
    print("✅ La inn debug route før app.listen")
PY

echo
echo "=== Verifiser route i fila ==="
grep -n 'debug-campaign-fetch' "$FILE" || true

echo
node --check "$FILE"
echo "✅ 799.1 ferdig"
