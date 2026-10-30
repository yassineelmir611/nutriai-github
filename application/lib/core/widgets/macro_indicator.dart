import 'package:flutter/material.dart';

import 'custom_card.dart';
import 'nutrition_progress_bar.dart';

class MacroIndicator extends StatelessWidget {
  const MacroIndicator({
    super.key,
    required this.title,
    required this.icon,
    required this.current,
    required this.goal,
    required this.color,
    this.unit = 'g',
  });

  final String title;
  final IconData icon;
  final double current;
  final double goal;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (current / goal).clamp(0, 1).toDouble();
    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${current.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)} $unit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          NutritionProgressBar(progress: progress, color: color),
        ],
      ),
    );
  }
}
