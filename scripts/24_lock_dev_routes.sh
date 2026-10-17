#!/usr/bin/env bash
# 24_lock_dev_routes.sh
# Legger en vakt foran alle /dev- og /v1/dev-endepunkter i api/server.js.
# Krever header x-admin-key lik BV_ADMIN_KEY (samme som /v1/admin/program-alert).
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
FILE="$ROOT/api/server.js"

[ -f "$FILE" ] || { echo "FEIL: finner ikke $FILE"; exit 1; }
if grep -q "DEV_GUARD_V1" "$FILE"; then echo "OK: allerede lastet."; exit 0; fi

cp "$FILE" "$FILE.bak_24"

python3 - "$FILE" <<'PY'
import sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
anchor = 'app.post("/dev/simulate-campaign", async (req, res) => {'
n = src.count(anchor)
if n != 1:
    sys.exit(f"FEIL: fant {n} forekomster av ankeret (forventet 1). Ingen endringer gjort.")
guard = '''// DEV_GUARD_V1: /dev og /v1/dev krever x-admin-key (BV_ADMIN_KEY)
const devGuard = (req, res, next) => {
  const adminKey = process.env.BV_ADMIN_KEY;
  if (!adminKey || req.headers['x-admin-key'] !== adminKey) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }
  next();
};
app.use(["/dev", "/v1/dev"], devGuard);

'''
new = src.replace(anchor, guard + anchor, 1)
open(path, "w", encoding="utf-8").write(new)
print("Vakt satt inn foran /dev-rutene")
PY

if command -v node >/dev/null 2>&1 && ! node --check "$FILE" 2>/dev/null; then
  echo "FEIL: syntaksfeil. Gjenoppretter original."
  mv "$FILE.bak_24" "$FILE"
  exit 1
fi
rm -f "$FILE.bak_24"
echo "OK: $FILE er oppdatert."
