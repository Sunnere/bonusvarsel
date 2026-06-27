#!/bin/bash
set -e
TARGET=".github/workflows/bonusvarsel.yml"
cp "$TARGET" "$TARGET.bak_$(date +%Y%m%d_%H%M%S)"
sed -i '' 's/DISPLAY_NAME: "Trumf Netthandel"/DISPLAY_NAME: "SAS EuroBonus"/' "$TARGET"
echo "✅ DISPLAY_NAME rettet til SAS EuroBonus"
