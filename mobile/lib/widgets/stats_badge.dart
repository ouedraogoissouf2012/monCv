import 'package:flutter/material.dart';

class StatsBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const StatsBadge({
    super.key,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}
