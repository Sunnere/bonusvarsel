class Campaign {
  final String title;
  final String store;
  final String details;
  final DateTime? validFrom;
  final DateTime? validTo;
  final int? multiplier;
  final String? url;

  const Campaign({
    required this.title,
    required this.store,
    required this.details,
    this.validFrom,
    this.validTo,
    this.multiplier,
    this.url,
  });
}