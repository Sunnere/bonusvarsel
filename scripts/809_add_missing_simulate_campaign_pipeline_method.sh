#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/api_service.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_809.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/services/api_service.dart")
text = p.read_text()

if "static Future<Map<String, dynamic>> simulateCampaignPipeline(" in text:
    print("ℹ️ simulateCampaignPipeline finnes allerede")
    raise SystemExit(0)

method = """
  static Future<Map<String, dynamic>> simulateCampaignPipeline({
    Map<String, dynamic>? body,
  }) async {
    final payload = body ?? <String, dynamic>{};

    final paths = <String>[
      '/dev/simulate-campaign',
      '/v1/dev/simulate-campaign',
      '/v1/dev/pipeline/simulate',
      '/dev/simulate',
      '/v1/dev/simulate',
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

    throw Exception(
      'simulateCampaignPipeline failed on all paths: $lastError',
    );
  }

"""

anchors = [
    "  static Future<Map<String, dynamic>> seedDevOffer({\n",
    "  static Future<Map<String, dynamic>> getPushDispatchPreview({\n",
    "}\n",
]

inserted = False
for anchor in anchors:
    if anchor in text:
        if anchor == "}\n":
            idx = text.rfind(anchor)
            text = text[:idx] + method + "\n" + text[idx:]
            inserted = True
            break
        else:
            text = text.replace(anchor, method + anchor, 1)
            inserted = True
            break

if not inserted:
    raise SystemExit("❌ Fant ikke trygg plass å sette inn simulateCampaignPipeline()")

p.write_text(text)
print("✅ La inn simulateCampaignPipeline() i ApiService")
PY

flutter analyze
echo "✅ 809 ferdig"
