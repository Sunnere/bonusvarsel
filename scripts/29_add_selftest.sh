#!/bin/bash
set -e
TARGET="functions/index.js"
cp "$TARGET" "$TARGET.bak_selftest_$(date +%Y%m%d_%H%M%S)"
echo "🔒 Backup lagret"

python3 << 'PYTHON'
with open("functions/index.js","r",encoding="utf-8") as f:
    src = f.read()

if "selfTest" in src:
    print("ℹ️  selfTest finnes allerede – hopper over")
else:
    old = """  const data = request.data;
  const { email, telegram, message, sasCount, trumfCount } = data;
  const promises = [];"""
    new = """  const data = request.data;
  const { email, telegram, message, sasCount, trumfCount } = data;

  // ── SELF-TEST: hent ekte tilbud, bygg melding, send til deg selv ──
  if (data.selfTest && telegram) {
    const sasOffers   = (await fetchOffersFromRailway('sas_online')).slice(0, 2);
    const trumfOffers = (await fetchOffersFromRailway('trumf_netthandel')).slice(0, 3);
    const testMsg = buildMessage(sasOffers, trumfOffers, [], []);
    await sendTelegram(telegram, testMsg);
    return { selfTest: true, sasCount: sasOffers.length, trumfCount: trumfOffers.length };
  }

  const promises = [];"""
    if old not in src:
        print("❌ Fant ikke innsettingspunkt – avbryter")
        raise SystemExit(1)
    src = src.replace(old, new, 1)
    with open("functions/index.js","w",encoding="utf-8") as f:
        f.write(src)
    print("✅ selfTest lagt til")
PYTHON

node --check "$TARGET" && echo "✅ node --check OK" || { echo "❌ Syntaksfeil – gjenoppretter"; cp "$TARGET".bak_selftest_* "$TARGET"; exit 1; }
