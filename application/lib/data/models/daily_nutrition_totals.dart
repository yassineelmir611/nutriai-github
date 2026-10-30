class DailyNutritionTotals {
  final double calories;
  final double protein;
  final double fat;

  const DailyNutritionTotals({
    required this.calories,
    required this.protein,
    required this.fat,
  });

  static const zero = DailyNutritionTotals(calories: 0, protein: 0, fat: 0);
}
