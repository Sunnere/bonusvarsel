#!/usr/bin/env bash
set -euo pipefail

FILE="lib/main.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/main.dart")
s = p.read_text(encoding="utf-8")

# 1) Fix deprecated "background:" -> "surface:" (Material 3)
s = re.sub(r"\bbackground\s*:", "surface:", s)

# 2) Ensure useMaterial3: true in ThemeData(...)
def ensure_use_material3(text: str) -> str:
    # If already present, do nothing
    if re.search(r"ThemeData\([\s\S]{0,300}useMaterial3\s*:\s*true", text):
        return text
    # Insert right after first ThemeData(
    return re.sub(r"ThemeData\(", "ThemeData(\n    useMaterial3: true,", text, count=1)

s = ensure_use_material3(s)

# 3) Add/replace premium-ish component themes in base.copyWith(...)
m = re.search(r"return\s+base\.copyWith\(\s*", s)
if not m:
    raise SystemExit("Fant ikke 'return base.copyWith(' i lib/main.dart. Åpne main.dart og sjekk at du fortsatt bygger theme via base.copyWith.")

# helper to upsert a named parameter inside copyWith(...)
def upsert_named_param(block: str, name: str, value: str) -> str:
    # Replace existing param if present
    pattern = rf"{name}\s*:\s*[^,]+\),"
    if re.search(pattern, block, flags=re.S):
        block = re.sub(pattern, f"{name}: {value},", block, flags=re.S)
        return block
    # Else insert near top (after colorScheme if possible)
    insert_after = re.search(r"colorScheme\s*:\s*[^,]+\),", block, flags=re.S)
    if insert_after:
        i = insert_after.end()
        return block[:i] + "\n\n      " + f"{name}: {value}," + block[i:]
    # fallback: insert right after copyWith(
    return re.sub(r"(base\.copyWith\()\s*", r"\1\n      " + f"{name}: {value},\n\n      ", block, count=1)

# Extract the copyWith(...) argument block (simple balanced-ish approach: from base.copyWith( to the next ");" at same indent)
start = m.start()
tail = s[start:]
end = tail.find(");")
if end == -1:
    raise SystemExit("Fant ikke slutten ');' etter base.copyWith(...).")
copy_block = tail[:end+2]

# Values (keep them const-friendly and Material3-friendly)
card_theme = """const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      )"""

input_theme = """const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      )"""

list_tile_theme = """const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        subtitleTextStyle: TextStyle(fontSize: 13),
      )"""

chip_theme = """ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
      )"""

# Upsert themes
copy_block2 = copy_block
copy_block2 = upsert_named_param(copy_block2, "cardTheme", card_theme)
copy_block2 = upsert_named_param(copy_block2, "inputDecorationTheme", input_theme)
copy_block2 = upsert_named_param(copy_block2, "listTileTheme", list_tile_theme)

# Only set chipTheme if not already customized heavily; otherwise keep existing and just leave it.
if "chipTheme:" not in copy_block2:
    copy_block2 = upsert_named_param(copy_block2, "chipTheme", chip_theme)

# Scaffold background + AppBar polish
# If scaffoldBackgroundColor is missing, add it
if "scaffoldBackgroundColor:" not in copy_block2:
    copy_block2 = upsert_named_param(copy_block2, "scaffoldBackgroundColor", "const Color(0xFFF7F7F8)")

# Replace appBarTheme block to cleaner M3-like if present (safe-ish replace)
copy_block2 = re.sub(
    r"appBarTheme\s*:\s*const\s*AppBarTheme\([\s\S]*?\)\s*,",
    """appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFFF7F7F8),
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
      ),""",
    copy_block2,
    flags=re.S,
)

# Write back
s2 = s[:start] + copy_block2 + s[start+len(copy_block):]
p.write_text(s2, encoding="utf-8")
print("✅ Premium theme patch lagt på lib/main.dart")
PY

dart format lib/main.dart
flutter analyze
