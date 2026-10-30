import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/nutrition_utils.dart';
import '../../core/widgets/curved_trend_chart.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/macro_indicator.dart';
import '../../core/widgets/steps_progress_card.dart';
import '../../providers/history_provider.dart';
import '../../providers/meals_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/steps_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final totals = ref.watch(dailyTotalsProvider);
    final meals = ref.watch(todayMealsProvider);
    final stepsState = ref.watch(stepsProvider);
    final weeklyTrend = ref.watch(weeklyActivityTrendProvider);

    if (profile == null) {
      return const Scaffold(
        body:
            Center(child: Text('Profile not set. Please complete onboarding.')),
      );
    }

    final caloriesProgress =
        NutritionUtils.safeProgress(totals.calories, profile.dailyCaloriesGoal);
    final remainingCalories =
        (profile.dailyCaloriesGoal - totals.calories).clamp(0, double.infinity);
    final averageCalories = weeklyTrend.isEmpty
        ? 0.0
        : weeklyTrend.fold<double>(0, (sum, day) => sum + day.totals.calories) /
            weeklyTrend.length;
    final bestStepsDay = weeklyTrend.isEmpty
        ? null
        : weeklyTrend.reduce(
            (best, day) => day.steps >= best.steps ? day : best,
          );
    final chartLabels = weeklyTrend
        .map((day) => AppDateUtils.formatDateLabel(day.date).split(',').first)
        .toList();
    final trendSeries = [
      TrendLineSeries(
        label: 'Calories',
        color: AppTheme.caloriesColor,
        values: weeklyTrend
            .map((day) => day.calorieProgress.clamp(0.0, 1.25).toDouble())
            .toList(),
      ),
      TrendLineSeries(
        label: 'Activity',
        color: AppTheme.accentSage,
        values: weeklyTrend
            .map((day) => day.stepsProgress.clamp(0.0, 1.25).toDouble())
            .toList(),
      ),
    ];

    String stepsStatusText = stepsState.message ?? '';
    String? stepsActionLabel;
    VoidCallback? onStepsAction;
    switch (stepsState.status) {
      case StepTrackingStatus.loading:
        stepsStatusText = 'Preparing step counter...';
        break;
      case StepTrackingStatus.active:
        stepsStatusText = 'Tracking your movement live.';
        break;
      case StepTrackingStatus.permissionDenied:
        stepsStatusText = 'Permission needed to read steps.';
        stepsActionLabel = 'Grant permission';
        onStepsAction = () => ref.read(stepsProvider.notifier).retry();
        break;
      case StepTrackingStatus.unsupported:
        stepsStatusText = 'Step tracking is not available on this device.';
        break;
      case StepTrackingStatus.error:
        stepsStatusText = 'Could not read sensor data.';
        stepsActionLabel = 'Try again';
        onStepsAction = () => ref.read(stepsProvider.notifier).retry();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.pageDecoration,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Text(
              'Hello, ${profile.name}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'A calm view of your nutrition today',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: caloriesProgress),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 10,
                                backgroundColor: AppTheme.mutedSurface,
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.primary,
                                ),
                              );
                            },
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totals.calories.toStringAsFixed(0),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'kcal',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calories',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${totals.calories.toStringAsFixed(0)} / ${profile.dailyCaloriesGoal.toStringAsFixed(0)} kcal',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${remainingCalories.toStringAsFixed(0)} kcal left',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: MacroIndicator(
                    title: 'Protein',
                    icon: Icons.fitness_center,
                    current: totals.protein,
                    goal: profile.dailyProteinGoal,
                    color: AppTheme.proteinColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MacroIndicator(
                    title: 'Fat',
                    icon: Icons.local_florist_outlined,
                    current: totals.fat,
                    goal: profile.dailyFatGoal,
                    color: AppTheme.fatColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            StepsProgressCard(
              steps: stepsState.todaySteps,
              goal: stepsState.goal,
              progress: stepsState.progress,
              statusText: stepsStatusText,
              isLive: stepsState.status == StepTrackingStatus.active,
              actionLabel: stepsActionLabel,
              onActionPressed: onStepsAction,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Curves',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Calories and activity over the last 7 days',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/history'),
                        child: const Text('Calendar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: trendSeries
                        .map(
                          (serie) => _TrendLegendChip(
                            label: serie.label,
                            color: serie.color,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  CurvedTrendChart(
                    labels: chartLabels,
                    series: trendSeries,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TrendStatCard(
                          title: 'Average calories',
                          value: '${averageCalories.toStringAsFixed(0)} kcal',
                          subtitle: 'per day this week',
                          color: AppTheme.caloriesColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TrendStatCard(
                          title: 'Best activity day',
                          value: bestStepsDay == null
                              ? '--'
                              : '${bestStepsDay.steps} steps',
                          subtitle: bestStepsDay == null
                              ? 'No activity yet'
                              : AppDateUtils.formatDateLabel(bestStepsDay.date),
                          color: AppTheme.accentSage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Journal',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: const Text('Full History'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (meals.isEmpty)
              const SizedBox(
                height: 220,
                child: EmptyState(
                  title: 'No meals yet',
                  subtitle: 'Start by analyzing your food!',
                  icon: Icons.auto_awesome_motion_outlined,
                ),
              )
            else
              ...meals.map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey(meal.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child:
                          const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) =>
                        ref.read(mealsProvider.notifier).deleteMeal(meal.id),
                    child: CustomCard(
                      onTap: () => context.push('/meal/${meal.id}'),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 62,
                              height: 62,
                              child: meal.imagePath != null
                                  ? Image.file(
                                      File(meal.imagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      child:
                                          const Icon(Icons.fastfood_outlined),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.foodName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${meal.calories.toStringAsFixed(0)} kcal | ${meal.gramsConsumed.toStringAsFixed(0)} g',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppDateUtils.formatTimeLabel(meal.dateTime),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendLegendChip extends StatelessWidget {
  const _TrendLegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF25273B),
                ),
          ),
        ],
      ),
    );
  }
}

class _TrendStatCard extends StatelessWidget {
  const _TrendStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
