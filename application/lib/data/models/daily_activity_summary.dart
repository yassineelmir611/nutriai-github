import '../../core/utils/date_utils.dart';
import 'daily_nutrition_totals.dart';
import 'meal_entry.dart';

class DailyActivitySummary {
  const DailyActivitySummary({
    required this.date,
    required this.meals,
    required this.totals,
    required this.goals,
    required this.steps,
    required this.stepsGoal,
  });

  factory DailyActivitySummary.empty({
    required DateTime date,
    required DailyNutritionTotals goals,
    required int stepsGoal,
  }) {
    return DailyActivitySummary(
      date: AppDateUtils.startOfDay(date),
      meals: const [],
      totals: DailyNutritionTotals.zero,
      goals: goals,
      steps: 0,
      stepsGoal: stepsGoal,
    );
  }

  final DateTime date;
  final List<MealEntry> meals;
  final DailyNutritionTotals totals;
  final DailyNutritionTotals goals;
  final int steps;
  final int stepsGoal;

  String get dateKey => AppDateUtils.groupKey(date);
  int get mealCount => meals.length;
  bool get hasNutrition => totals.calories > 0;
  bool get hasActivity => steps > 0;
  bool get hasAnyData => hasNutrition || hasActivity || meals.isNotEmpty;

  double get calorieProgress => _progress(totals.calories, goals.calories);
  double get proteinProgress => _progress(totals.protein, goals.protein);
  double get fatProgress => _progress(totals.fat, goals.fat);
  double get stepsProgress => _progress(steps.toDouble(), stepsGoal.toDouble());

  double get combinedProgress =>
      ((calorieProgress.clamp(0, 1) + stepsProgress.clamp(0, 1)) / 2)
          .toDouble();

  double _progress(double value, double goal) {
    if (goal <= 0) return 0;
    return value / goal;
  }
}
