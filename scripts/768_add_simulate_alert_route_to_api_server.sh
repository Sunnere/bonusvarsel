#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

if '/v1/push/simulate-alert' in text:
    print('✅ Route finnes allerede i api/server.js')
    raise SystemExit(0)

route = """

app.post("/v1/push/simulate-alert", (req, res) => {
  const now = new Date().toISOString();
  const rate = Number(req.body?.rate ?? 18);
  const level = req.body?.level ?? "premium";
  const campaign = req.body?.campaign ?? true;

  const result = {
    simulatedAt: now,
    offer: {
      rate,
      rateText: `${rate}x`,
      level,
      campaign,
    },
    evaluation: {
      score: Math.round(rate * 2),
      momentum: rate >= 15 ? "high" : rate >= 8 ? "medium" : "low",
      timing: "now",
      shouldNotify: rate >= 8,
      reason: rate >= 8
        ? "High enough score for alert"
        : "Below notify threshold",
    },
  };

  res.json(result);
});
"""

marker = "app.listen(port, () => {"
if marker not in text:
    raise SystemExit("❌ Fant ikke app.listen-markør i api/server.js")

text = text.replace(marker, route + "\n" + marker, 1)
p.write_text(text)
print("✅ La til /v1/push/simulate-alert i api/server.js")
PY

echo "✅ 768 ferdig"
