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
