import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'custom_card.dart';
import 'nutrition_progress_bar.dart';

class StepsProgressCard extends StatelessWidget {
  const StepsProgressCard({
    super.key,
    required this.steps,
    required this.goal,
    required this.progress,
    required this.statusText,
    required this.isLive,
    this.actionLabel,
    this.onActionPressed,
  });

  final int steps;
  final int goal;
  final double progress;
  final String statusText;
  final bool isLive;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
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
                  color: AppTheme.accentOlive.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_walk_rounded,
                    color: AppTheme.accentOlive),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Steps',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isLive
                          ? AppTheme.accentSage
                          : Theme.of(context).colorScheme.secondary)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isLive ? 'Live' : 'Paused',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isLive
                            ? AppTheme.accentSage
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$steps',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'of $goal steps',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          NutritionProgressBar(progress: progress, color: AppTheme.accentOlive),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onActionPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
