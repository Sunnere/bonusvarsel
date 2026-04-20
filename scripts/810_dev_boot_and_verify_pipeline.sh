#!/usr/bin/env bash
set -euo pipefail

API_PORT=8081
API_URL="http://127.0.0.1:${API_PORT}"

echo "== 🔥 Starter Bonusvarsel DEV miljø =="

echo
echo "== 🧹 Stopper gamle prosesser =="
kill $(lsof -ti :${API_PORT}) 2>/dev/null || true

echo
echo "== 🚀 Starter backend =="
cd ~/bonusvarsel/api
PORT=${API_PORT} \
ENABLE_DEV_ROUTES=true \
APP_VERSION=dev-local \
AUTO_PIPELINE_INTERVAL_MS=15000 \
AUTO_PIPELINE_THRESHOLD=2 \
npm run dev > /tmp/bonusvarsel_api.log 2>&1 &

API_PID=$!
echo "Backend PID: $API_PID"

echo
echo "== ⏳ Venter på API health =="

for i in {1..20}; do
  if curl -s "${API_URL}/health" | grep -q '"ok":true'; then
    echo "✅ API er oppe"
    break
  fi
  sleep 1
done

echo
echo "== 📡 Tester campaign fetch =="
curl -s "${API_URL}/v1/dev/debug-campaign-fetch" | head -c 300 || true
echo
echo

echo "== ⏳ Venter på auto pipeline tick (15s) =="
sleep 16

echo
echo "== 📊 Pipeline status =="
curl -s "${API_URL}/health" | sed 's/,/\n/g' | grep -E "scanned|queued|dispatched|source" || true

echo
echo "== 🚀 Starter Flutter =="
cd ~/bonusvarsel

flutter run -d chrome \
  --dart-define=APP_FLAVOR=dev \
  --dart-define=ENABLE_DEV_HUB=true \
  --dart-define=API_BASE=${API_URL}

