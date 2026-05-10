#!/bin/bash
cat > ~/bonusvarsel/lib/services/trumf_calculator.dart << 'DART'
/// Trumf opptjenings- og overføringslogikk for BonusVarsel
/// Basert på offisielle satser fra trumf.no (mai 2026)
///
/// OPPTJENINGSSATSER:
/// - Grunnbonus (alle betalingsmåter):          1 % av handlebeløp
/// - + Trumf Pay:                               1 % ekstra → totalt 2 %
/// - + Trumf Kredittkort (dagligvare):          1 % ekstra → totalt 2 %
/// - + Trumf Kredittkort via Trumf Pay:         2 % ekstra → totalt 3 %
/// - Trippel-Trumf Torsdag (ekstra):           +2 % ekstra
///
/// OVERFØRING TIL SAS EUROBONUS:
///   - Engangsoverføring:     1 kr Trumf = 10 EuroBonus-poeng
///   - Automatisk overføring: 1 kr Trumf = 13,5 EuroBonus-poeng

class TrumfCalculator {
  static const double grunnbonus = 0.01;
  static const double trumfPayEkstra = 0.01;
  static const double kredittKortEkstra = 0.01;
  static const double trippelTrumfEkstra = 0.02;
  static const double talkmoreBonus = 0.04;
  static const double fjordkraftBonus = 0.01;
  static const double euroBonusPerKroneEngang = 10.0;
  static const double euroBonusPerKroneAutomatisk = 13.5;

  static double beregnBonus({
    required double belop,
    bool brukKredittkort = false,
    bool brukTrumfPay = false,
    bool erTrippelTrumfTorsdag = false,
  }) {
    double sats = grunnbonus;
    if (brukKredittkort && brukTrumfPay) {
      sats += kredittKortEkstra + trumfPayEkstra;
    } else if (brukKredittkort) {
      sats += kredittKortEkstra;
    } else if (brukTrumfPay) {
      sats += trumfPayEkstra;
    }
    if (erTrippelTrumfTorsdag) sats += trippelTrumfEkstra;
    return belop * sats;
  }

  static double beregnMaanedligBonus({
    required double maanedligDagligvare,
    bool brukKredittkort = false,
    bool brukTrumfPay = false,
    double maanedligMobil = 0,
    double maanedligStrom = 0,
  }) {
    final dagligvareBonus = beregnBonus(
      belop: maanedligDagligvare,
      brukKredittkort: brukKredittkort,
      brukTrumfPay: brukTrumfPay,
    );
    return dagligvareBonus + (maanedligMobil * talkmoreBonus) + (maanedligStrom * fjordkraftBonus);
  }

  static double konverterTilEuroBonus({
    required double trumfKroner,
    bool automatiskOverforing = false,
  }) {
    final kurs = automatiskOverforing ? euroBonusPerKroneAutomatisk : euroBonusPerKroneEngang;
    return trumfKroner * kurs;
  }

  static String genererRad({
    required double maanedligBonus,
    bool harKredittkort = false,
    bool harTalkmore = false,
    bool harFjordkraft = false,
  }) {
    final aarligBonus = maanedligBonus * 12;
    final buffer = StringBuffer();
    buffer.writeln('Med din profil sparer du ca. ${maanedligBonus.toStringAsFixed(0)} kr/mnd (${aarligBonus.toStringAsFixed(0)} kr/år) i Trumf-bonus.');
    buffer.writeln('');
    buffer.writeln('📦 Hva er bonusen din verdt i EuroBonus?');
    buffer.writeln('• Engangsoverføring: ${konverterTilEuroBonus(trumfKroner: aarligBonus).toStringAsFixed(0)} poeng/år (10 p/kr)');
    buffer.writeln('• Automatisk overføring: ${konverterTilEuroBonus(trumfKroner: aarligBonus, automatiskOverforing: true).toStringAsFixed(0)} poeng/år (13,5 p/kr) ✅ Anbefalt');
    buffer.writeln('');
    if (!harKredittkort) buffer.writeln('💳 Tips: Med Trumf Kredittkort dobler du bonusen på dagligvarer (2 % i stedet for 1 %). På Trippel-Trumf Torsdag får du hele 4 %.');
    if (!harTalkmore) buffer.writeln('📱 Tips: Bytter du til Talkmore får du 4 % Trumf-bonus på hele mobilregningen.');
    if (!harFjordkraft) buffer.writeln('⚡ Tips: Med Fjordkraft sparer du 1 % Trumf-bonus på strømregningen.');
    buffer.writeln('');
    buffer.writeln('🔁 Sett opp automatisk overføring for å få 35 % mer EuroBonus-poeng. Husk: Trumf-saldoen må være under 200 kr når du aktiverer dette.');
    return buffer.toString();
  }
}
DART
echo "✅ Fil opprettet: lib/services/trumf_calculator.dart"
