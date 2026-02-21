import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/mam_offer.dart';

class MamLoader {
  static Future<List<MamOffer>> load() async {
    final jsonString = await rootBundle.loadString(
      'assets/mam.offers.min.json',
    );

    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('mam.offers.min.json: root is not an object');
    }

    final rawOffers = decoded['offers'];
    if (rawOffers is! List) {
      throw Exception('mam.offers.min.json: "offers" missing');
    }

    final all = rawOffers
        .whereType<Map<String, dynamic>>()
        .map(MamOffer.fromJson)
        .toList();

    // 🔥 KJERNEN: kun EuroBonus-relevant
    final euroBonusOnly = all.where((o) {
      // eksplisitt flag (fra steg 1)
      if (o.isEuroBonus) return true;

      // fallback: partnernavn
      final name = o.partnerName.toLowerCase();
      if (name.contains('sas')) return true;
      if (name.contains('eurobonus')) return true;
      if (name.contains('trumf')) return true;

      // indirekte EB (BillKill, kurs, etc)
      if (o.earnMethod == 'indirect') return true;

      return false;
    }).toList();

    // Sortert pent
    euroBonusOnly.sort((a, b) => a.partnerName.compareTo(b.partnerName));

    return euroBonusOnly;
  }
}
