class OfferFeedItem {
  final String id;
  final String program;
  final String programLabel;
  final String storeId;
  final String storeName;
  final String category;
  final String subcategory;
  final double rate;
  final String rateText;
  final String currency;
  final String level;
  final String source;
  final String campaign;
  final List<String> tags;
  final String url;
  final String validFrom;
  final String validTo;
  final String updatedAt;
  final String lastSeenAt;
  final bool isActive;
  final bool isExpired;
  final double confidence;

  const OfferFeedItem({
    required this.id,
    required this.program,
    required this.programLabel,
    required this.storeId,
    required this.storeName,
    required this.category,
    required this.subcategory,
    required this.rate,
    required this.rateText,
    required this.currency,
    required this.level,
    required this.source,
    required this.campaign,
    required this.tags,
    required this.url,
    required this.validFrom,
    required this.validTo,
    required this.updatedAt,
    required this.lastSeenAt,
    required this.isActive,
    required this.isExpired,
    required this.confidence,
  });

  factory OfferFeedItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    return OfferFeedItem(
      id: (json['id'] ?? '').toString(),
      program: (json['program'] ?? 'other').toString(),
      programLabel: (json['programLabel'] ?? '').toString(),
      storeId: (json['storeId'] ?? '').toString(),
      storeName: (json['storeName'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      subcategory: (json['subcategory'] ?? '').toString(),
      rate: parseDouble(json['rate']),
      rateText: (json['rateText'] ?? '').toString(),
      currency: (json['currency'] ?? 'NOK').toString(),
      level: (json['level'] ?? 'free').toString(),
      source: (json['source'] ?? '').toString(),
      campaign: (json['campaign'] ?? '').toString(),
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      url: (json['url'] ?? '').toString(),
      validFrom: (json['validFrom'] ?? '').toString(),
      validTo: (json['validTo'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      lastSeenAt: (json['lastSeenAt'] ?? '').toString(),
      isActive: json['isActive'] == true,
      isExpired: json['isExpired'] == true,
      confidence: parseDouble(json['confidence']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'program': program,
      'programLabel': programLabel,
      'storeId': storeId,
      'storeName': storeName,
      'category': category,
      'subcategory': subcategory,
      'rate': rate,
      'rateText': rateText,
      'currency': currency,
      'level': level,
      'source': source,
      'campaign': campaign,
      'tags': tags,
      'url': url,
      'validFrom': validFrom,
      'validTo': validTo,
      'updatedAt': updatedAt,
      'lastSeenAt': lastSeenAt,
      'isActive': isActive,
      'isExpired': isExpired,
      'confidence': confidence,
    };
  }
}
