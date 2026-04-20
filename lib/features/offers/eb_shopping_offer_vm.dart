class EbShoppingOfferVm {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String? merchantName;
  final String? pointsText;
  final String? ctaText;
  final String? deeplink;
  final String category;
  final bool featured;
  final bool sponsored;
  final int priority;
  final DateTime? expiresAt;
  final Map<String, dynamic> raw;

  const EbShoppingOfferVm({
    required this.id,
    required this.title,
    required this.category,
    required this.raw,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.merchantName,
    this.pointsText,
    this.ctaText,
    this.deeplink,
    this.featured = false,
    this.sponsored = false,
    this.priority = 0,
    this.expiresAt,
  });

  bool get isExpired {
    final dt = expiresAt;
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }
}
