#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

echo "==> Treff for Sticky CTA / Elite / plan-kort"
grep -n "_StickyCta\|title: 'Elite'\|class _Plan\|selected == 'Elite'\|Premium: full rate\|Oppgrader" "$FILE" || true

echo
echo "==> Utdrag rundt _StickyCta"
LINE="$(grep -n "_StickyCta" "$FILE" | head -n1 | cut -d: -f1 || true)"
if [ -n "${LINE:-}" ]; then
  START=$((LINE>30 ? LINE-30 : 1))
  END=$((LINE+50))
  nl -ba "$FILE" | sed -n "${START},${END}p"
else
  echo "Fant ingen _StickyCta"
fi

echo
echo "==> Utdrag rundt Elite-plan"
LINE="$(grep -n "title: 'Elite'" "$FILE" | head -n1 | cut -d: -f1 || true)"
if [ -n "${LINE:-}" ]; then
  START=$((LINE>40 ? LINE-40 : 1))
  END=$((LINE+80))
  nl -ba "$FILE" | sed -n "${START},${END}p"
else
  echo "Fant ingen direkte Elite-planlinje"
fi

echo
echo "==> Utdrag rundt plan-kortklasse"
LINE="$(grep -n "class _Plan" "$FILE" | head -n1 | cut -d: -f1 || true)"
if [ -n "${LINE:-}" ]; then
  START=$((LINE>20 ? LINE-20 : 1))
  END=$((LINE+160))
  nl -ba "$FILE" | sed -n "${START},${END}p"
else
  echo "Fant ingen class _Plan*"
fi
