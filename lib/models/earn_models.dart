// lib/models/earn_models.dart
enum Program { sas, trumf }

enum Network { amex, visa, mastercard }

enum EarnType { points, percent } // points per 100kr eller prosent cashback

class EarnRate {
  final EarnType type;

  /// Hvis type == points: points per 100 NOK
  /// Hvis type == percent: percent (f.eks 1.0 = 1%)
  final double value;

  const EarnRate.pointsPer100(this.value) : type = EarnType.points;
  const EarnRate.percent(this.value) : type = EarnType.percent;
}

class CardProduct {
  final String id;
  final String name;
  final Program program; // SAS EB eller Trumf
  final Network network; // Amex/Visa/Mastercard
  final EarnRate baseEarn; // grunnopptjening
  final String? note;

  const CardProduct({
    required this.id,
    required this.name,
    required this.program,
    required this.network,
    required this.baseEarn,
    this.note,
  });
}

class MerchantOffer {
  final String id;
  final String merchantName;
  final Program program; // EB shopping eller Trumf-nettbutikk osv
  final EarnRate earn; // typisk points per 100 eller %
  final bool isCampaign;
  final String? category;

  const MerchantOffer({
    required this.id,
    required this.merchantName,
    required this.program,
    required this.earn,
    required this.isCampaign,
    this.category,
  });
}

class TripInput {
  final double spendNok; // total spend i NOK
  final Program program;
  const TripInput({required this.spendNok, required this.program});
}

class CalcResult {
  final double earned; // poeng eller cashback-verdi
  final Program program;
  final String label; // “EuroBonus-poeng” / “Trumf-bonus”
  const CalcResult({
    required this.earned,
    required this.program,
    required this.label,
  });
}
