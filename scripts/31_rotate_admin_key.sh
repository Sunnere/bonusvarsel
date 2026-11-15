#!/usr/bin/env bash
# 31 – Roter BV_ADMIN_KEY: lager ny nøkkel, skriver til api/.env, kopierer til utklippstavlen.
# Skriver ALDRI nøkkelen til skjermen. Kjør: bash scripts/31_rotate_admin_key.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ENVF="api/.env"
[ -d api ] || { echo "❌ Fant ikke api/ – kjør fra repo-roten"; exit 1; }
touch "$ENVF"; chmod 600 "$ENVF"

if git check-ignore -q "$ENVF" 2>/dev/null; then echo "✅ $ENVF er git-ignorert"; else
  echo "⚠️  $ENVF er IKKE git-ignorert – legg '.env' i .gitignore før du committer!"; fi

KEY="$(openssl rand -hex 32 | tr -d '\n')"
[ "${#KEY}" -eq 64 ] || { echo "❌ Nøkkelgenerering feilet"; exit 1; }

TMP="$(mktemp)"
grep -v -E '^BV_ADMIN_KEY=' "$ENVF" > "$TMP" || true
printf 'BV_ADMIN_KEY=%s\n' "$KEY" >> "$TMP"
cat "$TMP" > "$ENVF"; rm -f "$TMP"; chmod 600 "$ENVF"

# verifiser at filen har nøyaktig én rad med riktig lengde
N="$(grep -c -E '^BV_ADMIN_KEY=' "$ENVF")"
L="$(grep -E '^BV_ADMIN_KEY=' "$ENVF" | cut -d= -f2- | tr -d '\n' | wc -c | tr -d ' ')"
[ "$N" = "1" ] && [ "$L" = "64" ] || { echo "❌ Verifisering feilet (rader=$N lengde=$L)"; exit 1; }
echo "✅ Ny BV_ADMIN_KEY lagret i $ENVF (64 tegn, 1 rad)"

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$KEY" | pbcopy
  echo "📋 Nøkkelen ligger nå i utklippstavlen (ingen mellomrom/linjeskift)"
else
  echo "ℹ️  pbcopy mangler – hent nøkkelen fra $ENVF"
fi
unset KEY

cat <<'TXT'

NESTE – lim inn samme nøkkel to steder (ikke mer enn dette):
 1) Railway → bonusvarsel → Variables → BV_ADMIN_KEY → Update → Deploy
 2) Make → scenario 8005088 → modul 3 (HTTP) → Headers → x-admin-key → Value
    (Name skal stå som: x-admin-key) → Save → Run once
Test etterpå (spør etter nøkkelen uten å vise den):
    read -rs "K?Nøkkel: "; echo
    curl -s -o /dev/null -w "%{http_code}\n" -X POST https://bonusvarsel-production.up.railway.app/v1/admin/program-alert \
      -H "x-admin-key: $K" -H 'Content-Type: application/json' -d '{"program":"spenn","title":"test","dryRun":true}'
  200 = riktig nøkkel, 401 = feil. (Gammel nøkkel skal nå gi 401.)
TXT
