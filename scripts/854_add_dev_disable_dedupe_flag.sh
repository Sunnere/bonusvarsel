#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_854.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()
original = text

marker = "const dedupeTtlMs = Number(process.env.AUTO_DEDUPE_TTL_MS || 21600000);\n"
insert = marker + "const autoDisableDedupe = String(process.env.AUTO_DISABLE_DEDUPE || '').toLowerCase() === 'true';\n"

if "autoDisableDedupe" not in text:
    if marker not in text:
        raise SystemExit("❌ Fant ikke dedupeTtlMs-marker")
    text = text.replace(marker, insert, 1)

old = """  const deduped = dispatchCandidates.filter((item) => {
    const seenAt = state.sentCampaignSeenAt.get(item.dedupeKey);
    if (!seenAt) return true;
    return nowMs - Number(seenAt) > dedupeTtlMs;
  });
"""

new = """  const deduped = autoDisableDedupe
    ? [...dispatchCandidates]
    : dispatchCandidates.filter((item) => {
        const seenAt = state.sentCampaignSeenAt.get(item.dedupeKey);
        if (!seenAt) return true;
        return nowMs - Number(seenAt) > dedupeTtlMs;
      });
"""

if old not in text:
    raise SystemExit("❌ Fant ikke dedupe-filterblokken")
text = text.replace(old, new, 1)

old2 = """  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • dispatchCandidates=${dispatchCandidates.length} • uniqueDispatchCandidates=${deduped.length} • queued=${queued} • dispatched=${dispatched}`;
"""

new2 = """  let summary = `scanned=${scanned} • notifyCandidates=${shouldNotifyItems.length} • dispatchCandidates=${dispatchCandidates.length} • uniqueDispatchCandidates=${deduped.length} • queued=${queued} • dispatched=${dispatched} • dedupe=${autoDisableDedupe ? 'off' : 'on'}`;
"""

if old2 in text:
    text = text.replace(old2, new2, 1)

if text == original:
    raise SystemExit("❌ Ingen endringer ble gjort")

p.write_text(text)
print("✅ La inn AUTO_DISABLE_DEDUPE for dev-testing")
PY

echo
node --check "$FILE"
echo "✅ node --check OK"
