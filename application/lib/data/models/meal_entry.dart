import 'food_analysis_result.dart';
import 'vitamins.dart';

class MealEntry {
  final String id;
  final DateTime dateTime;
  final String? imagePath;
  final String foodName;
  final double gramsConsumed;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double sodium;
  final Vitamins vitamins;

  const MealEntry({
    required this.id,
    required this.dateTime,
    this.imagePath,
    required this.foodName,
    required this.gramsConsumed,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.vitamins,
  });

  factory MealEntry.fromAnalysis({
    required String id,
    required DateTime dateTime,
    required String? imagePath,
    required String foodName,
    required double grams,
    required FoodAnalysisResult consumedValues,
  }) {
    return MealEntry(
      id: id,
      dateTime: dateTime,
      imagePath: imagePath,
      foodName: foodName,
      gramsConsumed: grams,
      calories: consumedValues.calories,
      protein: consumedValues.protein,
      fat: consumedValues.fat,
      carbs: consumedValues.carbs,
      fiber: consumedValues.fiber,
      sugar: consumedValues.sugar,
      sodium: consumedValues.sodium,
      vitamins: consumedValues.vitamins,
    );
  }

  MealEntry copyWith({
    String? id,
    DateTime? dateTime,
    String? imagePath,
    String? foodName,
    double? gramsConsumed,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? fiber,
    double? sugar,
    double? sodium,
    Vitamins? vitamins,
  }) {
    return MealEntry(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      imagePath: imagePath ?? this.imagePath,
      foodName: foodName ?? this.foodName,
      gramsConsumed: gramsConsumed ?? this.gramsConsumed,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      vitamins: vitamins ?? this.vitamins,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'imagePath': imagePath,
        'foodName': foodName,
        'gramsConsumed': gramsConsumed,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'vitamins': vitamins.toJson(),
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        id: json['id'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        imagePath: json['imagePath'] as String?,
        foodName: json['foodName'] as String,
        gramsConsumed: (json['gramsConsumed'] as num).toDouble(),
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fiber: (json['fiber'] as num).toDouble(),
        sugar: (json['sugar'] as num).toDouble(),
        sodium: (json['sodium'] as num).toDouble(),
        vitamins: Vitamins.fromJson(
            (json['vitamins'] as Map).cast<String, dynamic>()),
      );
}
