#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/services/paywall_trigger_service.dart"

echo "==> patch_774_make_register_app_open_context_optional"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_774_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/services/paywall_trigger_service.dart")
text = path.read_text()

old_sig = "  static Future<void> registerAppOpen(BuildContext context) async {"
new_sig = "  static Future<void> registerAppOpen([BuildContext? context]) async {"

if old_sig in text:
    text = text.replace(old_sig, new_sig, 1)
else:
    # fallback regex
    text, n = re.subn(
        r"static Future<void> registerAppOpen\(BuildContext context\) async \{",
        "static Future<void> registerAppOpen([BuildContext? context]) async {",
        text,
        count=1,
    )
    if n == 0:
        raise SystemExit("❌ Fant ikke registerAppOpen-signaturen")

# make context usage null-safe
text = text.replace(
    "      if (allowed && context.mounted) {",
    "      if (allowed && context != null && context.mounted) {",
)

text = text.replace(
    "          context,",
    "          context,",
)

path.write_text(text)
print("✅ registerAppOpen gjør nå context valgfri")
PY

echo
echo "==> Verifisering"
grep -n "registerAppOpen" "$TARGET" || true

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) hvis bare warnings: flutter run -d macos"
