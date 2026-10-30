import 'package:flutter/material.dart';

class NutritionProgressBar extends StatelessWidget {
  const NutritionProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 8,
  });

  final double progress;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safe = progress.clamp(0, 1).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: color.withValues(alpha: 0.15)),
            AnimatedFractionallySizedBox(
              widthFactor: safe,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
