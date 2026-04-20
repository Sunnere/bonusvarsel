#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_853.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()
original = text

# 1) legg inn TTL config hvis den ikke finnes
marker = "const autoDispatchMaxPerTick = Number(process.env.AUTO_DISPATCH_MAX_PER_TICK || 3);\n"
insert = marker + "const dedupeTtlMs = Number(process.env.AUTO_DEDUPE_TTL_MS || 21600000);\n"
if "dedupeTtlMs" not in text:
    if marker not in text:
        raise SystemExit("❌ Fant ikke config-marker for autoDispatchMaxPerTick")
    text = text.replace(marker, insert, 1)

# 2) initier timestamp-basert dedupe store hvis nødvendig
state_marker = "sentCampaignKeys"
if "sentCampaignSeenAt" not in text:
    text = text.replace(
        "sentCampaignKeys",
        "sentCampaignSeenAt",
        1,
    )

# 3) bytt dedupe-filteret til TTL-basert sjekk
old_filter = """  const deduped = dispatchCandidates.filter(
    (item) => !state.sentCampaignKeys.has(item.dedupeKey),
  );
"""

new_filter = """  const nowMs = Date.now();

  if (!(state.sentCampaignSeenAt instanceof Map)) {
    state.sentCampaignSeenAt = new Map();
  }

  for (const [key, seenAt] of [...state.sentCampaignSeenAt.entries()]) {
    if (!seenAt || nowMs - Number(seenAt) > dedupeTtlMs) {
      state.sentCampaignSeenAt.delete(key);
    }
  }

  const deduped = dispatchCandidates.filter((item) => {
    const seenAt = state.sentCampaignSeenAt.get(item.dedupeKey);
    if (!seenAt) return true;
    return nowMs - Number(seenAt) > dedupeTtlMs;
  });
"""

if old_filter not in text:
    raise SystemExit("❌ Fant ikke gammel dedupe-filterblokk")
text = text.replace(old_filter, new_filter, 1)

# 4) når noe faktisk dispatches, lagre tidspunkt i Map
old_mark = """  for (const item of dispatchedItems) {
    state.sentCampaignKeys.add(item.dedupeKey);
  }
"""

new_mark = """  for (const item of dispatchedItems) {
    if (!(state.sentCampaignSeenAt instanceof Map)) {
      state.sentCampaignSeenAt = new Map();
    }
    state.sentCampaignSeenAt.set(item.dedupeKey, Date.now());
  }
"""

if old_mark not in text:
    raise SystemExit("❌ Fant ikke blokk som markerer dispatch som sendt")
text = text.replace(old_mark, new_mark, 1)

# 5) reset må tømme riktig struktur
reset_candidates = [
"""  state.activatedNotifications = [];
  state.sentCampaignKeys = new Set();
""",
"""  state.activatedNotifications = [];
  state.sentCampaignSeenAt = new Map();
""",
]

replaced_reset = False
for candidate in reset_candidates:
    if candidate in text:
        text = text.replace(
            candidate,
            "  state.activatedNotifications = [];\n  state.sentCampaignSeenAt = new Map();\n",
            1,
        )
        replaced_reset = True
        break

if not replaced_reset:
    raise SystemExit("❌ Fant ikke reset-blokken for dedupe-state")

# 6) hvis state-init fortsatt bruker Set, gjør den om til Map
text = text.replace(
    "sentCampaignSeenAt: new Set()",
    "sentCampaignSeenAt: new Map()",
)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn TTL-basert dedupe + reset av riktig state")
PY

echo
grep -n "dedupeTtlMs\|sentCampaignSeenAt\|dedupeKey" "$FILE" | sed -n '1,200p'
echo
node --check "$FILE"
echo "✅ node --check OK"
