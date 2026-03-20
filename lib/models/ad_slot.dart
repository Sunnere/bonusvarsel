class AdSlot {
  final String id;
  
  // Monetization
  final bool isSponsored;     // true => paid placement eligible
  final double bidCpm;        // advertiser bid, normalized (e.g. 0–100)
  final int guaranteePerDay;  // guaranteed impressions per day (0 = none)
  final int priority;         // higher wins ties (0 default)
final String title;
  final String body;
  final String cta;
  final String link; // <-- use link (not url)
  final String? imageUrl;

  final List<String> tags;
  final bool premiumOnly;

  const AdSlot({
    this.isSponsored = false,
    this.bidCpm = 0.0,
    this.guaranteePerDay = 0,
    this.priority = 0,

    required this.id,
    required this.title,
    required this.body,
    required this.cta,
    required this.link,
    this.imageUrl,
    this.tags = const <String>[],
    this.premiumOnly = false,
  });
}
