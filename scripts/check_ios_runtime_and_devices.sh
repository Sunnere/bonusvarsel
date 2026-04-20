#!/bin/bash
set -euo pipefail

echo "== xcodebuild -version =="
xcodebuild -version || true
echo

echo "== simctl runtimes =="
xcrun simctl list runtimes || true
echo

echo "== simctl device types =="
xcrun simctl list devicetypes | grep -E "iPhone|iPad" || true
echo

echo "== simctl devices =="
xcrun simctl list devices || true
echo

echo "== flutter devices =="
flutter devices || true
echo
