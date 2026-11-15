#!/bin/bash
# Skriver ut checkFavoritesAndNotify() + tier-relaterte linjer fra api/server.js til /tmp/favorites_logic.txt
# Kjør fra rota av bonusvarsel-repoet:  bash scripts/08_show_favorites_logic.sh
set -e
FILE="api/server.js"
OUT="/tmp/favorites_logic.txt"
[ -f "$FILE" ] || { echo "❌ Fant ikke $FILE — kjør fra rota av repoet."; exit 1; }
START=$(grep -n "function checkFavoritesAndNotify" "$FILE" | head -1 | cut -d: -f1)
[ -n "$START" ] || { echo "❌ Fant ikke checkFavoritesAndNotify"; exit 1; }
END=$(python3 - "$FILE" "$START" <<'PY'
import sys
f,s=sys.argv[1],int(sys.argv[2])
depth=0;started=False
for i,l in enumerate(open(f).read().split("\n")[s-1:],start=s):
    for c in l:
        if c=="{": depth+=1;started=True
        elif c=="}": depth-=1
    if started and depth==0:
        print(i);break
PY
)
{
  echo "=== checkFavoritesAndNotify (linje $START-$END) ==="
  sed -n "${START},${END}p" "$FILE"
  echo
  echo "=== tier/premium/elite/free-treff i hele filen ==="
  grep -n -i "tier\|isPremium\|isElite\|plan ===\|subscription" "$FILE" || true
} > "$OUT"
wc -l "$OUT"
echo "✅ Ferdig. Kjør:  cat $OUT | pbcopy   (kopierer til utklippstavlen) — lim så inn her."
