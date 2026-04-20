#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/api_service.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_817.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/services/api_service.dart")
text = p.read_text()
original = text

old = """  static Future<Map<String, dynamic>> getHealth() async {
    return _getMap('/v1/health');
  }
"""

new = """  static Future<Map<String, dynamic>> getHealth() async {
    try {
      return await _getMap('/v1/health');
    } catch (_) {
      return _getMap('/health');
    }
  }
"""

if old not in text:
    raise SystemExit("❌ Fant ikke getHealth()-blokken i api_service.dart")

text = text.replace(old, new, 1)

if text == original:
    raise SystemExit("❌ Ingen endring gjort")

p.write_text(text)
print("✅ La inn fallback fra /v1/health til /health")
PY

flutter analyze
echo "✅ 817 ferdig"
