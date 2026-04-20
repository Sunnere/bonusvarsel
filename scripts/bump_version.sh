#!/bin/bash
# Øker build number med 1 (f.eks. 1.0.0+2 → 1.0.0+3)
PUBSPEC="pubspec.yaml"
CURRENT=$(grep "^version:" $PUBSPEC | head -1)
echo "Nåværende: $CURRENT"

VERSION=$(echo $CURRENT | sed 's/version: //' | cut -d'+' -f1)
BUILD=$(echo $CURRENT | cut -d'+' -f2)
NEW_BUILD=$((BUILD + 1))

sed -i '' "s/^version: .*/version: ${VERSION}+${NEW_BUILD}/" $PUBSPEC
echo "Ny versjon: version: ${VERSION}+${NEW_BUILD}"
