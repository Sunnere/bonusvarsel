#!/bin/bash
set -e
TARGET="server.js"
cp "$TARGET" "$TARGET.bak_saslink_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 << 'PYTHON'
with open("server.js","r",encoding="utf-8") as f:
    src = f.read()

old = """function bvOfferLink(c) {
  if (c.source === 'trumf') return TRUMF_HOME;
  if (c.source === 'elite') return c.url || SAS_HOME;
  if (c.slug) return SAS_BASE + c.slug;
  return SAS_HOME;
}"""

new = """function bvOfferLink(c) {
  // Trygg portal-hjem: gir alltid poeng, aldri 404.
  // (Dype /butikk/-lenker finnes ikke og ga 404 – bekreftet.)
  if (c.source === 'trumf') return TRUMF_HOME;
  return SAS_HOME;
}"""

if old in src:
    src = src.replace(old, new)
    print("✅ bvOfferLink fikset – SAS bruker nå trygg portal-hjem")
elif new in src:
    print("ℹ️  Allerede fikset")
else:
    print("❌ Fant ikke bvOfferLink – sjekk manuelt med: sed -n '69,74p' server.js")
    raise SystemExit(1)

with open("server.js","w",encoding="utf-8") as f:
    f.write(src)
PYTHON

node --check "$TARGET" && echo "✅ node --check OK" || { echo "❌ Syntaksfeil – gjenoppretter"; cp "$TARGET".bak_saslink_* "$TARGET"; exit 1; }
