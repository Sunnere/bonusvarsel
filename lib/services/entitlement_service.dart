import 'package:shared_preferences/shared_preferences.dart';

class EntitlementService {
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
  }

  Future<void> clear() async {
    _plan = 'free';
    _productId = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPlan);
    await prefs.remove(_keyProductId);
  }
}
