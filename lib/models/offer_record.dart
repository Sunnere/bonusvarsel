class OfferRecord {
  final String id;
  final String storeId;
  final num rate;
  final String rateText;
  final bool campaign;
  final String expires;
  final String level;

  const OfferRecord({
    required this.id,
    required this.storeId,
    required this.rate,
    required this.rateText,
    required this.campaign,
    required this.expires,
    required this.level,
  });

  factory OfferRecord.fromJson(Map<String, dynamic> json) {
    return OfferRecord(
      id: (json['id'] ?? '').toString(),
      storeId: (json['storeId'] ?? '').toString(),
      rate: (json['rate'] ?? 0) as num,
      rateText: (json['rateText'] ?? '').toString(),
      campaign: (json['campaign'] ?? false) == true,
      expires: (json['expires'] ?? '').toString(),
      level: (json['level'] ?? 'standard').toString(),
    );
  }
}
