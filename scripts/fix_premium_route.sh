#!/bin/bash
echo "=== Sjekker routes i main/app ==="
grep -rn "routes\|'/premium'\|premiumRouteName\|PremiumPage" lib/main.dart lib/app.dart 2>/dev/null || echo "Ingen treff – sjekk fil manuelt"

echo ""
echo "=== MaterialApp i prosjektet ==="
grep -rn "MaterialApp" lib/ | head -10
