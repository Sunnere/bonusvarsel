#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_747_autofind_favorite_master_and_lock_no_redesign"

FOUND="$(
  find "$HOME/Downloads" "$HOME/Desktop" -type f \
    \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) \
    -print0 2>/dev/null \
  | xargs -0 ls -t 2>/dev/null \
  | grep -Ei 'bonusvarsel|icon|airplane|flight|card|polished|favorite|master|app[_ -]?icon' \
  | head -1 || true
)"

if [ -z "${FOUND:-}" ]; then
  echo "❌ Fant ingen sannsynlig favorittfil automatisk."
  echo
  echo "Kjør denne for å finne filen manuelt:"
  echo 'find ~/Downloads ~/Desktop -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -print0 | xargs -0 ls -lt | head -50'
  echo
  echo "Når du ser riktig fil, kjør:"
  echo 'SOURCE_ICON="/full/sti/til/din/fil.png" bash scripts/patch_746_lock_exact_favorite_master_no_redesign.sh'
  exit 1
fi

echo "✅ Fant kandidat:"
echo "   $FOUND"
echo
echo "==> Bruker denne fila som eksakt master uten redesign"

SOURCE_ICON="$FOUND" bash scripts/patch_746_lock_exact_favorite_master_no_redesign.sh
