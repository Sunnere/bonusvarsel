class ActivatedNotification {
  final String id;
  final String offerId;
  final String storeId;
  final String store;
  final String source;
  final String category;
  final String title;
  final String body;
  final String level;
  final String rateText;
  final String activatedAt;
  final String expires;

  const ActivatedNotification({
    required this.id,
    required this.offerId,
    required this.storeId,
    required this.store,
    required this.source,
    required this.category,
    required this.title,
    required this.body,
    required this.level,
    required this.rateText,
    required this.activatedAt,
    required this.expires,
  });

  factory ActivatedNotification.fromJson(Map<String, dynamic> json) {
    return ActivatedNotification(
      id: (json['id'] ?? '').toString(),
      offerId: (json['offerId'] ?? '').toString(),
      storeId: (json['storeId'] ?? '').toString(),
      store: (json['store'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      rateText: (json['rateText'] ?? '').toString(),
      activatedAt: (json['activatedAt'] ?? '').toString(),
      expires: (json['expires'] ?? '').toString(),
    );
  }
}
