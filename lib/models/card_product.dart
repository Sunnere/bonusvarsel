class CardProduct {
  final String id;
  final String name;
  final String network; // Amex / Mastercard / Visa / Trumf etc
  final int defaultRatePer100; // poeng per 100 kr (manuell)
  final String? url;

  const CardProduct({
    required this.id,
    required this.name,
    required this.network,
    required this.defaultRatePer100,
    this.url,
  });
}
