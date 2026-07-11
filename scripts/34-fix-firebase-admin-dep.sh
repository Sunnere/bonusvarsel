#!/bin/zsh
set -e
cd /Users/sunnerehelse/bonusvarsel/api

echo "==> Installerer firebase-admin..."
npm install firebase-admin

echo "==> Verifiserer at pakken kan importeres..."
node -e "import('firebase-admin').then(() => console.log('✅ firebase-admin OK'))"

echo "==> Starter serveren lokalt og tester /health..."
PORT=8099 node server.js > /tmp/bv-test.log 2>&1 &
SERVER_PID=$!
sleep 4

HEALTH=$(curl -s http://127.0.0.1:8099/health || echo "FEIL")
kill $SERVER_PID 2>/dev/null || true

if echo "$HEALTH" | grep -q '"monitor"'; then
  echo "✅ Serveren starter og /health svarer med monitor-felt"
else
  echo "❌ Serveren svarte ikke som forventet. Logg:"
  cat /tmp/bv-test.log
  exit 1
fi

echo "==> Committer package.json + package-lock.json..."
cd /Users/sunnerehelse/bonusvarsel
git add api/package.json api/package-lock.json
git commit -m "Script 34: legg til firebase-admin som avhengighet (fikser ERR_MODULE_NOT_FOUND)"
git push origin local-stable-baseline

echo ""
echo "✅ FERDIG. Railway redeployer nå – vent på grønn deploy (1-2 min)."
