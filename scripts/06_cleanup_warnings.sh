#!/usr/bin/env bash
set -euo pipefail

echo "== [6] Cleanup warnings/deprecations =="

FILES=(
  "lib/main.dart"
  "lib/pages/eb_shopping_page.dart"
  "lib/pages/premium_page.dart"
  "lib/services/eb_repository.dart"
)

for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    cp "$f" "$f.bak.$(date +%s)"
  fi
done

python - <<'PY'
from pathlib import Path
import re
import math

def read(p): return Path(p).read_text(encoding="utf-8")
def write(p,s): Path(p).write_text(s, encoding="utf-8")

changed = 0

# -------------------------
# lib/main.dart
# -------------------------
p = Path("lib/main.dart")
if p.exists():
  s = read(p)

  # 1) ColorScheme background -> surface (deprecation)
  # Begrens til colorScheme copyWith/ColorScheme(...) kontekst (best effort)
  s2 = s
  # copyWith( ... background: X, ... ) -> surface: X,
  s2 = re.sub(r"(colorScheme\s*:\s*[^;{]*?copyWith\([\s\S]*?)\bbackground\s*:",
              r"\1surface:", s2, flags=re.M)
  # ColorScheme( ... background: X, ... ) -> surface: X,
  s2 = re.sub(r"(ColorScheme\([\s\S]*?)\bbackground\s*:",
              r"\1surface:", s2, flags=re.M)

  # 2) withOpacity(x) -> withAlpha(int) (unngå deprecated)
  def repl_opacity(m):
    val = float(m.group(1))
    a = max(0, min(255, int(round(val*255))))
    return f".withAlpha({a})"
  s2 = re.sub(r"\.withOpacity\(\s*([01](?:\.\d+)?)\s*\)", repl_opacity, s2)

  if s2 != s:
    write(p, s2)
    changed += 1

# -------------------------
# lib/pages/premium_page.dart
# -------------------------
p = Path("lib/pages/premium_page.dart")
if p.exists():
  s = read(p)
  s2 = s

  # Switch/Checkbox activeColor -> activeThumbColor (best effort)
  s2 = re.sub(r"\bactiveColor\s*:", "activeThumbColor:", s2)

  # withOpacity -> withAlpha
  def repl_opacity(m):
    val = float(m.group(1))
    a = max(0, min(255, int(round(val*255))))
    return f".withAlpha({a})"
  s2 = re.sub(r"\.withOpacity\(\s*([01](?:\.\d+)?)\s*\)", repl_opacity, s2)

  if s2 != s:
    write(p, s2)
    changed += 1

# -------------------------
# lib/pages/eb_shopping_page.dart
# -------------------------
p = Path("lib/pages/eb_shopping_page.dart")
if p.exists():
  s = read(p)
  s2 = s

  # DropdownButtonFormField value: -> initialValue: (deprecation i FormField)
  # Treffer KUN når det står DropdownButtonFormField<...>( ... value: ...)
  s2 = re.sub(
    r"(DropdownButtonFormField<[^>]+>\([\s\S]*?)\bvalue\s*:",
    r"\1initialValue:",
    s2
  )

  # Fjern private helpers/fields som aldri brukes (best effort)
  # _open (funksjon) som ikke refereres
  s2 = re.sub(r"\n\s*Future<[^>]*>\s+_open\([\s\S]*?\n\s*\}\n", "\n", s2)
  s2 = re.sub(r"\n\s*void\s+_open\([\s\S]*?\n\s*\}\n", "\n", s2)

  # Ubrukte private felter _shopName/_shopRate/_shopUrl hvis de finnes som "String? _shopName;" etc
  s2 = re.sub(r"^\s*(String\??|int\??|double\??)\s+_shop(Name|Rate|Url)\s*=\s*[^;]*;\s*$\n", "", s2, flags=re.M)
  s2 = re.sub(r"^\s*(String\??|int\??|double\??)\s+_shop(Name|Rate|Url)\s*;\s*$\n", "", s2, flags=re.M)

  if s2 != s:
    write(p, s2)
    changed += 1

# -------------------------
# lib/services/eb_repository.dart
# -------------------------
p = Path("lib/services/eb_repository.dart")
if p.exists():
  s = read(p)
  s2 = s

  # curly_braces_in_flow_control_structures: gjør "if (cond) stmt;" -> "if (cond) { stmt; }"
  # Best effort: kun for enkle if-linjer (ikke else, ikke blokker)
  s2 = re.sub(
    r"(^\s*if\s*\([^\)]*\)\s*)([^{\n;][^\n;]*;)\s*$",
    r"\1{\n  \2\n}",
    s2,
    flags=re.M
  )

  # unnecessary_cast: fjern "as dynamic"/"as Map<String, dynamic>" i enkle tilfeller (best effort)
  s2 = re.sub(r"\s+as\s+dynamic\b", "", s2)
  s2 = re.sub(r"\s+as\s+Map<String,\s*dynamic>\b", "", s2)
  s2 = re.sub(r"\s+as\s+List<Map<String,\s*dynamic>>\b", "", s2)

  if s2 != s:
    write(p, s2)
    changed += 1

print(f"Patched files: {changed}")
PY

dart format lib/main.dart lib/pages/eb_shopping_page.dart lib/pages/premium_page.dart lib/services/eb_repository.dart
flutter analyze

echo "== [6] Done =="
