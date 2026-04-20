#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/api_service.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_804_1.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/services/api_service.dart")
text = p.read_text()

# Fjern ødelagte metoder hvis de finnes
text = re.sub(
    r"""
\s*static\s+Future<Map<String,\s*dynamic>>\s+getAutoPipelineThreshold\(\)\s+async\s*\{
[\s\S]*?
\s*\}
\s*
\s*static\s+Future<Map<String,\s*dynamic>>\s+setAutoPipelineThreshold\(num\s+threshold\)\s+async\s*\{
[\s\S]*?
\s*\}
""",
    "\n",
    text,
    count=1,
    flags=re.VERBOSE,
)

marker = "  static Future<Map<String, dynamic>> clearPushQueue() async {\n"
if marker not in text:
    raise SystemExit("❌ Fant ikke trygg anker-metode i ApiService")

insert = """  static Future<Map<String, dynamic>> getAutoPipelineThreshold() async {
    final res = await http.get(_uri('/v1/dev/auto-pipeline-threshold'));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET /v1/dev/auto-pipeline-threshold failed: ${res.statusCode} ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('GET /v1/dev/auto-pipeline-threshold expected JSON object');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> setAutoPipelineThreshold(num threshold) async {
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
      throw Exception('POST /v1/dev/auto-pipeline-threshold expected JSON object');
    }
    return decoded;
  }

"""

text = text.replace(marker, insert + marker, 1)

p.write_text(text)
print("✅ Fikset threshold-metoder i riktig ApiService-scope")
PY

flutter analyze
echo "✅ 804.1 ferdig"
