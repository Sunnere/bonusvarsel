#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/api_service.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_804_2.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/services/api_service.dart")
text = p.read_text()

# 1) Fjern ALLE eksisterende threshold-metoder, både gyldige og ødelagte.
patterns = [
    r"""
    \n\s*static\s+Future<Map<String,\s*dynamic>>\s+getAutoPipelineThreshold\(\)\s+async\s*\{
    [\s\S]*?
    \n\s*\}
    """,
    r"""
    \n\s*static\s+Future<Map<String,\s*dynamic>>\s+setAutoPipelineThreshold\(num\s+threshold\)\s+async\s*\{
    [\s\S]*?
    \n\s*\}
    """,
]

removed = 0
for pat in patterns:
    new_text, count = re.subn(pat, "\n", text, count=10, flags=re.VERBOSE)
    text = new_text
    removed += count

# 2) Fjern evt. ødelagte rester rundt POST /v1/dev/auto-pipeline-threshold
garbage_patterns = [
    r"""
    \n\s*setAutoPipelineThreshold\(num\s+threshold\)\s+async\s*\{
    [\s\S]*?
    \n\s*\}
    """,
    r"""
    \n\s*getAutoPipelineThreshold\(\)\s+async\s*\{
    [\s\S]*?
    \n\s*\}
    """,
]

for pat in garbage_patterns:
    text = re.sub(pat, "\n", text, count=10, flags=re.VERBOSE)

# 3) Sett inn rene metoder inne i ApiService-klassen, rett før clearPushQueue hvis mulig.
insert_block = """
  static Future<Map<String, dynamic>> getAutoPipelineThreshold() async {
    final res = await http.get(_uri('/v1/dev/auto-pipeline-threshold'));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET /v1/dev/auto-pipeline-threshold failed: ${res.statusCode} ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'GET /v1/dev/auto-pipeline-threshold expected JSON object',
      );
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> setAutoPipelineThreshold(
    num threshold,
  ) async {
    final res = await http.post(
      _uri('/v1/dev/auto-pipeline-threshold'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'threshold': threshold}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'POST /v1/dev/auto-pipeline-threshold failed: ${res.statusCode} ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'POST /v1/dev/auto-pipeline-threshold expected JSON object',
      );
    }
    return decoded;
  }

"""

anchors = [
    "  static Future<Map<String, dynamic>> clearPushQueue() async {\n",
    "  static Future<Map<String, dynamic>> processPushQueue() async {\n",
    "}\n",
]

inserted = False
for anchor in anchors:
    if anchor in text:
        if anchor == "}\n":
            idx = text.rfind(anchor)
            if idx != -1:
                text = text[:idx] + insert_block + "\n" + text[idx:]
                inserted = True
                break
        else:
            text = text.replace(anchor, insert_block + anchor, 1)
            inserted = True
            break

if not inserted:
    raise SystemExit("❌ Fant ikke trygg plass å sette inn threshold-metodene")

# 4) Rydd bort store tomrom
text = re.sub(r"\n{4,}", "\n\n\n", text)

p.write_text(text)
print(f"✅ Reparerte ApiService threshold-metoder. Fjernet treff: {removed}")
PY

flutter analyze
echo "✅ 804.2 ferdig"
