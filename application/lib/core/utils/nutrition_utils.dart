import '../../data/models/food_analysis_result.dart';

class NutritionUtils {
  static double calculateValuePerGrams(double per100gValue, double grams) {
    return (per100gValue * grams) / 100;
  }

  static FoodAnalysisResult scaleResult(
      FoodAnalysisResult per100g, double grams) {
    return per100g.copyWith(
      calories: calculateValuePerGrams(per100g.calories, grams),
      protein: calculateValuePerGrams(per100g.protein, grams),
      fat: calculateValuePerGrams(per100g.fat, grams),
      carbs: calculateValuePerGrams(per100g.carbs, grams),
      fiber: calculateValuePerGrams(per100g.fiber, grams),
      sugar: calculateValuePerGrams(per100g.sugar, grams),
      sodium: calculateValuePerGrams(per100g.sodium, grams),
      vitamins: per100g.vitamins.scale(grams / 100),
    );
  }

  static double safeProgress(double current, double goal) {
    if (goal <= 0) return 0;
    return (current / goal).clamp(0, 1);
  }
}
