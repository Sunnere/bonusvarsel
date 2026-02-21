import '../models/eb_shop.dart';

class EarnResult {
  final int merchantPoints;
  final int cardPoints;
  int get total => merchantPoints + cardPoints;

  const EarnResult({required this.merchantPoints, required this.cardPoints});
}

class EarnEngine {
  /// amountNok: beløp i NOK som brukeren “simulerer”
  /// merchantRatePer100: f.eks "10" betyr 10p per 100kr
  static int merchantPoints({
    required double amountNok,
    required int merchantRatePer100,
  }) {
    if (amountNok <= 0 || merchantRatePer100 <= 0) return 0;
    return ((amountNok / 100.0) * merchantRatePer100).round();
  }

  /// cardRatePer100: f.eks 20 betyr 20p per 100kr
  static int cardPoints({
    required double amountNok,
    required int cardRatePer100,
  }) {
    if (amountNok <= 0 || cardRatePer100 <= 0) return 0;
    return ((amountNok / 100.0) * cardRatePer100).round();
  }

  /// Enkel v1: merchant + card (stacking)
  static EarnResult estimate({
    required double amountNok,
    required EbShop shop,
    required int cardRatePer100,
  }) {
    final mr = _parseRatePer100(shop);
    final m = merchantPoints(amountNok: amountNok, merchantRatePer100: mr);
    final c = cardPoints(amountNok: amountNok, cardRatePer100: cardRatePer100);
    return EarnResult(merchantPoints: m, cardPoints: c);
  }

  /// Henter "poeng per 100" fra EbShop (du har ofte cashback som string)
  static int _parseRatePer100(EbShop shop) {
    // Støtter f.eks "10", "10p", "10 poeng", "10/100", "10 per 100"
    final raw = (shop.cashback ?? '').trim().toLowerCase();
    if (raw.isEmpty) return 0;
    final m = RegExp(r'(\d+)').firstMatch(raw);
    if (m == null) return 0;
    return int.tryParse(m.group(1)!) ?? 0;
  }
}
