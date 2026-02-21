#!/usr/bin/env bash
set -euo pipefail

EB="lib/pages/eb_shopping_page.dart"
PS="lib/services/premium_service.dart"
PP="lib/pages/premium_page.dart"

[ -f "$EB" ] || { echo "Fant ikke $EB"; exit 1; }
[ -f "$PP" ] || { echo "Fant ikke $PP"; exit 1; }

cp "$EB" "$EB.bak.$(date +%s)" || true
[ -f "$PS" ] && cp "$PS" "$PS.bak.$(date +%s)" || true

python - <<'PY'
from pathlib import Path
import re

# --- 1) Fjern dobbel _premium i eb_shopping_page.dart ---
eb = Path("lib/pages/eb_shopping_page.dart")
s = eb.read_text(encoding="utf-8")

# Finn alle linjer som deklarerer _premium (typisk: final _premium = PremiumService(); / const PremiumService())
premium_decl_re = re.compile(r"^\s*final\s+_premium\s*=\s*(?:const\s+)?PremiumService\(\)\s*;\s*$", re.M)
decls = list(premium_decl_re.finditer(s))

if len(decls) >= 2:
    # behold første, fjern resten
    keep = decls[0].span()
    spans_to_remove = [m.span() for m in decls[1:]]
    # fjern bakfra for å ikke forskyve indekser
    for a,b in reversed(spans_to_remove):
        # fjern også en ekstra blank linje rett etter hvis den finnes
        end = b
        if end < len(s) and s[end:end+1] == "\n":
            end += 1
        s = s[:a] + s[end:]
    eb.write_text(s, encoding="utf-8")
    print("✅ Fjernet duplikat _premium i eb_shopping_page.dart")
else:
    print("ℹ️ Fant ikke duplikat _premium (eller allerede fikset)")

# --- 2) Sørg for PremiumService.restore() i lib/services/premium_service.dart ---
ps = Path("lib/services/premium_service.dart")
ps.parent.mkdir(parents=True, exist_ok=True)

if ps.exists():
    t = ps.read_text(encoding="utf-8")
else:
    # Lag en minimal PremiumService hvis den ikke finnes
    t = """import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const _kIsPremium = 'is_premium';

  const PremiumService();

  Future<bool> getIsPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsPremium) ?? false;
  }

  Future<void> setIsPremium(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, v);
  }
}
"""

# Hvis restore() mangler, legg den inn i klassen
if "Future<void> restore(" not in t and "restore(" not in t:
    # prøv å finne slutten av class PremiumService { ... }
    m = re.search(r"class\s+PremiumService\s*{", t)
    if not m:
        # fallback: legg på nytt full fil (trygt)
        t = """import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const _kIsPremium = 'is_premium';

  const PremiumService();

  Future<bool> getIsPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsPremium) ?? false;
  }

  Future<void> setIsPremium(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, v);
  }

  /// Placeholder for "Restore purchases".
  /// In this prototype we don't have store integration, so this is a no-op.
  Future<void> restore() async {
    // TODO: hook up App Store / Play Billing restore flow later.
    return;
  }
}
"""
        ps.write_text(t, encoding="utf-8")
        print("✅ Skrev minimal PremiumService med restore()")
    else:
        # Finn siste "}" i filen (for klassen) og injiser før den
        # (enkelt og robust hvis filen bare har én klasse)
        idx = t.rfind("}")
        if idx != -1:
            inject = """

  /// Placeholder for "Restore purchases".
  /// In this prototype we don't have store integration, so this is a no-op.
  Future<void> restore() async {
    // TODO: hook up App Store / Play Billing restore flow later.
    return;
  }
"""
            t = t[:idx] + inject + t[idx:]
            ps.write_text(t, encoding="utf-8")
            print("✅ La til restore() i PremiumService")
        else:
            print("⚠️ Fant ikke slutt-brace i premium_service.dart – ingen endring")
else:
    print("ℹ️ PremiumService.restore() finnes allerede")

# --- 3) (valgfritt trygging) Hvis premium_page.dart kaller restore(), la det stå ---
# Bare informativt; ingen endring her.
PY

dart format "$EB" "$PP" "$PS" >/dev/null 2>&1 || true
flutter analyze
