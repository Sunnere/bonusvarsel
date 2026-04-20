#!/bin/bash

echo "=== IAP/Subscription relevante filer ==="
echo ""

echo "--- pubspec.yaml (pakker) ---"
cat pubspec.yaml 2>/dev/null || echo "IKKE FUNNET"
echo ""

echo "--- Dart-filer med IAP/purchase/subscription ---"
find . -name "*.dart" | xargs grep -l -i "purchase\|subscription\|iap\|storekit\|revenue" 2>/dev/null
echo ""

echo "--- Innhold i disse filene ---"
find . -name "*.dart" | xargs grep -l -i "purchase\|subscription\|iap\|storekit\|revenue" 2>/dev/null | while read f; do
  echo ""
  echo "====== $f ======"
  cat "$f"
done
