#!/bin/bash
set -e

FILE="$HOME/bonusvarsel/lib/services/entitlement_service.dart"

cat > "$FILE" << 'DART'
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EntitlementService extends ChangeNotifier {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  static const _keyPlan = 'entitlement_plan';
  static const _keyProductId = 'entitlement_product_id';

  String _plan = 'free';
  String _productId = '';

  String get plan => _plan;
  String get productId => _productId;

  bool get isPremium => _plan == 'premium' || _plan == 'elite';
  bool get isElite => _plan == 'elite';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _plan = prefs.getString(_keyPlan) ?? 'free';
    _productId = prefs.getString(_keyProductId) ?? '';
    notifyListeners();
  }

  Future<void> unlock(String productId) async {
    _productId = productId;

    if (productId.contains('elite')) {
      _plan = 'elite';
    } else if (productId.contains('premium')) {
      _plan = 'premium';
    } else {
      _plan = 'free';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlan, _plan);
    await prefs.setString(_keyProductId, _productId);

    // Sync PremiumService og SubscriptionService så hele appen oppdateres
    await _syncOtherServices();

    notifyListeners();
    debugPrint('EntitlementService.unlock: plan=$_plan productId=$_productId');
  }

  Future<void> _syncOtherServices() async {
    final prefs = await SharedPreferences.getInstance();
    // PremiumService nøkkel
    await prefs.setBool('premium.is_premium', isPremium);
    // SubscriptionService nøkkel
    await prefs.setString('bv.subs.tier', _plan);
  }

  Future<void> clear() async {
    _plan = 'free';
    _productId = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPlan);
    await prefs.remove(_keyProductId);
    await prefs.remove('premium.is_premium');
    await prefs.setString('bv.subs.tier', 'free');

    notifyListeners();
  }
}
DART

echo "✅ entitlement_service.dart oppdatert"
