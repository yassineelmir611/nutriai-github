import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../data/models/daily_activity_summary.dart';
import '../data/models/daily_nutrition_totals.dart';
import '../data/models/meal_entry.dart';
import 'core_providers.dart';
import 'meals_provider.dart';
import 'profile_provider.dart';
import 'steps_provider.dart';

final dailyActivityMapProvider =
    Provider<Map<String, DailyActivitySummary>>((ref) {
  final meals = ref.watch(mealsProvider);
  final profile = ref.watch(profileProvider).value;
  ref.watch(stepsProvider);

  final stepsByDate = ref.read(localRepositoryProvider).getAllDailyStepCounts();
  final mealsByDate = <String, List<MealEntry>>{};

  for (final meal in meals) {
    final key = AppDateUtils.groupKey(meal.dateTime);
    mealsByDate.putIfAbsent(key, () => []);
    mealsByDate[key]!.add(meal);
  }

  final goalTotals = DailyNutritionTotals(
    calories: profile?.dailyCaloriesGoal ?? 0,
    protein: profile?.dailyProteinGoal ?? 0,
    fat: profile?.dailyFatGoal ?? 0,
  );
  final stepsGoal = profile?.dailyStepsGoal ?? AppConstants.dailyStepsGoal;

  final allKeys = <String>{
    ...mealsByDate.keys,
    ...stepsByDate.keys,
    AppDateUtils.groupKey(DateTime.now()),
  };

  final result = <String, DailyActivitySummary>{};
  for (final key in allKeys) {
    final dayMeals = [...(mealsByDate[key] ?? const <MealEntry>[])];
    dayMeals.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    double calories = 0;
    double protein = 0;
    double fat = 0;
    for (final meal in dayMeals) {
      calories += meal.calories;
      protein += meal.protein;
      fat += meal.fat;
    }

    result[key] = DailyActivitySummary(
      date: AppDateUtils.dateFromKey(key),
      meals: dayMeals,
      totals: DailyNutritionTotals(
        calories: calories,
        protein: protein,
        fat: fat,
      ),
      goals: goalTotals,
      steps: stepsByDate[key] ?? 0,
      stepsGoal: stepsGoal,
    );
  }

  return result;
});

final weeklyActivityTrendProvider = Provider<List<DailyActivitySummary>>((ref) {
  final summaries = ref.watch(dailyActivityMapProvider);
  final profile = ref.watch(profileProvider).value;
  final goalTotals = DailyNutritionTotals(
    calories: profile?.dailyCaloriesGoal ?? 0,
    protein: profile?.dailyProteinGoal ?? 0,
    fat: profile?.dailyFatGoal ?? 0,
  );
  final stepsGoal = profile?.dailyStepsGoal ?? AppConstants.dailyStepsGoal;
  final today = AppDateUtils.startOfDay(DateTime.now());

  return List.generate(7, (index) {
    final date = today.subtract(Duration(days: 6 - index));
    final key = AppDateUtils.groupKey(date);
    return summaries[key] ??
        DailyActivitySummary.empty(
          date: date,
          goals: goalTotals,
          stepsGoal: stepsGoal,
        );
  });
});
