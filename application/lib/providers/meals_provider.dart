import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/daily_nutrition_totals.dart';
import '../data/models/meal_entry.dart';
import '../data/models/user_profile.dart';
import '../providers/profile_provider.dart';
import 'core_providers.dart';

class MealsNotifier extends StateNotifier<List<MealEntry>> {
  MealsNotifier(this._ref) : super([]) {
    loadMeals();
  }

  final Ref _ref;

  void loadMeals() {
    final meals = _ref.read(localRepositoryProvider).getMeals();
    meals.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    state = meals;
  }

  Future<void> addMeal(MealEntry meal) async {
    final next = [meal, ...state]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    state = next;
    await _ref.read(localRepositoryProvider).saveMeals(next);
  }

  Future<void> deleteMeal(String id) async {
    final next = state.where((m) => m.id != id).toList();
    state = next;
    await _ref.read(localRepositoryProvider).saveMeals(next);
  }

  Future<void> updateMeal(MealEntry updated) async {
    final next = state.map((m) => m.id == updated.id ? updated : m).toList();
    next.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    state = next;
    await _ref.read(localRepositoryProvider).saveMeals(next);
  }
}

final mealsProvider = StateNotifierProvider<MealsNotifier, List<MealEntry>>(
  (ref) => MealsNotifier(ref),
);

final todayMealsProvider = Provider<List<MealEntry>>((ref) {
  return ref
      .watch(mealsProvider)
      .where((m) => AppDateUtils.isToday(m.dateTime))
      .toList();
});

final dailyTotalsProvider = Provider<DailyNutritionTotals>((ref) {
  final meals = ref.watch(todayMealsProvider);
  double calories = 0;
  double protein = 0;
  double fat = 0;

  for (final meal in meals) {
    calories += meal.calories;
    protein += meal.protein;
    fat += meal.fat;
  }

  return DailyNutritionTotals(calories: calories, protein: protein, fat: fat);
});

final mealsByDateProvider = Provider<Map<String, List<MealEntry>>>((ref) {
  final meals = ref.watch(mealsProvider);
  final grouped = <String, List<MealEntry>>{};

  for (final meal in meals) {
    final key = AppDateUtils.groupKey(meal.dateTime);
    grouped.putIfAbsent(key, () => []);
    grouped[key]!.add(meal);
  }

  return grouped;
});

final remainingGoalsProvider = Provider<DailyNutritionTotals>((ref) {
  final totals = ref.watch(dailyTotalsProvider);
  final profile = ref.watch(profileProvider).value;
  if (profile == null) return DailyNutritionTotals.zero;

  return DailyNutritionTotals(
    calories:
        (profile.dailyCaloriesGoal - totals.calories).clamp(0, double.infinity),
    protein:
        (profile.dailyProteinGoal - totals.protein).clamp(0, double.infinity),
    fat: (profile.dailyFatGoal - totals.fat).clamp(0, double.infinity),
  );
});

final selectedMealProvider = Provider.family<MealEntry?, String>((ref, id) {
  final meals = ref.watch(mealsProvider);
  for (final meal in meals) {
    if (meal.id == id) return meal;
  }
  return null;
});

final profileValueProvider =
    Provider<UserProfile?>((ref) => ref.watch(profileProvider).value);
