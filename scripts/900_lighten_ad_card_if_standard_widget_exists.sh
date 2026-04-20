#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/ad_slot_card.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE (hopper over lysning av annonsekort)"; exit 1; }

cp "$FILE" "$FILE.bak_900.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/ad_slot_card.dart")
text = p.read_text()
orig = text

# Forsiktig: bare enkle fargelettinger dersom vanlige mønstre finnes
text = text.replace("0xFF0B1F4D", "0xFF17305F")
text = text.replace("0xFF0F172A", "0xFF1A2742")
text = text.replace("0xFF111827", "0xFF1B2A45")
text = text.replace("alpha: 0.15", "alpha: 0.22")
text = text.replace("alpha: 0.16", "alpha: 0.24")

if text == orig:
    raise SystemExit("❌ Fant ingen kjente annonsefarger å lysne trygt")

p.write_text(text)
print("✅ Lysnet annonsekort litt")
PY

flutter analyze
echo "✅ 900 ferdig"
