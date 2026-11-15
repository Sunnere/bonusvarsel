#!/usr/bin/env bash
# 29_firebase_key_to_railway.sh
# Finner Firebase service-account-nøkkelen i ~/Downloads (eller oppgitt sti),
# validerer den, kopierer den som én linje til utklippstavlen for lim inn på Railway,
# og sletter den lokalt KUN når du bekrefter at den er satt på Railway.
set -euo pipefail

KEY="${1:-}"
if [ -z "$KEY" ]; then
  KEY=$(ls -t "$HOME"/Downloads/*firebase-adminsdk*.json 2>/dev/null | head -1 || true)
fi
[ -n "$KEY" ] && [ -f "$KEY" ] || { echo "FEIL: fant ingen nøkkelfil. Oppgi sti som argument."; exit 1; }

python3 - "$KEY" <<'PY' || { echo "FEIL: filen er ikke en gyldig service account-nøkkel."; exit 1; }
import sys, json
d = json.load(open(sys.argv[1], encoding="utf-8"))
assert d.get("type") == "service_account", "type"
assert d.get("project_id") == "bonusvarsel", "project_id"
assert d.get("private_key", "").startswith("-----BEGIN"), "private_key"
assert d.get("client_email", "").endswith("@bonusvarsel.iam.gserviceaccount.com"), "client_email"
print("OK: gyldig nøkkel for prosjekt", d["project_id"])
print("client_email:", d["client_email"])
PY

if command -v pbcopy >/dev/null 2>&1; then
  python3 -c "import json,sys; print(json.dumps(json.load(open(sys.argv[1]))))" "$KEY" | pbcopy
  echo "Kopiert til utklippstavlen."
else
  echo "FEIL: pbcopy finnes ikke. Kjør på Mac."; exit 1
fi

echo
echo "Neste:"
echo "  1. Railway → bonusvarsel → API-tjenesten → Variables"
echo "  2. Sett FIREBASE_SERVICE_ACCOUNT (eller rediger den) og lim inn med Cmd+V"
echo "  3. Vent til deploy er ferdig, og sjekk loggen for: Initialisert i firestore-mode"
echo
read -r -p "Er nøkkelen limt inn og lagret på Railway? Skriv ja for å slette lokal kopi: " SVAR
if [ "$SVAR" = "ja" ]; then
  rm -f "$KEY"
  echo "Slettet lokal kopi: $KEY"
  echo "Husk: slett den gamle nøkkelen i Firebase under Project settings → Service accounts."
else
  echo "Beholder lokal fil. Kjør scriptet igjen når du er klar til å slette den."
fi
