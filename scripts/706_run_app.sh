#!/usr/bin/env bash
set -euo pipefail

echo "==> 706_run_app (Starter Bonusvarsel)"

# 1. Sjekk Flutter
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter ikke installert / ikke i PATH"
  exit 1
fi

# 2. Flutter clean (unngår rare bugs)
echo "→ Flutter clean"
flutter clean

# 3. Hent dependencies
echo "→ Flutter pub get"
flutter pub get

# 4. List devices
echo "→ Tilgjengelige devices:"
flutter devices

# 5. Prøv å starte iOS simulator automatisk (Mac)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "→ Starter iOS Simulator (hvis ikke allerede åpen)"
  open -a Simulator || true
  sleep 3
fi

# 6. Run app
echo "→ Starter app..."
flutter run

