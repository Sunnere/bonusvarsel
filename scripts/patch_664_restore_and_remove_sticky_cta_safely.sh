#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
RESTORE_FROM="lib/pages/premium_page.dart.bak_659_move_membership_above_plans_and_luxury_elite"

if [ ! -f "$RESTORE_FROM" ]; then
  echo "❌ Fant ikke backup: $RESTORE_FROM"
  exit 1
fi

cp "$RESTORE_FROM" "$FILE"
echo "✅ Gjenopprettet $FILE fra $RESTORE_FROM"

BACKUP_AFTER_RESTORE="${FILE}.bak_664_after_restore"
cp "$FILE" "$BACKUP_AFTER_RESTORE"
echo "✅ Ekstra backup laget: $BACKUP_AFTER_RESTORE"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()

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

original = text

# 1) Fjern bruk av _StickyCta(...)
needle = "_StickyCta("
idx = text.find(needle)
if idx != -1:
    paren_start = text.find("(", idx)
    paren_end = find_matching(text, paren_start, "(", ")")
    if paren_end == -1:
        print("❌ Fant _StickyCta( men klarte ikke å matche parentesene.")
        sys.exit(1)

    # ta med eventuell trailing komma og whitespace
    end = paren_end + 1
    while end < len(text) and text[end] in " \t":
        end += 1
    if end < len(text) and text[end] == ",":
        end += 1

    # forsøk å fjerne ytre Align(...) eller Positioned(...) hvis widgeten står alene der
    line_start = text.rfind("\n", 0, idx) + 1
    prefix = text[line_start:idx]

    removed_outer = False
    for outer in ("Align(", "Positioned("):
        outer_idx = text.rfind(outer, 0, idx)
        if outer_idx != -1:
            outer_line_start = text.rfind("\n", 0, outer_idx) + 1
            maybe_prefix = text[outer_line_start:outer_idx]
            # bare hvis det ikke er andre widget-kall mellom outer og _StickyCta
            middle = text[outer_idx:idx]
            if middle.count("(") - middle.count(")") >= 1:
                outer_paren_start = text.find("(", outer_idx)
                outer_paren_end = find_matching(text, outer_paren_start, "(", ")")
                if outer_paren_end != -1 and outer_paren_end >= paren_end:
                    outer_end = outer_paren_end + 1
                    while outer_end < len(text) and text[outer_end] in " \t":
                        outer_end += 1
                    if outer_end < len(text) and text[outer_end] == ",":
                        outer_end += 1
                    text = text[:outer_line_start] + text[outer_end:]
                    removed_outer = True
                    break

    if not removed_outer:
        text = text[:line_start] + text[end:]

# 2) Fjern hele _StickyCta-klassen hvis den finnes
class_needle = "class _StickyCta extends StatelessWidget"
cidx = text.find(class_needle)
if cidx != -1:
    brace_start = text.find("{", cidx)
    if brace_start == -1:
        print("❌ Fant _StickyCta-klassen men ikke åpningsklamme.")
        sys.exit(1)
    brace_end = find_matching(text, brace_start, "{", "}")
    if brace_end == -1:
        print("❌ Fant _StickyCta-klassen men ikke matchende sluttklamme.")
        sys.exit(1)

    # fjern hele klassen inkl. ledende blanklinjer
    class_line_start = text.rfind("\n", 0, cidx)
    if class_line_start == -1:
        class_line_start = 0
    else:
        while class_line_start > 0 and text[class_line_start - 1] == "\n":
            class_line_start -= 1

    text = text[:class_line_start] + text[brace_end + 1:]

# 3) enkel opprydding
while "\n\n\n" in text:
    text = text.replace("\n\n\n", "\n\n")

if text == original:
    print("⚠️ Ingen _StickyCta-bruk eller klasse ble fjernet.")
else:
    path.write_text(text)
    print("✅ Fjernet _StickyCta-bruk og _StickyCta-klassen trygt")
PY

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
