#!/bin/bash
# 33: Aggregert GET /v1/stats/devices (kun antall per tier, ingen persondata)
set -e
FILE="${1:-api/server.js}"
[ -f "$FILE" ] || { echo "❌ Fant ikke $FILE (kjør fra repo-rot)"; exit 1; }
grep -q "\[33\] devices-stats" "$FILE" && { echo "✅ Allerede lagt inn"; exit 0; }
grep -q '^app.get("/v1/devices/favorites"' "$FILE" || { echo "❌ Fant ikke GET /v1/devices/favorites"; exit 1; }
cp "$FILE" "$FILE.bak33"
python3 - "$FILE" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read()
i=s.index('app.get("/v1/devices/favorites"')
j=s.index('\n});\n',i)+len('\n});\n')
add='''
// [33] devices-stats: kun aggregerte tall, ingen id/e-post/favoritter
app.get("/v1/stats/devices", (req, res) => {
  const byTier = { free: 0, premium: 0, elite: 0 };
  let total = 0, loggedIn = 0;
  for (const d of Object.values(deviceFavorites || {})) {
    if (!d) continue;
    total++;
    if (d.uid) loggedIn++;
    const t = byTier[d.tier] !== undefined ? d.tier : 'free';
    byTier[t]++;
  }
  res.json({ ok: true, total, loggedIn, byTier });
});
'''
open(p,'w').write(s[:j]+add+s[j:])
PY
node --check "$FILE" || { cp "$FILE.bak33" "$FILE"; echo "❌ Syntaksfeil – rullet tilbake"; exit 1; }
echo "✅ Lagt inn /v1/stats/devices"
