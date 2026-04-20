#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_762_check_premium_route_wiring"
echo

echo "==> Søker etter '/premium'"
rg -n "'/premium'|\"/premium\"" lib || true

echo
echo "==> Søker etter PremiumPage / premium_page"
rg -n "PremiumPage|premium_page|premium page" lib || true

echo
echo "==> Søker etter app-router"
rg -n "MaterialApp|CupertinoApp|routes:|onGenerateRoute|GoRouter|routeInformationParser|routerDelegate" lib || true

echo
echo "==> Søker etter named navigation til premium"
rg -n "pushNamed\\(.*/premium|pushNamed\\(" lib || true

echo
echo "✅ Ferdig"
echo
echo "Hvis '/premium' ikke dukker opp over, så er named route ikke koblet ennå."
echo "Lim inn outputen her, så lager jeg en presis wiring-cat-script."
