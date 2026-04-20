#!/usr/bin/env bash
set -euo pipefail

echo "==> 709_run_macos_with_log"

mkdir -p .tmp_ai

LOG_FILE=".tmp_ai/flutter_run_macos.log"

echo "→ Dreper gamle Flutter/macOS Runner-prosesser hvis de finnes"
pkill -f "Flutter" || true
pkill -f "Runner.app" || true
pkill -f "bonusvarsel" || true

echo "→ Flutter clean"
flutter clean

echo "→ Flutter pub get"
flutter pub get

echo "→ Flutter analyze"
flutter analyze || true

echo "→ Starter macOS-app med logg til $LOG_FILE"
echo "----------------------------------------" | tee "$LOG_FILE"
date | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"

flutter run -d macos 2>&1 | tee -a "$LOG_FILE"
