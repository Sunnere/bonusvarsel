#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/services/paywall_trigger_service.dart"

echo "==> patch_773_restore_missing_paywall_trigger_methods"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

cp "$TARGET" "$TARGET.bak_773_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

path = Path("lib/services/paywall_trigger_service.dart")
text = path.read_text()

# Sikre keys
if "_appOpenCountKey" not in text:
    text = text.replace(
        "  static const String _adClickCountKey = 'paywall_ad_click_count';\n"
        "  static const int _clicksBeforePrompt = 2;\n",
        "  static const String _adClickCountKey = 'paywall_ad_click_count';\n"
        "  static const String _appOpenCountKey = 'paywall_app_open_count';\n"
        "  static const String _scrollDepthSeenKey = 'paywall_scroll_depth_seen';\n"
        "  static const int _clicksBeforePrompt = 2;\n"
        "  static const int _appOpensBeforePrompt = 3;\n",
    )

# Legg inn manglende metoder før reset()
marker = "  static Future<void> reset() async {"
if marker not in text:
    raise SystemExit("❌ Fant ikke reset()-metoden å injisere før")

insertion = """
  static Future<void> registerAppOpen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_appOpenCountKey) ?? 0;
    final newCount = count + 1;
    await prefs.setInt(_appOpenCountKey, newCount);

    if (newCount >= _appOpensBeforePrompt) {
      await prefs.setInt(_appOpenCountKey, 0);
      final allowed = await _canShowPaywall();
      if (allowed && context.mounted) {
        await showPaywall(
          context,
          source: 'app_open',
          elite: false,
          title: 'Få maks bonuspoeng – automatisk',
          subtitle:
              'Lås opp smartere valg, høyere bonusrate og flere fordeler i Premium.',
        );
      }
    }
  }

  static Future<bool> hasSeenScrollDepth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_scrollDepthSeenKey) ?? false;
  }

  static Future<void> markScrollDepthSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scrollDepthSeenKey, true);
  }

"""

if "static Future<void> registerAppOpen(BuildContext context) async {" not in text:
    text = text.replace(marker, insertion + marker, 1)

# Utvid reset() til å rydde de nye key-ene
old_reset = """  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adClickCountKey);
  }"""

new_reset = """  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adClickCountKey);
    await prefs.remove(_appOpenCountKey);
    await prefs.remove(_scrollDepthSeenKey);
  }"""

if old_reset in text:
    text = text.replace(old_reset, new_reset, 1)

path.write_text(text)
print("✅ Gjenopprettet registerAppOpen / hasSeenScrollDepth / markScrollDepthSeen")
PY

echo
echo "==> Verifisering"
sed -n '1,240p' "$TARGET"

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) hvis bare warnings gjenstår: flutter run -d macos"
