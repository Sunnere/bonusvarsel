#!/usr/bin/env bash
# 26_favorites_auth_header.sh
# Legger Firebase-innloggingstoken i Authorization-headeren for /v1/devices/favorites.
# Retter også \${res.statusCode}, som ellers vises som tekst i feilmeldingen.
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
FILE="$ROOT/lib/services/api_service.dart"

[ -f "$FILE" ] || { echo "FEIL: finner ikke $FILE"; exit 1; }
if grep -q "FAV_AUTH_V1" "$FILE"; then echo "OK: allerede lastet."; exit 0; fi

cp "$FILE" "$FILE.bak_26"

python3 - "$FILE" <<'PY'
import sys, re
path = sys.argv[1]
src = open(path, encoding="utf-8").read()

old_head = """    final deviceId = await DeviceIdService.getId();
    final res = await http.post(
      _uri('/v1/devices/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'x-device-id': deviceId,
      },"""
new_head = """    final deviceId = await DeviceIdService.getId();
    // FAV_AUTH_V1: favoritter krever innlogging. Tokenet sendes til serveren.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Logg inn for å lagre favoritter');
    }
    final idToken = await user.getIdToken();
    final res = await http.post(
      _uri('/v1/devices/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'x-device-id': deviceId,
        'Authorization': 'Bearer $idToken',
      },"""
if src.count(old_head) != 1:
    sys.exit(f"FEIL: fant {src.count(old_head)} forekomster av headeren (forventet 1). Ingen endringer gjort.")
src = src.replace(old_head, new_head, 1)

src = src.replace("\\${res.statusCode}", "${res.statusCode}")

# importer firebase_auth etter siste eksisterende import, hvis den mangler
if "package:firebase_auth/firebase_auth.dart" not in src:
    lines = src.split("\n")
    last = max(i for i, l in enumerate(lines) if l.startswith("import "))
    lines.insert(last + 1, "import 'package:firebase_auth/firebase_auth.dart';")
    src = "\n".join(lines)

open(path, "w", encoding="utf-8").write(src)
print("Auth-header lagt til")
PY

rm -f "$FILE.bak_26"
echo "OK: $FILE er oppdatert."
