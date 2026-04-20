#!/usr/bin/env bash
set -euo pipefail

PAGE="lib/pages/premium_page.dart"
API="lib/services/api_service.dart"

if [ ! -f "$PAGE" ]; then
  echo "❌ Fant ikke $PAGE"
  exit 1
fi

if [ ! -f "$API" ]; then
  echo "❌ Fant ikke $API"
  exit 1
fi

cp "$PAGE" "${PAGE}.bak_689_force_insert"
cp "$API" "${API}.bak_689_force_insert"
echo "✅ Backup laget"

python3 - <<'PY'
from pathlib import Path
import re
import sys

page = Path("lib/pages/premium_page.dart")
api = Path("lib/services/api_service.dart")

page_text = page.read_text()
api_text = api.read_text()

page_changed = False
api_changed = False

# -----------------------------
# premium_page.dart
# -----------------------------
if "_billingCycle" not in page_text:
    # Sett inn rett etter class _PremiumPageState ... {
    pat = re.compile(r"(class\s+_PremiumPageState\s+extends\s+State<PremiumPage>\s*\{\n)")
    repl = r"\1  String _billingCycle = 'monthly';\n"
    new_text, count = pat.subn(repl, page_text, count=1)
    if count:
        page_text = new_text
        page_changed = True

# Fallback: sett inn rett etter _selected hvis det finnes
if "_billingCycle" not in page_text:
    pat = re.compile(r"(String\s+_selected\s*=\s*'Premium';[^\n]*\n)")
    repl = r"\1  String _billingCycle = 'monthly';\n"
    new_text, count = pat.subn(repl, page_text, count=1)
    if count:
        page_text = new_text
        page_changed = True

# Optional: replace print with debugPrint to remove lint later, harmless
page_text = page_text.replace("print('Checkout payload: $payload');", "debugPrint('Checkout payload: $payload');")

# -----------------------------
# api_service.dart
# -----------------------------
if "_hasUsableBaseUrl()" not in api_text:
    pat = re.compile(r"(class\s+ApiService\s*\{\n)")
    repl = r"""\1  bool _hasUsableBaseUrl() {
    final raw = baseUrl.trim();
    if (raw.isEmpty) return false;
    if (raw.contains('127.0.0.1')) return false;
    if (raw.contains('localhost')) return false;
    return true;
  }

"""
    new_text, count = pat.subn(repl, api_text, count=1)
    if count:
        api_text = new_text
        api_changed = True

# If call exists but helper absent due weird formatting, also add before first getter as fallback
if "_hasUsableBaseUrl()" not in api_text:
    pat = re.compile(r"(\s+String\s+get\s+baseUrl\b)")
    repl = """  bool _hasUsableBaseUrl() {
    final raw = baseUrl.trim();
    if (raw.isEmpty) return false;
    if (raw.contains('127.0.0.1')) return false;
    if (raw.contains('localhost')) return false;
    return true;
  }

\\1"""
    new_text, count = pat.subn(repl, api_text, count=1)
    if count:
        api_text = new_text
        api_changed = True

# Write files
page.write_text(page_text)
api.write_text(api_text)

print("premium_page.dart:", "changed" if page_changed else "unchanged")
print("api_service.dart:", "changed" if api_changed else "unchanged")
PY

echo
echo "==> Verifiser"
grep -n "_billingCycle" "$PAGE" || true
grep -n "_hasUsableBaseUrl" "$API" || true

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør:"
echo "  flutter run -d 00008110-001138643E60401E"
