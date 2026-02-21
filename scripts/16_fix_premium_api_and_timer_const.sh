#!/usr/bin/env bash
set -euo pipefail

# 1) PremiumService: gi stabilt API som resten av koden forventer
PREM="lib/services/premium_service.dart"
mkdir -p lib/services
[ -f "$PREM" ] && cp "$PREM" "$PREM.bak.$(date +%s)" || true

cat > "$PREM" <<'DART'
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  const PremiumService();

  static const String _kIsPremium = 'is_premium';

  Future<bool> getIsPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsPremium) ?? false;
  }

  /// Alias (noen steder kaller dette)
  Future<bool> isPremium() => getIsPremium();

  Future<void> setIsPremium(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, v);
  }

  /// Placeholder restore (til du kobler på IAP/RevenueCat)
  Future<void> restore() async {
    // No-op for nå. Når du har kjøp: hent purchases -> setIsPremium(true/false)
  }
}
DART

# 2) PremiumBadge: bruk getIsPremium() (eller isPremium())
BADGE="lib/widgets/premium_badge.dart"
if [ -f "$BADGE" ]; then
  cp "$BADGE" "$BADGE.bak.$(date +%s)" || true
  python3 - <<'PY'
import re, pathlib
p = pathlib.Path("lib/widgets/premium_badge.dart")
s = p.read_text(encoding="utf-8")
# bytt evt isPremium() kall til getIsPremium()
s = s.replace("premium.isPremium()", "premium.getIsPremium()")
p.write_text(s, encoding="utf-8")
PY
fi

# 3) premium_page.dart: hvis den kaller premium.restore() så skal det nå finnes
# (vi gjør ingen endring her med mindre fil finnes – metoden er nå definert)

# 4) eb_shopping_page.dart: sørg for Timer-import hvis du bruker Timer/auto-refresh
SHOP="lib/pages/eb_shopping_page.dart"
if [ -f "$SHOP" ]; then
  cp "$SHOP" "$SHOP.bak.$(date +%s)" || true
  python3 - <<'PY'
import pathlib, re
p = pathlib.Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# Legg til dart:async hvis Timer brukes og import mangler
uses_timer = "Timer(" in s or "Timer.periodic" in s
has_async = re.search(r"import\s+'dart:async';", s) is not None

if uses_timer and not has_async:
    # Sett dart:async øverst (første import)
    m = re.search(r"(import\s+'[^']+';\s*\n)", s)
    if m:
        s = s[:m.start()] + "import 'dart:async';\n" + s[m.start():]
    else:
        s = "import 'dart:async';\n" + s

# Sørg for freeLimit konstant (hvis noen script fjernet/ga feil casing)
if "static const int freeLimit" not in s:
    # prøv å sette inn i State-klassen rett etter class _EbShoppingPageState ... {
    s = re.sub(r"(class\s+_EbShoppingPageState\s+extends\s+State<[^>]+>\s*\{\s*)",
               r"\1\n  static const int freeLimit = 30;\n",
               s, count=1)

p.write_text(s, encoding="utf-8")
PY
fi

dart format lib/services/premium_service.dart || true
[ -f "$BADGE" ] && dart format "$BADGE" || true
[ -f "$SHOP" ] && dart format "$SHOP" || true

flutter analyze || true

echo "✅ PremiumService API fikset + Timer/import/const-stabilisering ferdig."
echo "👉 Restart web-server etterpå hvis den kjører."
