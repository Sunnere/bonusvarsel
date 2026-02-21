#!/usr/bin/env bash
set -euo pipefail

SVC="lib/services/premium_service.dart"
BADGE="lib/widgets/premium_badge.dart"
PREM="lib/pages/premium_page.dart"

for f in "$SVC" "$BADGE" "$PREM"; do
  if [[ ! -f "$f" ]]; then
    echo "Fant ikke $f"
    exit 1
  fi
done

cp "$SVC"   "$SVC.bak.$(date +%s)"
cp "$BADGE" "$BADGE.bak.$(date +%s)"
cp "$PREM"  "$PREM.bak.$(date +%s)"

# 1) PremiumService: sørg for at disse finnes: get/setShowBadges + debugBadgeEnabled get/set
python3 - "$SVC" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

def ensure_method(snippet: str, marker: str):
  global s
  if marker in s:
    return False
  # legg før siste }
  i = s.rfind("}")
  if i == -1:
    raise SystemExit("Fant ikke avsluttende } i premium_service.dart")
  s = s[:i] + "\n\n" + snippet.strip() + "\n\n" + s[i:]
  return True

# sørg for shared_prefs import
if "shared_preferences" not in s:
  # finn importblokka
  m = re.search(r"^(import\s+['\"].+?;\s*\n)+", s, flags=re.M)
  if m:
    block = m.group(0)
    if "package:shared_preferences/shared_preferences.dart" not in block:
      block2 = block + "import 'package:shared_preferences/shared_preferences.dart';\n"
      s = s.replace(block, block2, 1)
  else:
    s = "import 'package:shared_preferences/shared_preferences.dart';\n" + s

# nøkkelkonstanter (hvis de ikke finnes, lager vi)
if "_kShowBadges" not in s:
  # legg dem inne i klassen (rett etter class PremiumService { )
  s = re.sub(
    r"(class\s+PremiumService\s*\{\s*)",
    r"\1  static const String _kIsPremium = 'bv_is_premium';\n"
    r"  static const String _kShowBadges = 'bv_show_badges';\n"
    r"  static const String _kFreeLimit = 'bv_free_limit';\n"
    r"  static const String _kDebugBadge = 'bv_debug_badge_enabled';\n\n",
    s,
    count=1,
    flags=re.S
  )

snippet = r"""
  Future<bool> getShowBadges({bool fallback = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowBadges) ?? fallback;
  }

  Future<void> setShowBadges(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowBadges, v);
  }

  Future<bool> debugBadgeEnabled({bool fallback = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDebugBadge) ?? fallback;
  }

  Future<void> setDebugBadgeEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDebugBadge, v);
  }
"""

changed = False
changed |= ensure_method(snippet, "Future<bool> getShowBadges")
# (setter følger med i samme snippet)

p.write_text(s, encoding="utf-8")
print("✅ PremiumService: showBadges + debugBadgeEnabled OK" if changed else "ℹ️ PremiumService: allerede OK")
PY

# 2) PremiumBadge widget: skriv en enkel, robust badge som tar flags fra parent
cat > "$BADGE" <<'DART'
import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final bool isPremium;
  final bool showBadges; // admin flag
  final bool debugBadgeEnabled; // debug/admin override
  final String text;

  const PremiumBadge({
    super.key,
    required this.isPremium,
    required this.showBadges,
    required this.debugBadgeEnabled,
    this.text = 'PRO',
  });

  @override
  Widget build(BuildContext context) {
    // Kunden kan ikke styre dette – kun admin flag / debug override.
    final visible = (showBadges && isPremium) || debugBadgeEnabled;
    if (!visible) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}
DART

# 3) PremiumPage: fikse feil du hadde: showBadges(...) og debugBadgeEnabled(...) er named args
python3 - "$PREM" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")

# sørg for kDebugMode import
if "kDebugMode" in s and "foundation.dart" not in s:
  # legg til foundation import
  s = re.sub(r"(import\s+'package:flutter/material\.dart';\s*\n)",
             r"\1import 'package:flutter/foundation.dart';\n", s, count=1)

# rett opp kall hvis noen har skrevet showBadges(true) / debugBadgeEnabled(true) feil:
s = re.sub(r"getShowBadges\(\s*true\s*\)", "getShowBadges(fallback: true)", s)
s = re.sub(r"debugBadgeEnabled\(\s*true\s*\)", "debugBadgeEnabled(fallback: true)", s)
s = re.sub(r"debugBadgeEnabled\(\s*false\s*\)", "debugBadgeEnabled(fallback: false)", s)
s = re.sub(r"getFreeLimit\(\s*30\s*\)", "getFreeLimit(fallback: 30)", s)

# legg inn en debug toggle i UI hvis den ikke finnes
if "Debug-badge override" not in s:
  # prøv å finne der du har admin/ debug-seksjon, ellers legg før siste ] i ListView children
  marker = "Text('Admin / debug'"
  if marker in s:
    # sett inn rett etter den overskriften
    s = s.replace(marker, marker + " + badge.", 1) if False else s

  insert = r"""
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            value: _debugBadgeEnabled,
            onChanged: (v) async {
              setState(() => _debugBadgeEnabled = v);
              await _premiumSvc.setDebugBadgeEnabled(v);
            },
            title: const Text('Debug-badge override'),
            subtitle: const Text('Vis PRO-badge selv uten premium (kun debug).'),
          ),
        ],
"""

  # finn et sted å putte den: etter SwitchListTile for showBadges hvis den finnes
  m = re.search(r"SwitchListTile\([\s\S]*?setShowBadges\([\s\S]*?\)\s*;\s*\}\s*,[\s\S]*?\)\s*,", s)
  if m:
    s = s[:m.end()] + insert + s[m.end():]
  else:
    # fallback: putt inn før slutten av children: [
    m2 = re.search(r"children:\s*\[\s*", s)
    if m2:
      s = s[:m2.end()] + "const SizedBox(height: 8),\n" + insert + s[m2.end():]

p.write_text(s, encoding="utf-8")
print("✅ PremiumPage: fikset named args + lagt til debug override (hvis manglet)")
PY

dart format "$SVC" "$BADGE" "$PREM" || true
flutter analyze || true
