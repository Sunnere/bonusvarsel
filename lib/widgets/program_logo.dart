import 'package:flutter/material.dart';

/// Viser den offisielle logoen for et bonusprogram, levert fra Cloudinary.
///
/// Bruk:  ProgramLogo(program: 'trumf', size: 28)
/// Faller tilbake til et farget initial-merke hvis bildet ikke kan lastes
/// (f.eks. offline), slik at UI aldri viser et tomt hull.
class ProgramLogo extends StatelessWidget {
  const ProgramLogo({
    super.key,
    required this.program,
    this.size = 28,
  });

  /// Program-id: 'trumf', 'sas' (eller 'sas_eurobonus'), 'flying_blue'
  final String program;
  final double size;

  static const String _base =
      'https://res.cloudinary.com/ds3xrvivm/image/upload/f_auto,q_auto';

  static const Map<String, String> _publicIds = {
    'trumf': 'bonusvarsel/logos/trumf',
    'sas': 'bonusvarsel/logos/sas-eurobonus',
    'sas_eurobonus': 'bonusvarsel/logos/sas-eurobonus',
    'sas_online': 'bonusvarsel/logos/sas-eurobonus',
    'flying_blue': 'bonusvarsel/logos/flying-blue',
  };

  static const Map<String, Color> _fallbackColors = {
    'trumf': Color(0xFF00A651),
    'sas': Color(0xFF000F5D),
    'sas_eurobonus': Color(0xFF000F5D),
    'sas_online': Color(0xFF000F5D),
    'flying_blue': Color(0xFF051039),
  };

  String? get _url {
    final id = _publicIds[program.toLowerCase()];
    if (id == null) return null;
    // Be om 2x oppløsning for skarphet på retina-skjermer
    final w = (size * 2).round();
    return '$_base,w_$w/$id.png';
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return _fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(),
      ),
    );
  }

  Widget _fallback() {
    final color = _fallbackColors[program.toLowerCase()] ?? Colors.blueGrey;
    final letter = program.isNotEmpty ? program[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
    );
  }
}
