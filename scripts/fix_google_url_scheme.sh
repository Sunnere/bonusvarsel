#!/bin/bash

# Hent REVERSED_CLIENT_ID fra GoogleService-Info.plist
REVERSED_CLIENT_ID=$(grep -A1 "REVERSED_CLIENT_ID" ios/Runner/GoogleService-Info.plist | grep string | sed 's/.*<string>\(.*\)<\/string>/\1/')

echo "=== REVERSED_CLIENT_ID ==="
echo "$REVERSED_CLIENT_ID"

# Legg til URL scheme i Info.plist
python3 << PYTHON
import plistlib

with open('ios/Runner/Info.plist', 'rb') as f:
    plist = plistlib.load(f)

# Sjekk om CFBundleURLTypes allerede finnes
if 'CFBundleURLTypes' not in plist:
    plist['CFBundleURLTypes'] = []

# Sjekk om Google URL scheme allerede er lagt til
reversed_client_id = "$REVERSED_CLIENT_ID"
existing = [item for item in plist['CFBundleURLTypes'] 
            if reversed_client_id in str(item.get('CFBundleURLSchemes', []))]

if not existing:
    plist['CFBundleURLTypes'].append({
        'CFBundleTypeRole': 'Editor',
        'CFBundleURLSchemes': [reversed_client_id]
    })
    print("✅ Google URL scheme lagt til")
else:
    print("✅ Google URL scheme allerede til stede")

with open('ios/Runner/Info.plist', 'wb') as f:
    plistlib.dump(plist, f)
PYTHON

echo ""
echo "=== Ferdig ==="
