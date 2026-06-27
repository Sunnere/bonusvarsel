#!/bin/bash
set -e
TARGET="lib/services/notification_service.dart"
cp "$TARGET" "$TARGET.bak_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
echo "📦 Oppretter $TARGET ..."
mkdir -p lib/services
cat > "$TARGET" << 'DART'
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/offer_feed_item.dart';
import 'offers_feed_repository.dart';

class NotificationService {
  static const _kEmail     = 'alert_email';
  static const _kTelegram  = 'alert_telegram';
  static const _kTrumfFavs = 'alert_trumf_favs';
  static const _kSasFavs   = 'alert_sas_favs';

  static const _sasDefaultShops = [
    'Booking.com','Hotels.com','Expedia','Scandic Hotels',
    'H&M','Zalando','Elkjøp','IKEA',
  ];
  static const _trumfDefaultShops = [
    'Outnorth','Gina Tricot','Hotels.com',
    'Expedia','XXL','Blivakker',
  ];

  static Future<void> sendWeeklyOffers() async {
    final prefs     = await SharedPreferences.getInstance();
    final email     = prefs.getString(_kEmail)    ?? '';
    final telegram  = prefs.getString(_kTelegram) ?? '';
    final trumfFavs = prefs.getStringList(_kTrumfFavs) ?? [];
    final sasFavs   = prefs.getStringList(_kSasFavs)   ?? [];
    if (email.isEmpty && telegram.isEmpty) return;

    final repo       = const OffersFeedRepository();
    final sasItems   = await _fetchSasOffers(repo, sasFavs);
    final trumfItems = await _fetchTrumfOffers(repo, trumfFavs);
    if (sasItems.isEmpty && trumfItems.isEmpty) return;

    final message = _buildMessage(
      sasItems: sasItems, trumfItems: trumfItems,
      sasFavs: sasFavs,  trumfFavs: trumfFavs,
    );
    await _dispatchNotification(
      email: email, telegram: telegram, message: message,
      sasCount: sasItems.length, trumfCount: trumfItems.length,
    );
  }

  static Future<List<OfferFeedItem>> _fetchSasOffers(
    OffersFeedRepository repo, List<String> sasFavs) async {
    try {
      final all = await repo.fetchActiveItems(program: 'sas_online', forceRefresh: true);
      if (sasFavs.isNotEmpty) {
        final fav = all.where((item) => sasFavs.any((f) =>
          item.store.toLowerCase().contains(f.toLowerCase()))).toList();
        if (fav.isNotEmpty) return fav.take(3).toList();
      }
      final defaults = all.where((item) => _sasDefaultShops.any((s) =>
        item.store.toLowerCase().contains(s.toLowerCase()))).toList();
      defaults.sort((a, b) => (b.rate ?? 0).compareTo(a.rate ?? 0));
      return defaults.take(2).toList();
    } catch (_) { return []; }
  }

  static Future<List<OfferFeedItem>> _fetchTrumfOffers(
    OffersFeedRepository repo, List<String> trumfFavs) async {
    try {
      final all = await repo.fetchActiveItems(program: 'trumf_netthandel', forceRefresh: true);
      if (trumfFavs.isNotEmpty) {
        final fav = all.where((item) => trumfFavs.any((f) =>
          item.store.toLowerCase().contains(f.toLowerCase()))).toList();
        if (fav.isNotEmpty) return fav.take(3).toList();
      }
      final withCamp = all.where((i) => i.hasCampaign == true).toList();
      withCamp.sort((a, b) => (b.rate ?? 0).compareTo(a.rate ?? 0));
      if (withCamp.isNotEmpty) return withCamp.take(3).toList();
      all.sort((a, b) => (b.rate ?? 0).compareTo(a.rate ?? 0));
      return all.take(2).toList();
    } catch (_) { return []; }
  }

  static String _buildMessage({
    required List<OfferFeedItem> sasItems,
    required List<OfferFeedItem> trumfItems,
    required List<String> sasFavs,
    required List<String> trumfFavs,
  }) {
    final buf = StringBuffer();
    buf.writeln('🔔 *Bonusvarsler denne uken*\n');
    if (trumfItems.isNotEmpty) {
      buf.writeln('🟢 *Trumf Netthandel${trumfFavs.isNotEmpty ? " (dine favoritter)" : ""}*');
      for (final item in trumfItems) {
        final rate = item.rate != null ? ' – ${item.rate!.toStringAsFixed(0)} p/100kr' : '';
        buf.writeln('• ${item.store}$rate');
      }
      buf.writeln('👉 https://trumfnetthandel.no\n');
    }
    if (sasItems.isNotEmpty) {
      buf.writeln('✈️ *SAS Online Shopping${sasFavs.isNotEmpty ? " (dine favoritter)" : ""}*');
      for (final item in sasItems) {
        final rate = item.rate != null ? ' – ${item.rate!.toStringAsFixed(0)} p/100kr' : '';
        buf.writeln('• ${item.store}$rate');
      }
      buf.writeln('👉 https://onlineshopping.flysas.com/nb-NO\n');
    }
    buf.writeln('_Last ned Bonusvarsel-appen for full oversikt_');
    return buf.toString();
  }

  static Future<void> _dispatchNotification({
    required String email, required String telegram,
    required String message, required int sasCount, required int trumfCount,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) await FirebaseAuth.instance.signInAnonymously();
      final callable = FirebaseFunctions.instance
          .httpsCallable('sendWeeklyOfferNotification');
      await callable.call({
        'email': email, 'telegram': telegram, 'message': message,
        'sasCount': sasCount, 'trumfCount': trumfCount,
      });
    } catch (_) {}
  }
}
DART
echo "✅ notification_service.dart opprettet"
