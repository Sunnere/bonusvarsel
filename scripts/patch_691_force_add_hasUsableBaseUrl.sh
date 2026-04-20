#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/api_service.dart"

cp "$FILE" "${FILE}.bak_691_force_add_hasUsableBaseUrl"

awk '
BEGIN { inserted=0 }

/class ApiService/ {
  print $0
  if (!inserted) {
    print ""
    print "  bool _hasUsableBaseUrl() {"
    print "    final raw = baseUrl.trim();"
    print "    if (raw.isEmpty) return false;"
    print "    if (raw.contains(\"127.0.0.1\")) return false;"
    print "    if (raw.contains(\"localhost\")) return false;"
    print "    return true;"
    print "  }"
    print ""
    inserted=1
  }
  next
}

{ print }
' "$FILE" > "${FILE}.tmp"

mv "${FILE}.tmp" "$FILE"

echo "✅ _hasUsableBaseUrl lagt inn"
