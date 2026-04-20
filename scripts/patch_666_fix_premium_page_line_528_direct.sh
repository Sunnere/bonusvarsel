#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_666_fix_premium_page_line_528_direct"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

echo
echo "==> Utdrag før fix (linje 520-532)"
nl -ba "$FILE" | sed -n '520,532p' || true

python3 - <<'PY'
from pathlib import Path

path = Path("lib/pages/premium_page.dart")
lines = path.read_text().splitlines()

start = 519   # 0-based ~= line 520
end = 532     # exclusive-ish for scanning
window = lines[start:end]

# Fjern sannsynlige hengende rester etter _StickyCta-fjerning
# Mål: linjer i dette området som bare er ")," eller "," eller tom widget-rest.
cleaned = []
removed = []

for i, line in enumerate(window):
    s = line.strip()

    # typiske hengende rester
    if s in {",", ")," , "),", "];"}:
        removed.append((start + i + 1, line))
        continue

    cleaned.append(line)

# Hvis ingenting ble fjernet, prøv litt smartere:
# fjern en enslig linje som bare er ")" eller "]" med trailing comma-lignende rest
if not removed:
    cleaned = []
    for i, line in enumerate(window):
        s = line.strip()
        if s in {")", "]", "],", "),"} and 520 <= (start + i + 1) <= 532:
            # behold normalt lukkere, men fjern hvis de står alene mellom andre lukkere
            prev_nonempty = None
            next_nonempty = None

            for j in range(i - 1, -1, -1):
                if window[j].strip():
                    prev_nonempty = window[j].strip()
                    break
            for j in range(i + 1, len(window)):
                if window[j].strip():
                    next_nonempty = window[j].strip()
                    break

            if prev_nonempty in {"]", "],", ")", "),"} or next_nonempty in {"]", "],", ")", "),", "};", "}", "};"}:
                removed.append((start + i + 1, line))
                continue
        cleaned.append(line)

new_lines = lines[:start] + cleaned + lines[end:]
path.write_text("\n".join(new_lines) + "\n")

print(f"✅ Fjernet {len(removed)} mistenkelig(e) linje(r)")
for lineno, content in removed:
    print(f"   - linje {lineno}: {content!r}")
PY

echo
echo "==> Utdrag etter fix (linje 520-532)"
nl -ba "$FILE" | sed -n '520,532p' || true

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
