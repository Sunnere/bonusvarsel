class FeedItem {
  final String id;
  final String store;
  final String source;
  final String category;
  final num rate;
  final String rateText;
  final bool campaign;
  final String expires;
  final String level;
  final bool lockedForFree;

  const FeedItem({
    required this.id,
    required this.store,
    required this.source,
    required this.category,
    required this.rate,
    required this.rateText,
    required this.campaign,
    required this.expires,
    required this.level,
    required this.lockedForFree,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: (json['id'] ?? '').toString(),
      store: (json['store'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      rate: (json['rate'] ?? 0) as num,
      rateText: (json['rateText'] ?? '').toString(),
      campaign: (json['campaign'] ?? false) == true,
      expires: (json['expires'] ?? '').toString(),
      level: (json['level'] ?? 'standard').toString(),
      lockedForFree: (json['lockedForFree'] ?? false) == true,
    );
  }
}
