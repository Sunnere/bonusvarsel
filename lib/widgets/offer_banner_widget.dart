import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OfferBannerWidget extends StatefulWidget {
  final int maxItems;
  const OfferBannerWidget({super.key, this.maxItems = 3});

  @override
  State<OfferBannerWidget> createState() => _OfferBannerWidgetState();
}

class _OfferBannerWidgetState extends State<OfferBannerWidget> {
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    if (mounted) {
      setState(() {
        _offers = [
          {'name': 'Outnorth',        'points': 25, 'points_campaign': 50, 'expires': '10.05.2026'},
          {'name': 'Gina Tricot',     'points': 30, 'points_campaign': 60, 'expires': '15.05.2026'},
          {'name': 'SmartBuyGlasses', 'points': 40, 'points_campaign': 80, 'expires': '20.05.2026'},
          {'name': 'Marshall',        'points': 20, 'points_campaign': 40, 'expires': '12.05.2026'},
          {'name': 'Farnell',         'points': 15, 'points_campaign': 30, 'expires': '18.05.2026'},
        ].take(widget.maxItems).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A8A5C))));
    if (_offers.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('🔥 Aktive kampanjer',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70)),
        Text('Via SAS Shopping', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _offers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final o = _offers[i];
            final name = o['name'] as String;
            final pts = o['points_campaign'] ?? o['points'] ?? 0;
            final normal = o['points'] ?? 0;
            final expires = o['expires'] as String? ?? '';
            final isCamp = pts > normal;
            return GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://onlineshopping.flysas.com/nb-NO'),
                  mode: LaunchMode.externalApplication),
              child: Container(
                width: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isCamp
                      ? const Color(0xFF1A8A5C).withOpacity(0.4) : Colors.white12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A8A5C).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(name[0],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                            color: Color(0xFF4ADE80)))),
                  ),
                  const SizedBox(height: 6),
                  Text(name, style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  if (isCamp) Text('$normal p/100kr',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough)),
                  Text('$pts p/100kr', style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isCamp ? const Color(0xFF4ADE80) : Colors.white)),
                  if (expires.isNotEmpty) Text('Til $expires',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
