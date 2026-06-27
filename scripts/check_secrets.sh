#!/usr/bin/env bash
set -e

echo "🔐 Scanning for possible secrets..."

git grep -nE "API_KEY|SECRET|TOKEN|PASSWORD" || echo "✅ No obvious secrets found"
