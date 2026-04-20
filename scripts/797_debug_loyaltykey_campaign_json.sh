#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="tmp/loyaltykey_debug"
JSON_FILE="$OUT_DIR/campaigns.json"
REPORT_FILE="$OUT_DIR/report.txt"
URL="https://onlineshopping.loyaltykey.com/api/v1/campaigns?filter[channel]=SAS&filter[language]=nb&filter[country]=NO&filter[amount]=20"

mkdir -p "$OUT_DIR"

echo "🌐 Henter LoyaltyKey campaign JSON..."
curl -L --silent --show-error \
  -A "BonusVarsel/1.0 (Local Debug)" \
  -H "Accept: application/json, text/plain, */*" \
  "$URL" \
  -o "$JSON_FILE"

python3 <<'PY'
from pathlib import Path
import json

json_path = Path("tmp/loyaltykey_debug/campaigns.json")
report_path = Path("tmp/loyaltykey_debug/report.txt")

raw = json_path.read_text(errors="ignore")

lines = []
lines.append("=== LOYALTYKEY CAMPAIGN JSON DEBUG ===")
lines.append(f"Raw size: {len(raw)} bytes")
lines.append("")

try:
    data = json.loads(raw)
except Exception as e:
    lines.append(f"JSON parse failed: {e}")
    lines.append("")
    lines.append("=== RAW HEAD ===")
    lines.append(raw[:2000])
    report_path.write_text("\n".join(lines))
    print(report_path.read_text())
    raise SystemExit(0)

lines.append(f"Top-level type: {type(data).__name__}")

if isinstance(data, dict):
    lines.append(f"Top-level keys: {list(data.keys())[:80]}")
elif isinstance(data, list):
    lines.append(f"Top-level list length: {len(data)}")

items = None
source_name = None

candidates = [
    ("top-level list", data if isinstance(data, list) else None),
    ("data", data.get("data") if isinstance(data, dict) else None),
    ("campaigns", data.get("campaigns") if isinstance(data, dict) else None),
    ("items", data.get("items") if isinstance(data, dict) else None),
    ("results", data.get("results") if isinstance(data, dict) else None),
]

for name, candidate in candidates:
    if isinstance(candidate, list):
        items = candidate
        source_name = name
        break

lines.append(f"Chosen item source: {source_name or 'none'}")
lines.append(f"Chosen item count: {len(items) if isinstance(items, list) else 0}")
lines.append("")

if isinstance(items, list) and items:
    first = items[0]
    lines.append("=== FIRST ITEM KEYS ===")
    if isinstance(first, dict):
        lines.append(str(list(first.keys())))
    else:
        lines.append(f"First item type: {type(first).__name__}")
    lines.append("")

    lines.append("=== FIRST ITEM JSON ===")
    lines.append(json.dumps(first, ensure_ascii=False, indent=2)[:8000])
    lines.append("")

    lines.append("=== FIELD PROBES (first 5 items) ===")
    probe_keys = [
        "title", "name", "headline", "description", "subtitle",
        "url", "link", "shop_url", "shopUrl", "tracking_url", "trackingUrl",
        "multiplier", "rate", "amount", "value",
        "reward_multiplier", "rewardMultiplier",
        "campaign_multiplier", "campaignMultiplier",
        "shop_name", "shopName",
    ]
    for idx, item in enumerate(items[:5], start=1):
        lines.append(f"-- item #{idx} --")
        if isinstance(item, dict):
            for key in probe_keys:
                if key in item:
                    lines.append(f"{key}: {item.get(key)!r}")
        else:
            lines.append(repr(item))
        lines.append("")
else:
    lines.append("No items found in candidate arrays.")
    lines.append("")
    lines.append("=== FULL JSON HEAD ===")
    lines.append(json.dumps(data, ensure_ascii=False, indent=2)[:8000])

report_path.write_text("\n".join(lines))
print(report_path.read_text())
PY

echo
echo "📄 Filer:"
echo "  - $JSON_FILE"
echo "  - $REPORT_FILE"
