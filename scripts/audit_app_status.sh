#!/bin/bash
echo "=== STRUKTUR ==="
find lib -name "*.dart" | sort

echo ""
echo "=== NAVIGASJON / ROUTES ==="
grep -rn "Navigator\|pushNamed\|MaterialPageRoute" lib/main.dart lib/pages/home_page.dart 2>/dev/null

echo ""
echo "=== TRUMF-INTEGRASJON ==="
find lib -name "*.dart" | xargs grep -l -i "trumf" 2>/dev/null

echo ""
echo "=== FAVORITTER ==="
find lib -name "*.dart" | xargs grep -l -i "favorit" 2>/dev/null

echo ""
echo "=== VARSLER / NOTIFICATIONS ==="
find lib -name "*.dart" | xargs grep -l -i "notif\|telegram\|mail\|email" 2>/dev/null

echo ""
echo "=== HOME PAGE ==="
cat lib/pages/home_page.dart 2>/dev/null || echo "IKKE FUNNET"
