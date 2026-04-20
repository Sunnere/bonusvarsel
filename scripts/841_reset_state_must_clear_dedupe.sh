#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_841.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()
original = text

candidates = [
"""  state.pipeline = {
    ok: true,
    scanStatus: "idle",
    queueStatus: "idle",
    dispatchStatus: "idle",
    pipeline: { scanned: 0, queued: 0, dispatched: 0 },
    lastSimulationId: null,
    lastUpdated: nowIso(),
    summary: "Tilstand nullstilt.",
    threshold: currentAutoPipelineThreshold,
    source: "reset",
    recentCampaigns: [],
    notifications: { count: 0, items: [] },
  };
""",
"""  state.pipeline = {
    ok: true,
    scanStatus: "idle",
    queueStatus: "idle",
    dispatchStatus: "idle",
    pipeline: { scanned: 0, queued: 0, dispatched: 0 },
    lastSimulationId: null,
    lastUpdated: nowIso(),
    summary: "Tilstand nullstilt.",
    threshold: currentAutoPipelineThreshold,
    source: "reset",
    recentCampaigns: [],
    notifications: { count: 0, items: [] },
  };
  state.activatedNotifications = [];
"""
]

replacement = """  state.pipeline = {
    ok: true,
    scanStatus: "idle",
    queueStatus: "idle",
    dispatchStatus: "idle",
    pipeline: { scanned: 0, queued: 0, dispatched: 0 },
    lastSimulationId: null,
    lastUpdated: nowIso(),
    summary: "Tilstand nullstilt.",
    threshold: currentAutoPipelineThreshold,
    source: "reset",
    recentCampaigns: [],
    notifications: { count: 0, items: [] },
  };
  state.activatedNotifications = [];
  state.sentCampaignKeys = new Set();
"""

changed = False
for old in candidates:
    if old in text:
        text = text.replace(old, replacement, 1)
        changed = True
        break

if not changed:
    raise SystemExit("❌ Fant ikke reset-state-blokken å oppdatere")

p.write_text(text)
print("✅ Reset-state tømmer nå også sentCampaignKeys")
PY

echo
grep -n "sentCampaignKeys" "$FILE" | sed -n '1,120p'
echo
node --check "$FILE"
echo "✅ 841 ferdig"
