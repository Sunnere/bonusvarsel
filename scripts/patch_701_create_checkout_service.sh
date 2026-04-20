#!/usr/bin/env bash
set -e

FILE="lib/services/checkout_service.dart"

cat > "$FILE" <<'DART'
import 'package:in_app_purchase/in_app_purchase.dart';

class CheckoutService {
  static final CheckoutService instance = CheckoutService._();
  CheckoutService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  final Set<String> _productIds = {
    'premium_monthly',
    'premium_yearly',
    'elite_monthly',
    'elite_yearly',
  };

  List<ProductDetails> products = [];

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    products = response.productDetails;
  }

  ProductDetails? getProduct(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> buy(String productId) async {
    final product = getProduct(productId);
    if (product == null) return;

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }
}
DART

echo "✅ CheckoutService laget"
