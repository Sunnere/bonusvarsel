import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription_tier.dart';

class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  static const _kTier = 'bv.subs.tier';
  static const _kShowBadges = 'bv.subs.showBadges';
  static const _kFreeLimit = 'bv.subs.freeLimit';

  SharedPreferences? _prefs;

  SubscriptionTier? _tierCache;
  bool? _showBadgesCache;
  int? _freeLimitCache;

  Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ---------- READ ----------

  Future<SubscriptionTier> getTier() async {
    if (_tierCache != null) return _tierCache!;
    final p = await _ensurePrefs();
    final raw = p.getString(_kTier);
    _tierCache = SubscriptionTierX.fromName(raw);
    return _tierCache!;
  }

  Future<bool> getShowBadges({bool fallback = true}) async {
    if (_showBadgesCache != null) return _showBadgesCache!;
    final p = await _ensurePrefs();
    _showBadgesCache = p.getBool(_kShowBadges) ?? fallback;
    return _showBadgesCache!;
  }

  Future<int> getFreeLimit({int fallback = 30}) async {
    if (_freeLimitCache != null) return _freeLimitCache!;
    final p = await _ensurePrefs();
    _freeLimitCache = p.getInt(_kFreeLimit) ?? fallback;
    return _freeLimitCache!;
  }

  // ---------- WRITE ----------

  Future<void> setTier(SubscriptionTier tier) async {
    final p = await _ensurePrefs();
    await p.setString(_kTier, tier.name);
    _tierCache = tier;
    notifyListeners();
  }

  Future<void> setShowBadges(bool enabled) async {
    final p = await _ensurePrefs();
    await p.setBool(_kShowBadges, enabled);
    _showBadgesCache = enabled;
    notifyListeners();
  }

  Future<void> setFreeLimit(int limit) async {
    final p = await _ensurePrefs();
    await p.setInt(_kFreeLimit, limit);
    _freeLimitCache = limit;
    notifyListeners();
  }
}
