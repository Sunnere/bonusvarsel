import 'package:flutter/material.dart';

/// Viser et instruksjonsbilde fra bonusvarsel/info i Cloudinary,
/// til bruk i ℹ️-dialoger og hjelpetekster.
///
/// Bruk:  InfoImage(name: 'trumf-qr-kasse-kiwi')
/// Viser skimmer under lasting og en diskret feilboks offline -
/// aldri et tomt hull eller en rå feil.
class InfoImage extends StatelessWidget {
  const InfoImage({
    super.key,
    required this.name,
    this.maxHeight = 260,
    this.borderRadius = 12,
  });

  /// Filnavnet i bonusvarsel/info, uten sti og uten .jpg
  /// (f.eks. 'trumf-qr-kasse-kiwi')
  final String name;
  final double maxHeight;
  final double borderRadius;

  static const String _base =
      'https://res.cloudinary.com/ds3xrvivm/image/upload/f_auto,q_auto,w_800';

  @override
  Widget build(BuildContext context) {
    final url = '$_base/bonusvarsel/info/$name.jpg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              height: maxHeight,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 80,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Text(
              'Bilde ikke tilgjengelig',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
