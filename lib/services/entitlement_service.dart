import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EntitlementService extends ChangeNotifier {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  static const _keyPlan = 'entitlement_plan';
  static const _keyProductId = 'entitlement_product_id';
  static const _keySource = 'entitlement_source';

  String _plan = 'free';
  String _productId = '';
  String _source = 'none'; // 'iap' (App Store/Google Play), 'backend' (Stripe via checkSubscription), 'none'

  String get plan => _plan;
  String get productId => _productId;

  bool get isPremium => _plan == 'premium' || _plan == 'elite';
  bool get isElite => _plan == 'elite';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _plan = prefs.getString(_keyPlan) ?? 'free';
    _productId = prefs.getString(_keyProductId) ?? '';
    _source = prefs.getString(_keySource) ?? 'none';
    notifyListeners();
  }

  Future<void> unlock(String productId, {String source = 'iap'}) async {
    _productId = productId;
    _source = source;

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
    await prefs.setString(_keySource, _source);

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

  /// Henter faktisk abonnement-status fra den eksisterende
  /// checkSubscription Cloud Function (functions/index.js), og overstyrer
  /// lokal SharedPreferences-status hvis backend vet bedre.
  Future<void> syncFromBackend() async {
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user == null) {
        debugPrint('EntitlementService.syncFromBackend: ingen innlogget bruker, hopper over');
        return;
      }

      // MIDLERTIDIG DEBUG-UID - fjernes etter feilsøking
      debugPrint('EntitlementService.syncFromBackend [DEBUG-UID]: uid=${user.uid} email=${user.email}');

      final callable = FirebaseFunctions.instance.httpsCallable('checkSubscription');
      final result = await callable.call();
      final backendPlan = (result.data?['plan'] as String?) ?? 'free';

      if (backendPlan != _plan) {
        const tierRank = {'free': 0, 'premium': 1, 'elite': 2};
        final isDowngrade = (tierRank[backendPlan] ?? 0) < (tierRank[_plan] ?? 0);

        if (isDowngrade && _source == 'iap') {
          debugPrint('EntitlementService.syncFromBackend: backend sier $backendPlan, men lokal status ($_plan) er IAP-bekreftet - beholder lokal status');
          return;
        }

        debugPrint('EntitlementService.syncFromBackend: lokal=$_plan (kilde=$_source) backend=$backendPlan -> oppdaterer');
        await unlock(backendPlan, source: 'backend');
      } else {
        debugPrint('EntitlementService.syncFromBackend: allerede synkronisert ($_plan)');
      }
    } catch (e) {
      debugPrint('EntitlementService.syncFromBackend feilet (beholder lokal status): $e');
    }
  }

  Future<void> clear() async {
    _plan = 'free';
    _productId = '';
    _source = 'none';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPlan);
    await prefs.remove(_keyProductId);
    await prefs.remove(_keySource);
    await prefs.remove('premium.is_premium');
    await prefs.setString('bv.subs.tier', 'free');

    notifyListeners();
  }
}
