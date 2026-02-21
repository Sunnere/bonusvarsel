class ShopOffer {
  final String name;
  final double rate; // poeng pr 100 kr
  final String url;
  final String category;
  final bool isCampaign;

  const ShopOffer({
    required this.name,
    required this.rate,
    required this.url,
    required this.category,
    required this.isCampaign,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'rate': rate,
        'url': url,
        'category': category,
        'isCampaign': isCampaign,
      };

  static ShopOffer? fromAny(dynamic v) {
    if (v is! Map) return null;
    final m = Map<String, dynamic>.from(v);

    final name = (m['name'] ?? m['shop'] ?? '').toString().trim();
    if (name.isEmpty) return null;

    final rateRaw = m['rate'] ?? m['points'] ?? m['poeng'] ?? 0;
    final double rate = (rateRaw is num)
        ? rateRaw.toDouble()
        : (double.tryParse(rateRaw.toString()) ?? 0.0);

    final url = (m['url'] ?? m['link'] ?? '').toString().trim();
    final category = (m['category'] ?? m['cat'] ?? 'Alle').toString().trim();
    final isCampaign = (m['isCampaign'] ?? m['campaign'] ?? false) == true;

    return ShopOffer(
      name: name,
      rate: rate,
      url: url,
      category: category.isEmpty ? 'Alle' : category,
      isCampaign: isCampaign,
    );
  }
}
