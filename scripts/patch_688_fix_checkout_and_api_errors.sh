#!/usr/bin/env bash
set -euo pipefail

PAGE="lib/pages/premium_page.dart"
API="lib/services/api_service.dart"

cp "$PAGE" "${PAGE}.bak_688_fix"
cp "$API" "${API}.bak_688_fix"

echo "✅ Backup laget"

python3 - <<'PY'
from pathlib import Path

# ---------- FIX 1: billingCycle ----------
page = Path("lib/pages/premium_page.dart")
text = page.read_text()

if "_billingCycle" not in text:
    text = text.replace(
        "String _selected = 'Premium';",
        "String _selected = 'Premium';\n  String _billingCycle = 'monthly';"
    )

# fallback hvis replace ikke traff
if "_billingCycle" not in text:
    text = text.replace(
        "class _PremiumPageState extends State<PremiumPage> {",
        "class _PremiumPageState extends State<PremiumPage> {\n  String _billingCycle = 'monthly';"
    )

page.write_text(text)
print("✅ billingCycle lagt inn")


# ---------- FIX 2: hasUsableBaseUrl ----------
api = Path("lib/services/api_service.dart")
text = api.read_text()

if "_hasUsableBaseUrl()" not in text:
    insert = """

  bool _hasUsableBaseUrl() {
    final raw = baseUrl.trim();
    if (raw.isEmpty) return false;
    if (raw.contains('127.0.0.1')) return false;
    if (raw.contains('localhost')) return false;
    return true;
  }

"""

    # legg rett etter class ApiService
    text = text.replace(
        "class ApiService {",
        "class ApiService {" + insert
    )

api.write_text(text)
print("✅ hasUsableBaseUrl lagt inn")

PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør:"
echo "  flutter run -d 00008110-001138643E60401E"
