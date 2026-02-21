class MamOffer {
  final String id;
  final String heading;
  final String benefit;
  final String partnerName;
  final String offerType;
  final String url;

  // 👉 NYE FELT (PRO)
  final bool isEuroBonus;
  final String earnMethod;
  // 'fly' | 'card' | 'shopping' | 'indirect'

  MamOffer({
    required this.id,
    required this.heading,
    required this.benefit,
    required this.partnerName,
    required this.offerType,
    required this.url,
    required this.isEuroBonus,
    required this.earnMethod,
  });

  factory MamOffer.fromJson(Map<String, dynamic> m) {
    final partner =
        m['partner'] is Map<String, dynamic> ? m['partner'] : const {};

    final tags = (m['tags'] is List)
        ? (m['tags'] as List).map((e) => e.toString()).toList()
        : <String>[];

    // 👉 EuroBonus-logikk (robust)
    final isEuroBonus = m['program'] == 'eurobonus' ||
        tags.contains('eurobonus') ||
        tags.contains('indirect-eb');

    // 👉 Hvordan tjenes poeng
    String earnMethod = 'indirect';
    if (tags.contains('fly')) earnMethod = 'fly';
    if (tags.contains('card')) earnMethod = 'card';
    if (tags.contains('shopping')) earnMethod = 'shopping';

    return MamOffer(
      id: (m['id'] ?? '').toString(),
      heading: (m['heading'] ?? '').toString(),
      benefit: (m['benefit'] ?? '').toString(),
      partnerName: (partner['name'] ?? 'Ukjent partner').toString(),
      offerType: (m['offerType'] ?? '').toString(),
      url: (m['url'] ?? '').toString(),
      isEuroBonus: isEuroBonus,
      earnMethod: earnMethod,
    );
  }
}

enum OfferCategory { travel, card, shopping, indirect }

extension OfferCategoryLabel on OfferCategory {
  String get label {
    switch (this) {
      case OfferCategory.travel:
        return '✈️ Reise';
      case OfferCategory.card:
        return '💳 Kort';
      case OfferCategory.shopping:
        return '🛍 Shopping';
      case OfferCategory.indirect:
        return '🔁 Indirekte';
    }
  }
}
