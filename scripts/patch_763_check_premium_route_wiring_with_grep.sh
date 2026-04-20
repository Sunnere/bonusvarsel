#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_763_check_premium_route_wiring_with_grep"
echo

echo "==> Søker etter '/premium'"
find lib -type f \( -name "*.dart" \) -print0 | xargs -0 grep -nE "'/premium'|\"/premium\"" || true

echo
echo "==> Søker etter PremiumPage / premium_page"
find lib -type f \( -name "*.dart" \) -print0 | xargs -0 grep -nEi "PremiumPage|premium_page|premium page" || true

echo
echo "==> Søker etter app-router"
find lib -type f \( -name "*.dart" \) -print0 | xargs -0 grep -nE "MaterialApp|CupertinoApp|routes:|onGenerateRoute|GoRouter|routeInformationParser|routerDelegate" || true

echo
echo "==> Søker etter named navigation"
find lib -type f \( -name "*.dart" \) -print0 | xargs -0 grep -nE "pushNamed\(|pushReplacementNamed\(|pushNamedAndRemoveUntil\(" || true

echo
echo "✅ Ferdig"
echo
echo "Hvis '/premium' ikke dukker opp over, er named route ikke koblet ennå."
echo "Lim inn outputen her, så lager jeg en presis wiring-cat-script."
