import 'package:flutter/material.dart';

class EliteHeaderWidget extends StatelessWidget {
  final String title;
  final Widget? badge;
  final Widget? trailing;

  const EliteHeaderWidget({
    super.key,
    required this.title,
    this.badge,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          badge!,
        ],
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}
