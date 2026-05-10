#!/bin/bash
set -e

cat > ~/bonusvarsel/lib/services/promo_offer_service.dart << 'DART'
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

class PromoOfferService {
  PromoOfferService._();
  static final PromoOfferService instance = PromoOfferService._();

  /// Hent signatur fra Firebase og start kjøp med promotional offer
  Future<void> buyWithPromoOffer({
    required ProductDetails product,
    required String offerId,
  }) async {
    // Hent signatur fra Firebase Function
    final callable = FirebaseFunctions.instance.httpsCallable('signPromoOffer');
    final result = await callable.call({
      'productId': product.id,
      'offerId': offerId,
    });

    final data = result.data as Map<String, dynamic>;
    final keyId = data['keyId'] as String;
    final nonce = data['nonce'] as String;
    final timestamp = data['timestamp'] as int;
    final signature = data['signature'] as String;

    // Lag SKPaymentDiscount
    final discount = SKPaymentDiscountWrapper(
      identifier: offerId,
      keyIdentifier: keyId,
      nonce: nonce,
      signature: signature,
      timestamp: timestamp,
    );

    final storeKitPlugin = InAppPurchaseStoreKitPlatformAddition();
    final payment = SKMutablePaymentWrapper(
      productIdentifier: product.id,
      quantity: 1,
      applicationUsername: null,
      simulatesAskToBuyInSandbox: false,
      paymentDiscount: discount,
    );

    await storeKitPlugin.addPayment(payment);
  }
}
DART

echo "✅ PromoOfferService opprettet"
