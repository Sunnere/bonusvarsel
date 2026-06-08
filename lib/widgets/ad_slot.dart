import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/brand_theme.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/ad_slot.dart';
import '../services/ad_service.dart';
import '../services/boost_lock_service.dart';
import '../services/paywall_trigger_service.dart';

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

  static const int _safeMaxLinesTitle = 2;
  static const int _safeMaxLinesBody = 2;

  bool _counted = false;

  bool get _isPremiumPlacement {
    final p = widget.placement.toLowerCase();
    return p.contains('premium') || p.contains('elite');
  }

  bool get _isElitePlacement {
    final p = widget.placement.toLowerCase();
    return p.contains('elite');
  }

  bool get _isLocked => BoostLockService.isLocked(widget.placement);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_counted) {
      _counted = true;
      AdService.instance.recordImpression(
        placement: widget.placement,
        adId: widget.slot.id,
      );
    }
  }

  // ignore: use_build_context_synchronously
  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
  }

  Future<void> _handleTap() async {
    if (_isLocked) {
      await PaywallTriggerService.showPaywall(
        context,
        source: 'locked_ad',
        title: _isElitePlacement
            ? 'Lås opp Elite-fordeler'
            : 'Lås opp flere tilbud',
        subtitle: _isElitePlacement
            ? 'Elite gir tilgang til flere programmer, mer prioriterte valg og enda flere bonusmuligheter.'
            : 'Premium gir tilgang til flere butikker, høyere bonus og smartere valg.',
      );
      return;
    }

    if (widget.slot.link.trim().isEmpty) return;

    await AdService.instance.recordClick(
      placement: widget.placement,
      adId: widget.slot.id,
    );
    await PaywallTriggerService.registerAdClick(context);
    await _openUrl(widget.slot.link);
  }

  String _displayTitle(AdSlot slot) {
    final raw = slot.title.trim();
    if (!_isPremiumPlacement) return raw;

    final lower = raw.toLowerCase();
    final looksGenericAmex = lower == 'amex' ||
        lower == 'american express' ||
        lower.contains('amex: høy poeng') ||
        raw.endsWith('...');

    if (looksGenericAmex) {
      return _isElitePlacement
          ? 'American Express Platinum'
          : 'American Express Gold';
    }

    return raw;
  }

  String _displayBody(AdSlot slot) {
    final raw = slot.body.trim();
    if (!_isPremiumPlacement) return raw;

    final lower = raw.toLowerCase();
    final looksGeneric = lower.contains('bruk amex på hverdagskjøp') ||
        lower.contains('bygg poeng raskere') ||
        lower.contains('relevant kort eller tilbud');

    if (looksGeneric) {
      return _isElitePlacement
          ? 'Bygg poeng raskere med premiumfordeler, reisegoder og sterkere verdi for hyppige reisende.'
          : 'Tjen flere poeng på kjøp og få bedre oversikt over kortfordeler og reiserelevante tilbud.';
    }

    return raw;
  }

  String _displayCta(AdSlot slot) {
    final raw = slot.cta.trim();
    if (_isLocked) {
      return _isElitePlacement ? 'Lås opp Elite' : 'Lås opp Premium';
    }
    if (!_isPremiumPlacement) return raw.isEmpty ? 'Se tilbud' : raw;
    if (raw.isEmpty || raw.toLowerCase() == 'se tilbud') {
      return 'Se kort & fordeler';
    }
    return raw;
  }

  String get _disclaimerText {
    if (!_isPremiumPlacement) return '';
    return 'Eksempelplassering – ikke et aktivt partnerskap';
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final title = _displayTitle(slot);
    final body = _displayBody(slot);
    final cta = _displayCta(slot);

    const navy = Color(0xFF245AA8);
    const navy2 = Color(0xFF163A70);
    const gold = BrandTheme.gold;
    const premiumGreen = Color(0xFF22C55E);
    const elitePurple = Color(0xFF7C5CFF);

    final accentTop = _isElitePlacement
        ? const Color(0xFFD4AF37)
        : (_isPremiumPlacement ? premiumGreen : gold);

    final badgeBg = _isPremiumPlacement
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.22);

    final badgeBorder = _isPremiumPlacement
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.32);

    final lockAccent = _isElitePlacement ? elitePurple : premiumGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Opacity(
        opacity: _isLocked ? 0.94 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [navy, navy2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _isPremiumPlacement
                  ? accentTop.withValues(alpha: 0.34)
                  : Colors.transparent,
              width: _isPremiumPlacement ? 1.1 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Accent stripe removed for consistent design
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                child: Column(
              mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isElitePlacement
                              ? Icons.workspace_premium
                              : Icons.flight_takeoff,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.surface,
                            ),
                          ),
                        ),
                        if (_isLocked) ...[
                          _tierChip(
                            label: _isElitePlacement ? 'Elite' : 'Premium',
                            accent: lockAccent,
                            icon: Icons.lock_outline,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: const Text(
                            'Annonse',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      maxLines: _isPremiumPlacement ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _isPremiumPlacement ? 14 : 13,
                        height: 1.28,
                        color: Colors.white.withValues(alpha: 0.98),
                        fontWeight:
                            _isPremiumPlacement ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (_isLocked) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: lockAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: lockAccent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
              mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(Icons.lock_outline, size: 16, color: lockAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isElitePlacement
                                    ? 'Låst for Elite – åpne for flere bonusmuligheter'
                                    : 'Låst for Premium – åpne for høyere bonus og flere tilbud',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _isLocked ? lockAccent : accentTop,
                          foregroundColor: _isLocked ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _handleTap,
                        icon: Icon(
                          _isLocked ? Icons.lock_open_outlined : Icons.open_in_new,
                          size: 18,
                        ),
                        label: Text(
                    cta,
                    maxLines: _safeMaxLinesTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (_disclaimerText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                    _disclaimerText,
                    maxLines: _safeMaxLinesTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tierChip({
    required String label,
    required Color accent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
              mainAxisSize: MainAxisSize.max,children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
                    label,
                    maxLines: _safeMaxLinesTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}