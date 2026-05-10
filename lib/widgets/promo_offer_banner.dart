import 'package:flutter/material.dart';
import '../services/promo_offer_service.dart';
import '../services/checkout_service.dart';

class PromoOfferBanner extends StatefulWidget {
  const PromoOfferBanner({super.key});

  @override
  State<PromoOfferBanner> createState() => _PromoOfferBannerState();
}

class _PromoOfferBannerState extends State<PromoOfferBanner> {
  bool _loading = false;
  static const _offerId = 'elite_intro_premium_price';
  static const _productId = 'elite_monthly';

  Future<void> _claim() async {
    setState(() => _loading = true);
    try {
      await CheckoutService.instance.init();
      final product = CheckoutService.instance.getProduct(_productId);
      if (product == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produktet ikke tilgjengelig. Prøv igjen.')),
        );
        return;
      }
      await PromoOfferService.instance.buyWithPromoOffer(
        product: product,
        offerId: _offerId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feil: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A6E), Color(0xFFD4AF37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44D4AF37),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 28),
              SizedBox(width: 8),
              Text(
                '🎉 Spesialtilbud',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Elite til Premium-pris',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Første måned kun 49 kr – deretter 89 kr/mnd. Avslutt når som helst.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _loading ? null : _claim,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Aktiver tilbud nå',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
