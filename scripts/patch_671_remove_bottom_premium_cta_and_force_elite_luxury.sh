#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_671_remove_bottom_premium_cta_and_force_elite_luxury"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

def find_matching(s: str, start: int, open_ch: str, close_ch: str) -> int:
    depth = 0
    in_single = False
    in_double = False
    i = start
    while i < len(s):
        ch = s[i]
        prev = s[i - 1] if i > 0 else ""
        if ch == "'" and not in_double and prev != "\\":
            in_single = not in_single
        elif ch == '"' and not in_single and prev != "\\":
            in_double = not in_double
        elif not in_single and not in_double:
            if ch == open_ch:
                depth += 1
            elif ch == close_ch:
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1

changed = False

# ------------------------------------------------------------
# 1) Fjern bruk av _StickyCta(...) nederst på siden
# ------------------------------------------------------------
needle = "_StickyCta("
idx = text.find(needle)
if idx != -1:
    paren_start = text.find("(", idx)
    paren_end = find_matching(text, paren_start, "(", ")")
    if paren_end != -1:
        line_start = text.rfind("\n", 0, idx) + 1
        end = paren_end + 1
        while end < len(text) and text[end] in " \t":
            end += 1
        if end < len(text) and text[end] == ",":
            end += 1

        # prøv å ta med ytre Positioned/Align hvis den står alene
        outer_removed = False
        for outer in ("Positioned(", "Align(", "SafeArea("):
            outer_idx = text.rfind(outer, 0, idx)
            if outer_idx != -1:
                outer_line_start = text.rfind("\n", 0, outer_idx) + 1
                outer_paren_start = text.find("(", outer_idx)
                outer_paren_end = find_matching(text, outer_paren_start, "(", ")")
                if outer_paren_end != -1 and outer_paren_end >= paren_end:
                    outer_end = outer_paren_end + 1
                    while outer_end < len(text) and text[outer_end] in " \t":
                        outer_end += 1
                    if outer_end < len(text) and text[outer_end] == ",":
                        outer_end += 1
                    text = text[:outer_line_start] + text[outer_end:]
                    changed = True
                    outer_removed = True
                    break

        if not outer_removed:
            text = text[:line_start] + text[end:]
            changed = True

# Fjern selve klassen også hvis den finnes
class_needle = "class _StickyCta extends StatelessWidget"
cidx = text.find(class_needle)
if cidx != -1:
    brace_start = text.find("{", cidx)
    if brace_start != -1:
        brace_end = find_matching(text, brace_start, "{", "}")
        if brace_end != -1:
            class_line_start = text.rfind("\n", 0, cidx)
            if class_line_start == -1:
                class_line_start = 0
            else:
                while class_line_start > 0 and text[class_line_start - 1] == "\n":
                    class_line_start -= 1
            text = text[:class_line_start] + text[brace_end + 1:]
            changed = True

# ------------------------------------------------------------
# 2) Force Elite luksus i den faktiske plan-kort-wigdeten
#    Vi patcher generiske farger der title/selected brukes.
# ------------------------------------------------------------

# A) borderColor = Elite -> gull
text2 = re.sub(
    r"final\s+borderColor\s*=\s*selected\s*\?\s*accent\s*:\s*([^;]+);",
    r"final borderColor = selected ? (title == 'Elite' ? const Color(0xFFD4AF37) : accent) : \1;",
    text,
    count=1,
)
if text2 != text:
    text = text2
    changed = True

# B) bg = Elite -> mørk blå/lilla
text2 = re.sub(
    r"final\s+bg\s*=\s*selected\s*\?\s*([^;]+)\s*:\s*([^;]+);",
    "final bg = selected ? (title == 'Elite' ? const Color(0xFF1A1740) : \\1) : \\2;",
    text,
    count=1,
)
if text2 != text:
    text = text2
    changed = True

# C) elite title text color / badge accent
text2 = text.replace(
    "color: selected ? accent :",
    "color: selected ? (title == 'Elite' ? const Color(0xFFD4AF37) : accent) :",
    1,
)
if text2 != text:
    text = text2
    changed = True

# D) hvis Elite-kortet har subtitle/description om maks poeng
text2 = text.replace(
    "'Elite: maks poeng & flere programmer'",
    "'Elite: luksusnivå med maks poengverdi'",
)
if text2 != text:
    text = text2
    changed = True

# E) hvis accent er statisk i build, bruk dynamisk accent når Elite er valgt
text2 = text.replace(
    "final accent = const Color(0xFFF0D48A);",
    "final accent = _selected == 'Elite' ? const Color(0xFFD4AF37) : const Color(0xFFF0D48A);",
)
if text2 != text:
    text = text2
    changed = True

# ------------------------------------------------------------
# 3) Opprydding av tomme linjer
# ------------------------------------------------------------
while "\n\n\n" in text:
    text = text.replace("\n\n\n", "\n\n")

if not changed:
    print("⚠️ Ingen treffsikre endringer ble gjort. Filen ble ikke endret.")
    sys.exit(2)

path.write_text(text)
print("✅ Fjernet nederste CTA og forsøkte å tvinge Elite-luksus i faktisk kort-widget")
PY

echo
echo "==> Vis relevante utdrag"
echo "-- Sticky / bottom area --"
grep -n "_StickyCta\|Oppgrader\|Premium: full rate\|Elite: luksusnivå" "$FILE" || true

echo
echo "-- Elite / border / bg --"
grep -n "borderColor\|final bg =\|title == 'Elite'\|D4AF37\|1A1740" "$FILE" || true

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter run -d 00008110-001138643E60401E"
