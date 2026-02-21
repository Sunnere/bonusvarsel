#!/usr/bin/env bash
set -euo pipefail

echo "== B1: Web release build =="
flutter build web --release

echo
echo "== B2: Serve build lokalt (simple http) =="
python3 -m http.server 8081 -d build/web
