#!/usr/bin/env bash
set -euo pipefail

echo "==> 754_force_light_travel_form_and_readable_cards"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_754")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

changes = 0

# 1) Gjør "hero"/mørke kort lyse i travel_page
new = text.replace(
    "color: _heroOcean,",
    "color: const Color(0xFFF8FBFD),"
)
if new != text:
    changes += 1
    text = new

# 2) Gjør hero title/body mørke og lesbare
new = re.sub(
    r"TextStyle _heroTitleStyle\(BuildContext context\) \{.*?\n  \}",
    """TextStyle _heroTitleStyle(BuildContext context) {
    return (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w900,
      color: const Color(0xFF10252B),
    );
  }""",
    text,
    flags=re.DOTALL
)
if new != text:
    changes += 1
    text = new

new = re.sub(
    r"TextStyle _heroBodyStyle\(BuildContext context\) \{.*?\n  \}",
    """TextStyle _heroBodyStyle(BuildContext context) {
    return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: const Color(0xFF243940),
      fontWeight: FontWeight.w600,
      height: 1.35,
    );
  }""",
    text,
    flags=re.DOTALL
)
if new != text:
    changes += 1
    text = new

# 3) Tving alle InputDecoration i travel_page til lys stil
# erstatt const InputDecoration -> InputDecoration med eksplisitte felter
new = re.sub(
    r"decoration:\s*const InputDecoration\(",
    """decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF4F7FB),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  alignLabelWithHint: true,
                  labelStyle: const TextStyle(
                    color: Color(0xFF243940),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Color(0xFF10252B),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD9E3EE), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD9E3EE), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF8FB8C5), width: 1.3),
                  ),
""",
    text
)
if new != text:
    changes += 1
    text = new

# 4) Også for ikke-const InputDecoration
new = re.sub(
    r"decoration:\s*InputDecoration\(",
    """decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF4F7FB),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  alignLabelWithHint: true,
                  labelStyle: const TextStyle(
                    color: Color(0xFF243940),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: Color(0xFF10252B),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD9E3EE), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD9E3EE), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF8FB8C5), width: 1.3),
                  ),
""",
    text,
    count=2
)
# count begrenser litt for å unngå total overpatch
if new != text:
    changes += 1
    text = new

# 5) Fjern duplikater som kan oppstå
for dup in [
    ("filled: true,\n                  filled: true,\n", "filled: true,\n"),
    ("fillColor: const Color(0xFFF4F7FB),\n                  fillColor: const Color(0xFFF4F7FB),\n", "fillColor: const Color(0xFFF4F7FB),\n"),
    ("floatingLabelBehavior: FloatingLabelBehavior.always,\n                  floatingLabelBehavior: FloatingLabelBehavior.always,\n", "floatingLabelBehavior: FloatingLabelBehavior.always,\n"),
    ("alignLabelWithHint: true,\n                  alignLabelWithHint: true,\n", "alignLabelWithHint: true,\n"),
]:
    text = text.replace(dup[0], dup[1])

# 6) Gjør dropdowns hvite og tydelige
new = re.sub(
    r"DropdownButtonFormField<([^>]+)>\(",
    r"DropdownButtonFormField<\1>(\n                dropdownColor: Colors.white,",
    text
)
if new != text:
    changes += 1
    text = new

# 7) Gjør feltene høyere
for old in ["height: 44,", "height: 60,", "height: 68,"]:
    if old in text:
        text = text.replace(old, "height: 72,")
        changes += 1

# 8) Gjør poengplan-kort mer synlig
new = text.replace(
    "color: const Color(0xFFF0E1B8),",
    "color: const Color(0xFFF2E4B9),"
)
if new != text:
    changes += 1
    text = new

# 9) Gjør mørk tekst enda mørkere
for old, newv in [
    ("const Color(0xFF1C3036)", "const Color(0xFF10252B)"),
    ("const Color(0xFF1F3941)", "const Color(0xFF10252B)"),
    ("const Color(0xFF2E4951)", "const Color(0xFF243940)"),
]:
    if old in text:
        text = text.replace(old, newv)
        changes += 1

# 10) Seksjonstitler større og tydeligere
new = re.sub(
    r"TextStyle _sectionTitleStyle\(BuildContext context\) \{.*?\n  \}",
    """TextStyle _sectionTitleStyle(BuildContext context) {
    return (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w900,
      fontSize: 22,
      color: const Color(0xFF10252B),
    );
  }""",
    text,
    flags=re.DOTALL
)
if new != text:
    changes += 1
    text = new

if text == original or changes == 0:
    print("ERROR: Ingen endringer ble truffet. Stopper for å unngå falsk suksess.")
    raise SystemExit(1)

path.write_text(text)
print(f"Patched: {path}")
print(f"Endringsblokker: {changes}")
PY

echo
echo "✅ 754 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
