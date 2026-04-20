#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
cp "$FILE" "$FILE.bak.$(date +%s)"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

if "/v1/push/simulate-alert" in text:
    print("✅ endpoint finnes allerede")
    exit()

insert = """

app.post("/v1/push/simulate-alert", express.json(), (req, res) => {
  const now = new Date().toISOString();

  const rate = req.body?.rate ?? 10;

  const result = {
    simulatedAt: now,
    offer: {
      rate,
      rateText: rate + "x",
      level: rate >= 10 ? "premium" : "basic",
      campaign: "Simulated campaign"
    },
    evaluation: {
      score: Math.round(rate * 7),
      momentum: rate > 5 ? "high" : "low",
      timing: "now",
      shouldNotify: rate >= 8,
      reason: rate >= 8
        ? "High value campaign → should notify"
        : "Too low value → skip"
    }
  };

  res.json(result);
});
"""

# legg inn før app.listen
text = text.replace("app.listen", insert + "\napp.listen")

p.write_text(text)
print("✅ simulate-alert endpoint lagt til")
PY

echo "👉 Restart backend etter dette!"
