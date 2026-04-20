#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starter backend med live pipeline..."

cd ~/bonusvarsel/api

PORT=8081 \
ENABLE_DEV_ROUTES=true \
APP_VERSION=dev-local \
AUTO_PIPELINE_INTERVAL_MS=15000 \
npm run dev &

PID=$!

echo "⏳ Venter på API..."
sleep 2

echo
echo "🔍 Tester health endpoint..."
curl -s http://127.0.0.1:8081/v1/health | jq || echo "⚠️ Health feilet"

echo
echo "🔍 Tester simulate-alert..."
curl -s -X POST http://127.0.0.1:8081/v1/push/simulate-alert \
  -H "Content-Type: application/json" \
  -d '{"rate":18,"level":"premium","campaign":true}' | jq || echo "⚠️ Simulate feilet"

echo
echo "📡 Backend kjører (PID: $PID)"
echo "➡️  Pipeline kjører hvert 15s"
echo "➡️  Trykk CTRL+C for å stoppe"

wait $PID
