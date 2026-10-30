import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/activity_calendar.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/nutrition_progress_bar.dart';
import '../../data/models/daily_activity_summary.dart';
import '../../data/models/daily_nutrition_totals.dart';
import '../../providers/history_provider.dart';
import '../../providers/profile_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedMonth = AppDateUtils.startOfMonth(today);
    _selectedDate = AppDateUtils.startOfDay(today);
  }

  void _changeMonth(int delta) {
    final nextMonth = AppDateUtils.addMonths(_focusedMonth, delta);
    final today = AppDateUtils.startOfDay(DateTime.now());

    setState(() {
      _focusedMonth = nextMonth;
      _selectedDate = AppDateUtils.isSameMonth(today, nextMonth)
          ? today
          : AppDateUtils.startOfMonth(nextMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final summaries = ref.watch(dailyActivityMapProvider);
    final currentGoals = DailyNutritionTotals(
      calories: profile?.dailyCaloriesGoal ?? 0,
      protein: profile?.dailyProteinGoal ?? 0,
      fat: profile?.dailyFatGoal ?? 0,
    );
    final currentStepsGoal =
        profile?.dailyStepsGoal ?? AppConstants.dailyStepsGoal;

    final selectedSummary = summaries[AppDateUtils.groupKey(_selectedDate)] ??
        DailyActivitySummary.empty(
          date: _selectedDate,
          goals: currentGoals,
          stepsGoal: currentStepsGoal,
        );

    final monthSummaries = summaries.values
        .where(
          (summary) => AppDateUtils.isSameMonth(summary.date, _focusedMonth),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final trackedSummaries =
        monthSummaries.where((summary) => summary.hasAnyData).toList();
    final nutritionSummaries =
        trackedSummaries.where((summary) => summary.hasNutrition).toList();

    final trackedDays = trackedSummaries.length;
    final monthCalories = trackedSummaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totals.calories,
    );
    final averageSteps = trackedSummaries.isEmpty
        ? 0
        : trackedSummaries.fold<int>(0, (sum, summary) => sum + summary.steps) /
            trackedSummaries.length;
    final bestNutritionDay = nutritionSummaries.isEmpty
        ? null
        : nutritionSummaries.reduce(
            (best, day) =>
                day.totals.calories >= best.totals.calories ? day : best,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Container(
        decoration: AppTheme.pageDecoration,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly overview',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A clean snapshot of your nutrition and activity.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _HistoryStatTile(
                          label: 'Tracked days',
                          value: '$trackedDays',
                          accentColor: AppTheme.primary,
                          subtitle:
                              AppDateUtils.formatMonthLabel(_focusedMonth),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HistoryStatTile(
                          label: 'Calories logged',
                          value: '${monthCalories.toStringAsFixed(0)} kcal',
                          accentColor: AppTheme.caloriesColor,
                          subtitle: 'Month total',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _HistoryStatTile(
                          label: 'Average steps',
                          value: averageSteps.toStringAsFixed(0),
                          accentColor: AppTheme.accentSage,
                          subtitle: 'Per tracked day',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HistoryStatTile(
                          label: 'Highest intake',
                          value: bestNutritionDay == null
                              ? '--'
                              : '${bestNutritionDay.totals.calories.toStringAsFixed(0)} kcal',
                          accentColor: AppTheme.accentOlive,
                          subtitle: bestNutritionDay == null
                              ? 'No entries yet'
                              : AppDateUtils.formatDateLabel(
                                  bestNutritionDay.date,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          AppDateUtils.formatMonthLabel(_focusedMonth),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _CalendarLegend(
                        label: 'Nutrition',
                        color: AppTheme.caloriesColor,
                      ),
                      _CalendarLegend(
                        label: 'Activity',
                        color: AppTheme.accentSage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ActivityCalendar(
                    month: _focusedMonth,
                    selectedDate: _selectedDate,
                    summariesByDate: summaries,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDateUtils.formatDateLabel(_selectedDate),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detailed view for the selected day',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _ProgressPanel(
                    label: 'Calories',
                    value:
                        '${selectedSummary.totals.calories.toStringAsFixed(0)} / ${selectedSummary.goals.calories.toStringAsFixed(0)} kcal',
                    progress: selectedSummary.calorieProgress,
                    color: AppTheme.caloriesColor,
                  ),
                  const SizedBox(height: 12),
                  _ProgressPanel(
                    label: 'Steps',
                    value:
                        '${selectedSummary.steps} / ${selectedSummary.stepsGoal}',
                    progress: selectedSummary.stepsProgress,
                    color: AppTheme.accentSage,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Protein',
                          value:
                              '${selectedSummary.totals.protein.toStringAsFixed(1)} g',
                          subtitle:
                              'Goal ${selectedSummary.goals.protein.toStringAsFixed(0)} g',
                          color: AppTheme.proteinColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          label: 'Fat',
                          value:
                              '${selectedSummary.totals.fat.toStringAsFixed(1)} g',
                          subtitle:
                              'Goal ${selectedSummary.goals.fat.toStringAsFixed(0)} g',
                          color: AppTheme.fatColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Meals',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (selectedSummary.meals.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.mutedSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        selectedSummary.hasActivity
                            ? 'No meals were saved for this day, but your activity was tracked.'
                            : 'No meals or activity snapshots were recorded for this day yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    ...selectedSummary.meals.map(
                      (meal) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => context.push('/meal/${meal.id}'),
                            child: Ink(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.elevatedSurface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: meal.imagePath != null
                                          ? Image.file(
                                              File(meal.imagePath!),
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: AppTheme.mutedSurface,
                                              child: const Icon(Icons.fastfood),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meal.foodName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${meal.gramsConsumed.toStringAsFixed(0)} g | ${meal.calories.toStringAsFixed(0)} kcal',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AppTheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    AppDateUtils.formatTimeLabel(meal.dateTime),
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
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryStatTile extends StatelessWidget {
  const _HistoryStatTile({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.subtitle,
  });

  final String label;
  final String value;
  final Color accentColor;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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
          const SizedBox(height: 4),
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

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        NutritionProgressBar(
          progress: progress,
          color: color,
          height: 10,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
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
