class EbShop {
  final String id;
  final String name;
  final String url;
  final String? category;
  final String? cashback; // f.eks "5%" eller "10 EB/100kr"
  final String? logoUrl; // hvis vi har
  final bool hasCampaign; // hvis vi har kampanje-markering

  EbShop({
    required this.id,
    required this.name,
    required this.url,
    this.category,
    this.cashback,
    this.logoUrl,
    required this.hasCampaign,
  });

  factory EbShop.fromJson(Map<String, dynamic> m) {
    return EbShop(
      id: (m['id'] ?? m['slug'] ?? m['name'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      url: (m['url'] ?? '').toString(),
      category: (m['category'] ?? m['categoryName'])?.toString(),
      cashback: (m['cashback'] ?? m['rate'] ?? m['reward'])?.toString(),
      logoUrl: (m['logoUrl'] ?? m['logo'] ?? m['image'])?.toString(),
      hasCampaign: (m['hasCampaign'] == true) || (m['campaign'] == true),
    );
  }
}
