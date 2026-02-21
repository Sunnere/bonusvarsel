#!/usr/bin/env bash
set -euo pipefail

echo "== [1/4] Finn/lag PremiumService =="
mkdir -p lib/services lib/widgets

PREMIUM_SVC_FILE="$(find lib -maxdepth 3 -type f -name '*premium*service*.dart' | head -n 1 || true)"
if [[ -z "${PREMIUM_SVC_FILE}" ]]; then
  PREMIUM_SVC_FILE="lib/services/premium_service.dart"
fi
echo "Bruker: ${PREMIUM_SVC_FILE}"

cp -f "${PREMIUM_SVC_FILE}" "${PREMIUM_SVC_FILE}.bak.$(date +%s)" 2>/dev/null || true

cat > "${PREMIUM_SVC_FILE}" <<'DART'
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const _kIsPremium = 'is_premium';
  static const _kDebugBadge = 'debug_force_premium_badge';

  Future<SharedPreferences> _p() => SharedPreferences.getInstance();

  /// “Ekte” premium (senere bytter vi dette til RevenueCat / Stripe / etc.)
  Future<bool> isPremium() async {
    final prefs = await _p();
    return prefs.getBool(_kIsPremium) ?? false;
  }

  /// Placeholder for “Restore purchases”.
  /// Når du kobler til ekte betaling senere, blir denne mappet til restorePurchases().
  Future<void> restore() async {
    // no-op i denne MVPen
    return;
  }

  /// For testing i debug / lokalt.
  Future<void> setPremiumForDebug(bool value) async {
    final prefs = await _p();
    await prefs.setBool(_kIsPremium, value);
  }

  /// ADMIN/DEBUG: tving badge synlig/skjult (kundene får aldri denne i release)
  Future<bool> debugBadgeEnabled() async {
    final prefs = await _p();
    return prefs.getBool(_kDebugBadge) ?? false;
  }

  Future<void> setDebugBadgeEnabled(bool value) async {
    final prefs = await _p();
    await prefs.setBool(_kDebugBadge, value);
  }
}
DART

echo "== [2/4] Skriv premium_badge.dart (badge styrt av DEG i debug) =="
BADGE_FILE="lib/widgets/premium_badge.dart"
cp -f "${BADGE_FILE}" "${BADGE_FILE}.bak.$(date +%s)" 2>/dev/null || true

cat > "${BADGE_FILE}" <<'DART'
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/premium_service.dart';

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = PremiumService();

    return FutureBuilder<bool>(
      future: _shouldShowBadge(svc),
      builder: (context, snap) {
        final show = snap.data ?? false;
        if (!show) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Theme.of(context).colorScheme.primary,
          ),
          child: const Text(
            'PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        );
      },
    );
  }

  Future<bool> _shouldShowBadge(PremiumService svc) async {
    final isPrem = await svc.isPremium();

    // I release: badge vises kun hvis premium
    if (!kDebugMode) return isPrem;

    // I debug: du kan tvinge badge av/på
    final forced = await svc.debugBadgeEnabled();
    return forced || isPrem;
  }
}
DART

echo "== [3/4] Performance: debounce søk i eb_shopping_page.dart (hvis fil finnes) =="
SHOP_FILE="lib/pages/eb_shopping_page.dart"
if [[ -f "${SHOP_FILE}" ]]; then
  cp -f "${SHOP_FILE}" "${SHOP_FILE}.bak.$(date +%s)" || true

  python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# 1) Sørg for at dart:async import finnes (Timer)
if "dart:async" not in s:
  s = s.replace("import 'dart:convert';", "import 'dart:async';\nimport 'dart:convert';", 1)

# 2) Legg til Timer? _debounce; hvis ikke finnes
if re.search(r"Timer\?\s+_debounce\s*;", s) is None:
  # sett inn etter første TextEditingController eller i toppen av State
  s = re.sub(r"(final\s+TextEditingController\s+_searchCtrl\s*=\s*TextEditingController\(\)\s*;)",
             r"\1\n\n  Timer? _debounce;",
             s, count=1)

# 3) Sørg for dispose rydder debounce
if " _debounce?.cancel();" not in s:
  s = re.sub(r"(\s*void\s+dispose\(\)\s*\{\s*)",
             r"\1\n    _debounce?.cancel();\n",
             s, count=1)

# 4) Erstatt onChanged direkte setState med debounce (hvis onChanged finnes på søkefeltet)
# Vi prøver å finne: onChanged: (_) => setState(() {}),
s = re.sub(r"onChanged:\s*\(_\)\s*=>\s*setState\(\(\)\s*\{\s*\}\s*\),",
           "onChanged: (_) {\n"
           "                      _debounce?.cancel();\n"
           "                      _debounce = Timer(const Duration(milliseconds: 180), () {\n"
           "                        if (!mounted) return;\n"
           "                        setState(() {});\n"
           "                      });\n"
           "                    },",
           s)

p.write_text(s, encoding="utf-8")
print("✅ Debounce patch forsøkt på eb_shopping_page.dart")
PY
else
  echo "ℹ️ Fant ikke ${SHOP_FILE} – hopper over debounce patch"
fi

echo "== [4/4] Format + Analyze =="
dart format lib >/dev/null
flutter analyze || true

echo "✅ Ferdig. Restart web-server hvis du kjører den."
