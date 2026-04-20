#!/usr/bin/env bash
set -euo pipefail

API_FILE="api/server.js"
SERVICE_FILE="lib/services/api_service.dart"

[[ -f "$API_FILE" ]] || { echo "❌ Fant ikke $API_FILE"; exit 1; }
[[ -f "$SERVICE_FILE" ]] || { echo "❌ Fant ikke $SERVICE_FILE"; exit 1; }

cp "$API_FILE" "$API_FILE.bak_811.$(date +%s)"
cp "$SERVICE_FILE" "$SERVICE_FILE.bak_811.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

api = Path("api/server.js")
text = api.read_text()

original = text

# 1) Default prefs/state: legg til alertThreshold hvis vi finner prefs-blokk med favFirst
patterns = [
    (
        r"(favFirst:\s*(?:true|false)\s*,\s*\n)",
        r"\1    alertThreshold: 2,\n",
        "default prefs"
    ),
]

for pat, repl, label in patterns:
    if "alertThreshold" not in text:
        new_text, count = re.subn(pat, repl, text, count=1)
        if count == 1:
            text = new_text

# 2) update prefs route: legg til parsing av alertThreshold dersom body-håndtering finnes
if "body.alertThreshold" not in text:
    anchors = [
        (
            r"(if\s*\(\s*body\.favFirst\s*!?=\s*null\s*\)\s*\{[\s\S]*?\}\s*\n)",
            r"""\1  if (body.alertThreshold != null) {
    const next = Number(body.alertThreshold);
    if (Number.isFinite(next) && next > 0) {
      prefs.alertThreshold = next;
    }
  }
""",
        ),
        (
            r"(if\s*\(\s*body\.minRate\s*!?=\s*null\s*\)\s*\{[\s\S]*?\}\s*\n)",
            r"""\1  if (body.alertThreshold != null) {
    const next = Number(body.alertThreshold);
    if (Number.isFinite(next) && next > 0) {
      prefs.alertThreshold = next;
    }
  }
""",
        ),
    ]
    inserted = False
    for pat, repl in anchors:
        new_text, count = re.subn(pat, repl, text, count=1)
        if count == 1:
            text = new_text
            inserted = True
            break
    if not inserted:
        print("⚠️ Fant ikke trygg prefs-update-anker i api/server.js for alertThreshold")

# 3) evaluateCampaign threshold fallback
# prøv å bytte kjent threshold-linje
if "prefs.alertThreshold" not in text:
    replacements = [
        (
            "const threshold = Number(reqBody.threshold || currentAutoPipelineThreshold || 2);",
            "const threshold = Number(reqBody.threshold || reqBody.alertThreshold || prefs?.alertThreshold || currentAutoPipelineThreshold || 2);",
        ),
        (
            "const threshold = Number(reqBody.threshold || 2);",
            "const threshold = Number(reqBody.threshold || reqBody.alertThreshold || prefs?.alertThreshold || 2);",
        ),
    ]
    changed = False
    for old, new in replacements:
        if old in text:
            text = text.replace(old, new, 1)
            changed = True
            break
    if not changed:
        print("⚠️ Fant ikke kjent threshold-linje i api/server.js")

# 4) hvis vi har en /v1/health eller /v1/prefs response med prefs-objekt, ingen ekstra jobb nødvendig

if text == original:
    raise SystemExit("❌ Fant ingen trygge endringer å gjøre i api/server.js")

api.write_text(text)
print("✅ Patcher api/server.js")
PY

python3 <<'PY'
from pathlib import Path
import re

svc = Path("lib/services/api_service.dart")
text = svc.read_text()
original = text

# Utvid updatePrefs-signaturen
old_sig = """  static Future<Map<String, dynamic>> updatePrefs({
    List<String>? sources,
    List<String>? categories,
    int? minRate,
    bool? onlyCampaigns,
    bool? favFirst,
  }) async {"""

new_sig = """  static Future<Map<String, dynamic>> updatePrefs({
    List<String>? sources,
    List<String>? categories,
    int? minRate,
    num? alertThreshold,
    bool? onlyCampaigns,
    bool? favFirst,
  }) async {"""

if old_sig in text:
    text = text.replace(old_sig, new_sig, 1)
else:
    raise SystemExit("❌ Fant ikke updatePrefs-signaturen i api_service.dart")

# Legg til body.alertThreshold
old_body = """    if (minRate != null) body['minRate'] = minRate;
    if (onlyCampaigns != null) body['onlyCampaigns'] = onlyCampaigns;
    if (favFirst != null) body['favFirst'] = favFirst;"""

new_body = """    if (minRate != null) body['minRate'] = minRate;
    if (alertThreshold != null) body['alertThreshold'] = alertThreshold;
    if (onlyCampaigns != null) body['onlyCampaigns'] = onlyCampaigns;
    if (favFirst != null) body['favFirst'] = favFirst;"""

if old_body in text:
    text = text.replace(old_body, new_body, 1)
else:
    raise SystemExit("❌ Fant ikke updatePrefs-body-blokken i api_service.dart")

if text == original:
    raise SystemExit("❌ Ingen endringer i api_service.dart")

svc.write_text(text)
print("✅ Patcher api_service.dart")
PY

echo
echo "=== Verifiser treff ==="
grep -n "alertThreshold\\|updatePrefs({" "$API_FILE" "$SERVICE_FILE" || true

echo
node --check "$API_FILE"
flutter analyze
echo "✅ 811 ferdig"
