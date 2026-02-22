#!/usr/bin/env bash
set -e

echo "🔍 Checking for com.example leftovers..."

if grep -R "com.example" ios; then
  echo "❌ Found com.example references!"
  exit 1
else
  echo "✅ No com.example found. Bundle ID clean."
fi
