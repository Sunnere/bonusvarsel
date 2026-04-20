#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/checkout_service.dart"
mkdir -p lib/services

cp "$FILE" "${FILE}.bak_705" 2>/dev/null || true

cat > "$FILE" <<'DART'
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'entitlement_service.dart';

class CheckoutService {
  CheckoutService._();
  static final CheckoutService instance = CheckoutService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  final Set<String> _productIds = const {
    'premium_monthly',
    'premium_yearly',
    'elite_monthly',
    'elite_yearly',
  };

  List<ProductDetails> products = <ProductDetails>[];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _initialized = false;

  String _plan = 'Premium';
  String _billing = 'monthly';
  bool _isPartner = false;

  String get plan => _plan;
  String get billing => _billing;
  bool get isPartner => _isPartner;

  String get effectivePlan {
    if (_isPartner && _plan.toLowerCase() == 'premium') {
      return 'elite';
    }
    return _plan.toLowerCase();
  }

  Map<String, dynamic> toPayload() {
    return {
      'plan': _plan.toLowerCase(),
      'billing': _billing,
      'effectivePlan': effectivePlan,
      'isPartner': _isPartner,
    };
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await EntitlementService.instance.load();

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('IAP unavailable on this device/account.');
      return;
    }

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Purchase stream error: $error');
      },
      cancelOnError: false,
    );

    await loadProducts();
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
  }

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);

    if (response.error != null) {
      debugPrint('IAP query error: ${response.error}');
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP not found: ${response.notFoundIDs}');
    }

    products = response.productDetails;
  }

  ProductDetails? getProduct(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> setSelection({
    required String plan,
    required String billing,
  }) async {
    _plan = plan;
    _billing = billing;
  }

  Future<void> setBilling(String value) async {
    _billing = value;
  }

  Future<void> setPartner(bool value) async {
    _isPartner = value;
  }

  String selectedProductId() {
    final planPart = _plan.toLowerCase();
    final billingPart = _billing == 'yearly' ? 'yearly' : 'monthly';
    return '${planPart}_${billingPart}';
  }

  Future<void> buySelected() async {
    final productId = selectedProductId();
    await buy(productId);
  }

  Future<void> buy(String productId) async {
    if (products.isEmpty) {
      await loadProducts();
    }

    final product = getProduct(productId);
    if (product == null) {
      debugPrint('Product not found: $productId');
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    // Subscriptions håndteres som non-consumable-kjøp i in_app_purchase-flowen.
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('Restore skipped: IAP unavailable.');
      return;
    }
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('Purchase pending: ${purchase.productID}');
          break;

        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchase.error}');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await EntitlementService.instance.unlock(purchase.productID);
          debugPrint(
            'Unlocked plan=${EntitlementService.instance.plan} via ${purchase.productID} (${purchase.status.name})',
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          debugPrint('Purchase canceled: ${purchase.productID}');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }
}
DART

echo "✅ checkout_service.dart oppdatert"
echo
echo "==> flutter analyze"
flutter analyze || true
