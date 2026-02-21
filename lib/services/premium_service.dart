import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PremiumService (v1)
/// - Nå: local prefs + admin overrides (for dev/test)
/// - Senere: bytt inn kjøp/kvittering (in_app_purchase) og behold samme API.
class PremiumService {
  const PremiumService();

  static const _kPremium = 'premium.is_premium';
  static const _kShowBadges = 'premium.show_badges';
  static const _kFreeLimit = 'premium.free_limit';

  // Defaults (free tier)
  static const int defaultFreeLimit = 30;
  static const bool defaultShowBadges = true;

  Future<SharedPreferences> _p() => SharedPreferences.getInstance();

  /// True hvis bruker er premium (foreløpig: lagret i prefs / admin override)
  Future<bool> isPremium() async {
    final p = await _p();
    return p.getBool(_kPremium) ?? false;
  }

  /// Hvor mange shops som er synlige for gratisbruker
  Future<int> freeLimit() async {
    final p = await _p();
    final v = p.getInt(_kFreeLimit) ?? defaultFreeLimit;
    // hard clamp for safety
    return v < 0 ? 0 : v;
  }

  /// Om badges skal vises (styrt av deg)
  Future<bool> showBadges() async {
    final p = await _p();
    return p.getBool(_kShowBadges) ?? defaultShowBadges;
  }

  /// Admin/dev: sett premium on/off
  Future<void> setPremium(bool v) async {
    final p = await _p();
    await p.setBool(_kPremium, v);
  }

  /// Admin/dev: sett badge synlighet
  Future<void> setShowBadges(bool v) async {
    final p = await _p();
    await p.setBool(_kShowBadges, v);
  }

  /// Admin/dev: sett free limit (antall butikker gratis)
  Future<void> setFreeLimit(int v) async {
    final p = await _p();
    await p.setInt(_kFreeLimit, v);
  }

  /// Convenience: sett flere samtidig
  Future<void> setAdminOverrides({
    bool? premium,
    bool? showBadges,
    int? freeLimit,
  }) async {
    final p = await _p();
    if (premium != null) await p.setBool(_kPremium, premium);
    if (showBadges != null) await p.setBool(_kShowBadges, showBadges);
    if (freeLimit != null) await p.setInt(_kFreeLimit, freeLimit);
  }

  /// “Restore purchases” – senere: implementer ekte restore via store.
  /// Nå: no-op i release, men holder appen grønn.
  Future<void> restore() async {
    if (kDebugMode) {
      // print("PremiumService.restore() - not implemented yet");
    }
  }

  /// Reset alt (dev)
  Future<void> clear() async {
    final p = await _p();
    await p.remove(_kPremium);
    await p.remove(_kShowBadges);
    await p.remove(_kFreeLimit);
  }

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
}
