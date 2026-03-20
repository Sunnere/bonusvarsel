import 'package:flutter/material.dart';

enum EliteBadgeType {
  premium, // "Premium"
  plus,    // "Boost"
  elite,   // "Trygt"
}

/// Small pill badge used in the premium header.
/// We keep the existing enum names (premium/plus/elite) to avoid breaking call sites,
/// but we render human labels that match the UI concept.
class EliteBadgeChip extends StatelessWidget {
  final EliteBadgeType type;

  const EliteBadgeChip({
    super.key,
    required this.type,
  });

  String get _label {
    switch (type) {
      case EliteBadgeType.premium:
        return 'Premium';
      case EliteBadgeType.plus:
        return 'Boost';
      case EliteBadgeType.elite:
        return 'Trygt';
    }
  }

  @override
  Widget build(BuildContext context) {

    // B/C: subtle, readable, "official" feel
    final bg = Colors.white.withValues(alpha: 0.92);
    final fg = Colors.black.withValues(alpha: 0.82);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        color: bg,
        borderRadius: BorderRadius.circular(999),
              ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
