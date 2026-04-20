#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Kjører Bonusvarsel i prod-lignende modus =="
echo "Dev Hub skal være skjult når ENABLE_DEV_HUB ikke settes."

flutter run -d chrome \
  --dart-define=APP_FLAVOR=prod \
  --dart-define=API_BASE=http://127.0.0.1:8081
