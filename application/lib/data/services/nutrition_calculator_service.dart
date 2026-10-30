class NutritionCalculatorService {
  // Reasonable defaults when age/sex/activity are not explicitly collected yet.
  // We use an adapted Mifflin-St Jeor baseline for a 30-year profile and moderate activity.
  double calculateDailyCalories(
      {required double weight, required double height}) {
    final bmrEstimate = (10 * weight) + (6.25 * height) - (5 * 30) + 5;
    final maintenanceEstimate = bmrEstimate * 1.4;
    return maintenanceEstimate.clamp(1200, 4200).toDouble();
  }

  // Evidence-based default target for active adults:
  // 1.6 g/kg body weight/day.
  double calculateDailyProtein({required double weight}) {
    return (weight * 1.6).clamp(45, 260).toDouble();
  }

  // Moderate fat target using 0.9 g/kg with practical bounds.
  double calculateDailyFat({required double weight}) {
    return (weight * 0.9).clamp(35, 140).toDouble();
  }
}
