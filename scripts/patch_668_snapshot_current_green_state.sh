#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d_%H%M%S)"

cp lib/pages/premium_page.dart "lib/pages/premium_page.dart.green_${STAMP}.bak"
cp lib/pages/eb_shopping_page.dart "lib/pages/eb_shopping_page.dart.green_${STAMP}.bak"

echo "✅ Snapshot laget:"
echo "  lib/pages/premium_page.dart.green_${STAMP}.bak"
echo "  lib/pages/eb_shopping_page.dart.green_${STAMP}.bak"
