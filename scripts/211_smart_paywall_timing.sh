#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"

FILE="lib/services/paywall_trigger_service.dart"

cp "$FILE" "${FILE}.bak.${STAMP}"
echo "Backup laget: ${FILE}.bak.${STAMP}"

cat > "$FILE" <<'DART'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/premium_page.dart';
import '../widgets/premium_paywall_sheet.dart';

class PaywallTriggerService {
  static const _scrollDepthSeenKey = 'paywall_scroll_depth_seen_v2';
  static const _paywallShownCountKey = 'paywall_shown_count_v2';
  static const _lastPaywallShownAtKey = 'paywall_last_shown_at_v2';
  static const _sessionShownKey = 'paywall_session_shown_v2';
  static const _appOpenCountKey = 'paywall_app_open_count_v2';

  static Future<void> registerAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_appOpenCountKey) ?? 0;
    await prefs.setInt(_appOpenCountKey, count + 1);

    // reset session flag
    await prefs.setBool(_sessionShownKey, false);
  }

  static Future<bool> _canShowPaywall() async {
    final prefs = await SharedPreferences.getInstance();

    final appOpens = prefs.getInt(_appOpenCountKey) ?? 0;
    final sessionShown = prefs.getBool(_sessionShownKey) ?? false;
    final totalShown = prefs.getInt(_paywallShownCountKey) ?? 0;
    final lastShown = prefs.getInt(_lastPaywallShownAtKey);

    // ❌ Ikke første gang
    if (appOpens < 2) return false;

    // ❌ Ikke flere ganger per session
    if (sessionShown) return false;

    // ❌ Maks 3 ganger totalt
    if (totalShown >= 3) return false;

    // ❌ Cooldown 24 timer
    if (lastShown != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - lastShown;
      const oneDay = 24 * 60 * 60 * 1000;

      if (diff < oneDay) return false;
    }

    return true;
  }

  static Future<void> markScrollDepthSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scrollDepthSeenKey, true);
  }

  static Future<bool> hasSeenScrollDepth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_scrollDepthSeenKey) ?? false;
  }

  static Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();

    final count = prefs.getInt(_paywallShownCountKey) ?? 0;

    await prefs.setInt(_paywallShownCountKey, count + 1);
    await prefs.setInt(
      _lastPaywallShownAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.setBool(_sessionShownKey, true);
  }

  static Future<void> showPaywall(
    BuildContext context, {
    required String source,
    String title = 'Lås opp flere bonusmuligheter',
    String subtitle =
        'Se høyere bonusrate, flere tilbud og smartere valg før du klikker.',
  }) async {
    final allowed = await _canShowPaywall();
    if (!allowed) return;

    await _markShown();

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PremiumPaywallSheet(
        source: source,
        title: title,
        subtitle: subtitle,
        onPrimary: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PremiumPage()),
          );
        },
      ),
    );
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
DART

# --------------------------------------------------
# PATCH main.dart (register app open)
# --------------------------------------------------
perl -0777 -pe "
s/runApp\(const BonusvarselApp\(\)\);/runApp(const BonusvarselApp());\n  PaywallTriggerService.registerAppOpen();/g
" -i lib/main.dart

# legg til import hvis mangler
perl -0777 -pe "
s/import 'package:bonusvarsel\/services\/api_service.dart';/import 'package:bonusvarsel\/services\/api_service.dart';\nimport 'package:bonusvarsel\/services\/paywall_trigger_service.dart';/g
" -i lib/main.dart

echo
echo "Smart trigger timing installert"
echo
echo "Kjør nå:"
echo "flutter analyze"
echo "flutter test"
