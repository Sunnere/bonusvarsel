import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/brand_theme.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/ad_slot.dart';
import '../services/ad_service.dart';

class AdSlotCard extends StatefulWidget {
  final AdSlot slot;
  final String placement;

  const AdSlotCard({
    super.key,
    required this.slot,
    required this.placement,
  });

  @override
  State<AdSlotCard> createState() => _AdSlotCardState();
}

class _AdSlotCardState extends State<AdSlotCard> {
  bool _counted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Count impression once per mount
    if (!_counted) {
      _counted = true;
      AdService.instance.recordImpression(
        placement: widget.placement,
        adId: widget.slot.id,
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  
  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;

    const navy = BrandTheme.navy;
    const navy2 = BrandTheme.navy2;
    const gold = BrandTheme.gold;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [navy, navy2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flight_takeoff, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slot.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.surface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: const Text(
                          'Annonse',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    slot.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: slot.link.trim().isEmpty
                          ? null
                          : () async {
                              await AdService.instance.recordClick(
                                placement: widget.placement,
                                adId: slot.id,
                              );
                              await _openUrl(slot.link);
                            },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(slot.cta, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
