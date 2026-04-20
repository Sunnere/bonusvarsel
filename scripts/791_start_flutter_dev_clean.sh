#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starter Flutter DEV (ren start)..."

cd ~/bonusvarsel

flutter clean
flutter pub get

flutter run -d chrome \
  --dart-define=APP_FLAVOR=dev \
  --dart-define=ENABLE_DEV_HUB=true \
  --dart-define=API_BASE=http://127.0.0.1:8081
