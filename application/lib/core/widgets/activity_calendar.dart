import 'package:flutter/material.dart';

import '../../data/models/daily_activity_summary.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

class ActivityCalendar extends StatelessWidget {
  const ActivityCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.summariesByDate,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final Map<String, DailyActivitySummary> summariesByDate;
  final ValueChanged<DateTime> onDateSelected;

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final firstDay = AppDateUtils.startOfMonth(month);
    final daysInMonth = AppDateUtils.daysInMonth(month);
    final leadingEmptyCells = (firstDay.weekday + 6) % 7;
    final totalCells = leadingEmptyCells + daysInMonth;
    final trailingEmptyCells = (7 - (totalCells % 7)) % 7;
    final totalGridCount = totalCells + trailingEmptyCells;

    return Column(
      children: [
        Row(
          children: _weekdayLabels
              .map(
                (label) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalGridCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.84,
          ),
          itemBuilder: (context, index) {
            final dayOffset = index - leadingEmptyCells;
            if (dayOffset < 0 || dayOffset >= daysInMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(month.year, month.month, dayOffset + 1);
            final summary = summariesByDate[AppDateUtils.groupKey(date)];
            final isSelected = AppDateUtils.isSameDay(date, selectedDate);
            final isToday = AppDateUtils.isToday(date);

            return _CalendarDayCell(
              date: date,
              summary: summary,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () => onDateSelected(date),
            );
          },
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.summary,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final DailyActivitySummary? summary;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNutrition = summary?.hasNutrition ?? false;
    final hasActivity = summary?.hasActivity ?? false;
    final hasAnyData = summary?.hasAnyData ?? false;
    final combinedProgress = (summary?.combinedProgress ?? 0).clamp(0.0, 1.0);

    final Color backgroundColor;
    if (isSelected) {
      backgroundColor = AppTheme.primary.withValues(alpha: 0.10);
    } else if (hasAnyData) {
      backgroundColor = theme.colorScheme.surface;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.72 : 0.35);
    }

    final borderColor = isSelected
        ? AppTheme.primary
        : isToday
            ? AppTheme.primary.withValues(alpha: 0.35)
            : theme.colorScheme.outline.withValues(alpha: 0.72);

    return LayoutBuilder(
      builder: (context, constraints) {
        final dayBubbleSize = (constraints.maxWidth * 0.70).clamp(20.0, 30.0);
        final dayFontSize = (dayBubbleSize * 0.44).clamp(11.0, 15.0);
        final dotSize = (constraints.maxWidth * 0.16).clamp(4.0, 8.0);
        final dotSpacing = (constraints.maxWidth * 0.08).clamp(3.0, 6.0);
        final verticalPadding = (constraints.maxHeight * 0.08).clamp(3.0, 7.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: borderColor, width: isSelected ? 1.4 : 1),
                boxShadow: hasAnyData
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.25
                                : 0.035,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: verticalPadding,
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: dayBubbleSize,
                      height: dayBubbleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasAnyData
                            ? Color.lerp(
                                theme.colorScheme.surface,
                                AppTheme.primary.withValues(alpha: 0.18),
                                combinedProgress.toDouble(),
                              )
                            : Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        textScaler: TextScaler.noScaling,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: dayFontSize,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: hasAnyData
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasNutrition)
                                _DaySignalDot(
                                  color: AppTheme.caloriesColor,
                                  strength:
                                      summary!.calorieProgress.clamp(0.18, 1.0),
                                  size: dotSize,
                                ),
                              if (hasNutrition && hasActivity)
                                SizedBox(width: dotSpacing),
                              if (hasActivity)
                                _DaySignalDot(
                                  color: AppTheme.accentSage,
                                  strength:
                                      summary!.stepsProgress.clamp(0.18, 1.0),
                                  size: dotSize,
                                ),
                            ],
                          )
                        : Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  theme.colorScheme.outline.withValues(alpha: 0.55),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DaySignalDot extends StatelessWidget {
  const _DaySignalDot({
    required this.color,
    required this.strength,
    required this.size,
  });

  final Color color;
  final double strength;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: strength),
      ),
    );
  }
}
