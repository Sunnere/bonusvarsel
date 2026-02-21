#!/usr/bin/env bash
set -euo pipefail

# ---------- 1) Patch PremiumService: legg til gamle metodenavn som wrappers ----------
PS="lib/services/premium_service.dart"
if [[ ! -f "$PS" ]]; then
  echo "Fant ikke $PS"
  exit 1
fi

cp "$PS" "$PS.bak.$(date +%s)"

python3 - "$PS" <<'PY'
import re, sys, pathlib

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Hvis wrappers allerede finnes, gjør ingenting.
if "getIsPremium(" in s and "setIsPremium(" in s and "getFreeLimit(" in s:
    print("PremiumService: wrappers finnes allerede – skip")
    sys.exit(0)

# Finn slutten av klassen (siste })
m = re.search(r"\n\}\s*$", s)
if not m:
    raise SystemExit("Klarte ikke finne slutten av PremiumService-klassen")

wrappers = r"""

  // ---------------------------------------------------------------------------
  // Backwards compatible API (old method names used around the app)
  // ---------------------------------------------------------------------------

  /// Old name: getIsPremium()
  Future<bool> getIsPremium() => isPremium();

  /// Old name: setIsPremium(bool)
  Future<void> setIsPremium(bool v) => setPremium(v);

  /// Old name: getFreeLimit({fallback})
  Future<int> getFreeLimit({int fallback = defaultFreeLimit}) async {
    try {
      final v = await freeLimit();
      return v;
    } catch (_) {
      return fallback;
    }
  }

  /// Old name: getShowBadges({fallback})
  Future<bool> getShowBadges({bool fallback = defaultShowBadges}) async {
    try {
      final v = await showBadges();
      return v;
    } catch (_) {
      return fallback;
    }
  }

  /// Old name used in premium_page: debugBadgeEnabled()
  Future<bool> debugBadgeEnabled({bool fallback = defaultShowBadges}) =>
      getShowBadges(fallback: fallback);

  /// Old name used in premium_page: setDebugBadgeEnabled(bool)
  Future<void> setDebugBadgeEnabled(bool v) => setShowBadges(v);
"""

s = s[:m.start()] + wrappers + s[m.start():]
p.write_text(s, encoding="utf-8")
print("✅ PremiumService: la til bakoverkompatible wrappers")
PY

dart format "$PS"

# ---------- 2) Fix error_handling.dart: fjern unødvendige imports ----------
EH="lib/app/error_handling.dart"
if [[ -f "$EH" ]]; then
  cp "$EH" "$EH.bak.$(date +%s)"
  python3 - "$EH" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# Denne fila trenger egentlig kun foundation.dart for kDebugMode + FlutterError
# Vi beholder kun: package:flutter/foundation.dart
lines = s.splitlines()
keep = []
for line in lines:
  if line.startswith("import 'package:flutter/foundation.dart'"):
    keep.append(line)
  elif line.startswith("import "):
    # dropper dart:ui og material.dart osv
    continue
  else:
    keep.append(line)
s2 = "\n".join(keep).strip() + "\n"
p.write_text(s2, encoding="utf-8")
print("✅ error_handling.dart: imports ryddet")
PY
  dart format "$EH" || true
fi

# ---------- 3) Fix main.dart: fjern unused settings import hvis ingen route bruker den ----------
MAIN="lib/main.dart"
if [[ -f "$MAIN" ]]; then
  cp "$MAIN" "$MAIN.bak.$(date +%s)"
  python3 - "$MAIN" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

has_settings_route = ("/settings" in s) or ("SettingsPage" in s) or ("settings_page.dart" in s and "pushNamed('/settings')" in s)

# Hvis import finnes men ingenting bruker den (og ingen /settings route), fjern importen
if "import 'pages/settings_page.dart';" in s and not has_settings_route:
  s = s.replace("import 'pages/settings_page.dart';\n", "")
  p.write_text(s, encoding="utf-8")
  print("✅ main.dart: fjernet unused settings import")
else:
  print("main.dart: lot settings import stå (route/bruk kan finnes)")
PY
  dart format "$MAIN" || true
fi

echo "✅ Patch ferdig"
