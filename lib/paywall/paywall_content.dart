class PaywallPlanOption {
  final String id;
  final String title;
  final String price;
  final String subtext;
  final String badge;
  final bool highlighted;

  const PaywallPlanOption({
    required this.id,
    required this.title,
    required this.price,
    required this.subtext,
    this.badge = '',
    this.highlighted = false,
  });
}

class PaywallFeature {
  final String title;
  final String subtitle;

  const PaywallFeature({
    required this.title,
    required this.subtitle,
  });
}

class PaywallContent {
  static const String title = 'Få maks bonuspoeng – automatisk';
  static const String subtitle =
      'Se beste valg, lås opp boosts og få varsler som kan spare deg tusenvis i året.';
  static const String cta = 'Fortsett til betaling';
  static const String restore = 'Gjenopprett kjøp';
  static const String disclaimer = 'Ingen binding. Avslutt når som helst.';
  static const String valueStrip = 'Typisk verdi: 1.500–8.000 poeng per måned';

  static const List<PaywallFeature> features = [
    PaywallFeature(
      title: 'Beste valg hver gang',
      subtitle: 'Se hvor du bør handle og hvilket kort som gir mest verdi.',
    ),
    PaywallFeature(
      title: 'Premium boosts',
      subtitle: 'Lås opp høyere bonus og tydelige “Boost i Premium”-fordeler.',
    ),
    PaywallFeature(
      title: 'Varsler i sanntid',
      subtitle: 'Få beskjed når kampanjer og gode bonusmuligheter dukker opp.',
    ),
    PaywallFeature(
      title: 'Full oversikt',
      subtitle: 'Se alle butikker, kampanjer og filtre uten begrensninger.',
    ),
  ];

  static const List<PaywallPlanOption> plans = [
    PaywallPlanOption(
      id: 'monthly',
      title: 'Måned',
      price: '49 kr / mnd',
      subtext: 'Lav terskel. Perfekt for å teste.',
    ),
    PaywallPlanOption(
      id: 'yearly',
      title: 'År',
      price: '399 kr / år',
      subtext: 'Best verdi. Tilsvarer 33 kr / mnd.',
      badge: 'Mest verdi',
      highlighted: true,
    ),
  ];
}
