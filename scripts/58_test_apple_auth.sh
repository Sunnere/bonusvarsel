#!/bin/bash
set -euo pipefail
cd "$HOME/bonusvarsel"
KEY_FILE="functions/keys/SubscriptionKey.p8"
KEY_ID=$(sed -n 's/^const KEY_ID = "\([A-Z0-9]*\)";.*/\1/p' functions/appstore_verify.js)
[ -n "$KEY_ID" ] || { echo "FEIL: fant ingen KEY_ID i functions/appstore_verify.js"; exit 1; }
ISSUER_ID=$(awk -F= '/^APPLE_ISSUER_ID=/{print $2}' functions/.env | tr -d '"' | tr -d '\r')
BUNDLE_ID="com.royrotvold.bonusvarsel"

echo "Key ID: $KEY_ID"
echo "Issuer-lengde: ${#ISSUER_ID} (skal være 36)"
openssl pkey -in "$KEY_FILE" -noout && echo "PEM OK"

TOKEN=$(KEY_FILE="$KEY_FILE" KEY_ID="$KEY_ID" ISSUER_ID="$ISSUER_ID" BUNDLE_ID="$BUNDLE_ID" node -e '
const crypto = require("crypto"), fs = require("fs");
const b64u = b => Buffer.from(b).toString("base64").replace(/=+$/,"").replace(/\+/g,"-").replace(/\//g,"_");
const now = Math.floor(Date.now()/1000);
const head = b64u(JSON.stringify({alg:"ES256", kid:process.env.KEY_ID, typ:"JWT"}));
const body = b64u(JSON.stringify({iss:process.env.ISSUER_ID, iat:now, exp:now+300, aud:"appstoreconnect-v1", bid:process.env.BUNDLE_ID}));
const input = head + "." + body;
const sig = crypto.sign("sha256", Buffer.from(input), {key: fs.readFileSync(process.env.KEY_FILE,"utf8"), dsaEncoding:"ieee-p1363"}).toString("base64url");
process.stdout.write(input + "." + sig);
')

CODE=$(curl -s -o /tmp/apple_resp.json -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.storekit-sandbox.itunes.apple.com/inApps/v1/transactions/1")
echo "Apple svarte HTTP $CODE"
case "$CODE" in
  404) echo "OK: autentisering godtatt (transaksjon finnes ikke, som forventet)";;
  401) echo "FEIL: Apple avviser token. Se /tmp/apple_resp.json";;
  000) echo "Ingen nettverksforbindelse";;
  *)   echo "Uventet svar, se /tmp/apple_resp.json";;
esac
