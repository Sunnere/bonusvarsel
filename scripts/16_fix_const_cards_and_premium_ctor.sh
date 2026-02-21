#!/usr/bin/env bash
set -euo pipefail

fix_remove_const_on_line() {
  local file="$1"
  local line_no="$2"

  [ -f "$file" ] || { echo "Fant ikke $file"; return 0; }
  cp "$file" "$file.bak.$(date +%s)"

  python - "$file" "$line_no" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
line_no = int(sys.argv[2])

lines = p.read_text(encoding="utf-8").splitlines(True)
i = line_no - 1
if 0 <= i < len(lines):
  # Fjern kun "const " hvis linja faktisk starter med det (etter innrykk)
  import re
  lines[i] = re.sub(r'^(\s*)const\s+', r'\1', lines[i])
p.write_text("".join(lines), encoding="utf-8")
PY
  echo "✅ Fjernet ev. 'const' på linje $line_no i $file"
}

fix_make_ctor_const_if_possible() {
  local file="$1"
  local class_name="$2"

  [ -f "$file" ] || { echo "Fant ikke $file"; return 0; }
  cp "$file" "$file.bak.$(date +%s)"

  python - "$file" "$class_name" <<'PY'
from pathlib import Path
import re, sys

p = Path(sys.argv[1])
cls = sys.argv[2]
s = p.read_text(encoding="utf-8")

# Bytt:  PremiumPage({super.key});
# til:   const PremiumPage({super.key});
pat = rf'(^\s*)(?!const\s+)({re.escape(cls)}\s*\(\s*\{{\s*super\.key\s*\}}\s*\)\s*;)'  # constructor line
m = re.search(pat, s, flags=re.MULTILINE)
if m:
  s = re.sub(pat, r'\1const \2', s, flags=re.MULTILINE)
  p.write_text(s, encoding="utf-8")
  print(f"✅ Satt const constructor for {cls} i {p}")
else:
  print(f"ℹ️ Fant ikke enkel ctor-linje å gjøre const i {p} (hopper over).")
PY
}

# 1) Fix cards_page.dart: feilen sier "cards_page.dart:9:12 const_with_non_const"
fix_remove_const_on_line "lib/pages/cards_page.dart" 9

# 2) Info: prefer_const_constructors_in_immutables i premium_page.dart -> prøv å gjøre ctor const
fix_make_ctor_const_if_possible "lib/pages/premium_page.dart" "PremiumPage"

dart format lib/pages/cards_page.dart lib/pages/premium_page.dart || true
flutter analyze
