#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/api_service.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_818.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/services/api_service.dart")
text = p.read_text()
original = text

pattern = re.compile(
    r"""
  static\s+Future<Map<String,\s*dynamic>>\s+simulateCampaignPipeline\(\{
    [\s\S]*?
  \}\n
""",
    re.VERBOSE,
)

replacement = """  static Future<Map<String, dynamic>> simulateCampaignPipeline({
    Map<String, dynamic>? body,
  }) async {
    final payload = body ?? <String, dynamic>{};

    final paths = <String>[
      '/v1/dev/simulate-campaign',
      '/dev/simulate-campaign',
      '/v1/dev/pipeline/simulate',
      '/v1/dev/simulate',
      '/dev/simulate',
    ];

    Object? lastError;

    for (final path in paths) {
      try {
        final res = await http
            .post(
              _uri(path),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 6));

        if (res.statusCode < 200 || res.statusCode >= 300) {
          lastError = 'POST $path failed: ${res.statusCode} ${res.body}';
          continue;
        }

        final decoded = jsonDecode(res.body);
        if (decoded is! Map<String, dynamic>) {
          lastError = 'POST $path expected JSON object';
          continue;
        }

        return decoded;
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('simulateCampaignPipeline failed on all paths: $lastError');
  }

"""

new_text, count = pattern.subn(replacement, text, count=1)

if count != 1:
    raise SystemExit("❌ Fant ikke simulateCampaignPipeline()-blokken")

text = new_text

if text == original:
    raise SystemExit("❌ Ingen endring gjort")

p.write_text(text)
print("✅ Gjorde simulateCampaignPipeline robust med fallback paths")
PY

flutter analyze
echo "✅ 818 ferdig"
