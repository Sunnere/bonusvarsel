/// NivapoengService – Elite-funksjon for SAS EuroBonus statusberegning
/// Basert på offisielle 2026-satser:
///   Sølv: 20 000 nivåpoeng (+25% bonuspoeng)
///   Gull: 45 000 nivåpoeng (+50% bonuspoeng)
///   Diamant: 90 000 nivåpoeng (+75% bonuspoeng, ingen poengutløp)
///
/// VIKTIG: Nivåpoeng nullstilles hver 12-mnd kvalifiseringsperiode.
/// Bonuspoeng varer 4-5 år. Hold de to fra hverandre.
library;

class EuroBonusTier {
  final String name;
  final int minPoints;
  final int bonusBoostPercent;
  const EuroBonusTier(this.name, this.minPoints, this.bonusBoostPercent);
}

class NivapoengStatus {
  final String currentTier;
  final int bonusBoostPercent;
  final int? pointsToNext;
  final String? nextTier;
  final int? kronerToNext;
  final bool isMaxed;

  NivapoengStatus({
    required this.currentTier,
    required this.bonusBoostPercent,
    this.pointsToNext,
    this.nextTier,
    this.kronerToNext,
    this.isMaxed = false,
  });
}

class NivapoengService {
  static const List<EuroBonusTier> tiers = [
    EuroBonusTier('Medlem', 0, 0),
    EuroBonusTier('Sølv', 20000, 25),
    EuroBonusTier('Gull', 45000, 50),
    EuroBonusTier('Diamant', 90000, 75),
  ];

  /// Beregn status fra antall nivåpoeng
  static NivapoengStatus calculate(int nivapoeng) {
    EuroBonusTier current = tiers[0];
    EuroBonusTier? next;

    for (int i = 0; i < tiers.length; i++) {
      if (nivapoeng >= tiers[i].minPoints) {
        current = tiers[i];
        next = (i + 1 < tiers.length) ? tiers[i + 1] : null;
      }
    }

    if (next == null) {
      return NivapoengStatus(
        currentTier: current.name,
        bonusBoostPercent: current.bonusBoostPercent,
        isMaxed: true,
      );
    }

    final toNext = next.minPoints - nivapoeng;
    // SAS Amex gir ~25% nivåpoeng av bonuspoeng (~20p/100kr)
    // → ca 20 kr forbruk per nivåpoeng
    final kroner = toNext * 20;

    return NivapoengStatus(
      currentTier: current.name,
      bonusBoostPercent: current.bonusBoostPercent,
      pointsToNext: toNext,
      nextTier: next.name,
      kronerToNext: kroner,
    );
  }

  /// Bygg Elite-melding om status
  static String buildStatusMessage(int nivapoeng) {
    final s = calculate(nivapoeng);
    final buf = StringBuffer();
    buf.writeln('👑 *Din EuroBonus-status*');
    buf.writeln('');
    buf.writeln('🏅 Nivå: ${s.currentTier} (+${s.bonusBoostPercent}% bonuspoeng)');

    if (s.isMaxed) {
      buf.writeln('💎 Høyeste nivå – ingen poengutløp!');
    } else {
      final fmt = _fmt(s.pointsToNext!);
      final kr = _fmt(s.kronerToNext!);
      buf.writeln('📈 ${fmt} nivåpoeng til ${s.nextTier}');
      buf.writeln('💳 ~$kr kr på SAS Amex for å nå dit');
      buf.writeln('');
      buf.writeln('💡 Husk: nivåpoeng nullstilles ved periodeslutt.');
    }
    return buf.toString();
  }

  static String _fmt(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }
}
