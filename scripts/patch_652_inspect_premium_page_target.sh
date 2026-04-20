#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

echo "==> Treff for typisk gevinst / mål / Premium / Elite"
grep -ni "typisk gevinst\|mål\|premium\|elite" "$FILE" || true

echo
echo "==> Utdrag rundt første treff"
LINE="$(grep -ni "typisk gevinst\|mål\|premium\|elite" "$FILE" | head -n1 | cut -d: -f1 || true)"

if [ -z "${LINE:-}" ]; then
  echo "Fant ingen relevante treff."
  exit 0
fi

START=$((LINE>80 ? LINE-80 : 1))
END=$((LINE+140))

sed -n "${START},${END}p" "$FILE"
