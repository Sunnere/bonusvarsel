#!/usr/bin/env bash
set -euo pipefail

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/services/eb_repository.dart")
if not p.exists():
    raise SystemExit("Fant ikke lib/services/eb_repository.dart")

s = p.read_text(encoding="utf-8")

# Fjern "unnecessary_cast" typiske mønstre fra jsonDecode
# Eksempler vi rydder:
#   jsonDecode(x) as Map<String, dynamic>
#   jsonDecode(x) as List<dynamic>
#   (jsonDecode(x) as Map<String, dynamic>)  -> jsonDecode(x)
s2 = s

s2 = re.sub(r"\(\s*jsonDecode\(([^)]+)\)\s+as\s+Map<String,\s*dynamic>\s*\)", r"jsonDecode(\1)", s2)
s2 = re.sub(r"\(\s*jsonDecode\(([^)]+)\)\s+as\s+List<dynamic>\s*\)", r"jsonDecode(\1)", s2)

s2 = re.sub(r"jsonDecode\(([^)]+)\)\s+as\s+Map<String,\s*dynamic>", r"jsonDecode(\1)", s2)
s2 = re.sub(r"jsonDecode\(([^)]+)\)\s+as\s+List<dynamic>", r"jsonDecode(\1)", s2)

if s2 != s:
    p.write_text(s2, encoding="utf-8")
    print("Ryddet casts i:", p)
else:
    print("Ingen casts å rydde i:", p)
PY

dart format lib/services/eb_repository.dart
flutter analyze
