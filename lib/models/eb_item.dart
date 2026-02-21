class EbItem {
  final String id;
  final String kind; // "shop" | "campaign"
  final String name;
  final num? rate;
  final String url;
  final String? startsAt;
  final String? endsAt;

  EbItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.rate,
    required this.url,
    this.startsAt,
    this.endsAt,
  });

  factory EbItem.fromJson(Map<String, dynamic> m, String fallbackKind) {
    return EbItem(
      id: (m['id'] ?? '').toString(),
      kind: (m['kind'] ?? fallbackKind).toString(),
      name: (m['name'] ?? 'Ukjent').toString(),
      rate: m['rate'] is num ? m['rate'] as num : null,
      url: (m['url'] ?? '').toString(),
      startsAt: m['startsAt']?.toString(),
      endsAt: m['endsAt']?.toString(),
    );
  }
}
