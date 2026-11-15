#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
TARGET_FILE="functions/index.js"

echo "=== 1) Sjekker at vi er i riktig repo ==="
if [ ! -f "$TARGET_FILE" ]; then
  echo "❌ Fant ikke $TARGET_FILE fra $REPO_ROOT"
  echo "   Kjør scriptet fra roten av bonusvarsel-repoet."
  exit 1
fi
echo "✅ Funnet: $REPO_ROOT/$TARGET_FILE"
echo ""

echo "=== 2) Imports (topp 30 linjer) ==="
head -n 30 "$TARGET_FILE"
echo ""

echo "=== 3) package.json for functions/ (avhengigheter) ==="
if [ -f "functions/package.json" ]; then
  cat functions/package.json
else
  echo "⚠️  functions/package.json ikke funnet"
fi
echo ""

echo "=== 4) checkSubscription-funksjonen ==="
awk '/exports\.checkSubscription|checkSubscription[[:space:]]*=/,/^\}\);?[[:space:]]*$/' "$TARGET_FILE" || true
echo ""

echo "=== 5) stripeWebhook-funksjonen (for å se skrivemønster til Firestore) ==="
awk '/exports\.stripeWebhook|stripeWebhook[[:space:]]*=/,/^\}\);?[[:space:]]*$/' "$TARGET_FILE" || true
echo ""

echo "=== 6) Alle exports.* -funksjonsnavn i filen ==="
grep -n "^exports\." "$TARGET_FILE" || echo "(ingen 'exports.' funnet — sjekk om filen bruker annen eksportstil)"
echo ""

echo "=== 7) Søk etter eksisterende Google Play / IAP-relatert kode ==="
grep -n -i "googleapis\|play_developer\|purchases\.subscriptions\|android-publisher\|inapp" "$TARGET_FILE" || echo "(ingen treff — bekrefter at Google Play-verifisering ikke finnes ennå)"
echo ""

echo "=== 8) Firebase Functions-versjon ==="
if [ -f "functions/package.json" ]; then
  grep -A1 "\"firebase-functions\"\|\"firebase-admin\"" functions/package.json || true
fi
echo ""

echo "=== Ferdig. Lim inn hele denne outputen tilbake til Claude. ==="
