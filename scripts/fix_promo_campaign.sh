#!/bin/bash
set -e

# 1. Kampanje-popup widget
cat > ~/bonusvarsel/lib/widgets/promo_offer_banner.dart << 'DART'
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
DART

# 2. Deep link + push service
cat > ~/bonusvarsel/lib/services/campaign_service.dart << 'DART'
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CampaignService {
  CampaignService._();
  static final CampaignService instance = CampaignService._();

  final _appLinks = AppLinks();
  static const _kPromoShown = 'promo_shown_elite_intro';

  /// Kall fra main.dart etter Firebase.initializeApp()
  Future<void> init(BuildContext context) async {
    await _initPushNotifications(context);
    await _initDeepLinks(context);
  }

  Future<void> _initPushNotifications(BuildContext context) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Håndter push når appen er i forgrunnen
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      if (data['type'] == 'promo_offer') {
        _showPromoBanner(context);
      }
    });

    // Håndter trykk på push-notifikasjon
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final data = message.data;
      if (data['type'] == 'promo_offer') {
        _showPromoBanner(context);
      }
    });

    // Hent FCM token (for å sende push til spesifikke brukere)
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');
  }

  Future<void> _initDeepLinks(BuildContext context) async {
    // Deep link når appen allerede er åpen
    _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri, context);
    });

    // Deep link når appen åpnes fra lukket tilstand
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri, context);
    }
  }

  void _handleUri(Uri uri, BuildContext context) {
    // bonusvarsel://promo/elite_intro
    if (uri.scheme == 'bonusvarsel' && uri.host == 'promo') {
      _showPromoBanner(context);
    }
  }

  Future<bool> shouldShowPromo() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_kPromoShown) ?? false;
    return !shown;
  }

  Future<void> markPromoShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPromoShown, true);
  }

  void _showPromoBanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PromoSheet(),
    );
  }
}

class _PromoSheet extends StatelessWidget {
  const _PromoSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white70),
            ),
          ),
          // PromoOfferBanner importeres her
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A6E), Color(0xFFD4AF37)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎉 Spesialtilbud – kun til deg!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Elite til Premium-pris\nFørste måned kun 49 kr',
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // Naviger til checkout med promo
                    },
                    child: const Text(
                      'Aktiver tilbud',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
DART

echo "✅ PromoOfferBanner og CampaignService opprettet"
