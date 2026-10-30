import 'vitamins.dart';

class FoodPredictionCandidate {
  final String label;
  final String displayName;
  final double confidence;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double sodium;
  final Vitamins vitamins;

  const FoodPredictionCandidate({
    required this.label,
    required this.displayName,
    required this.confidence,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.vitamins,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'display_name': displayName,
        'confidence': confidence,
        'nutrition': {
          'calories': calories,
          'protein': protein,
          'fat': fat,
          'carbs': carbs,
          'fiber': fiber,
          'sugar': sugar,
          'sodium': sodium,
        },
        'vitamins': vitamins.toJson(),
      };

  factory FoodPredictionCandidate.fromJson(Map<String, dynamic> json) {
    final nutrition = (json['nutrition'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final vitaminsJson = (json['vitamins'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    double readNum(String key) {
      return (nutrition[key] as num?)?.toDouble() ??
          (json[key] as num?)?.toDouble() ??
          0;
    }

    return FoodPredictionCandidate(
      label: (json['label'] ?? '').toString(),
      displayName:
          (json['display_name'] ?? json['displayName'] ?? '').toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      calories: readNum('calories'),
      protein: readNum('protein'),
      fat: readNum('fat'),
      carbs: readNum('carbs'),
      fiber: readNum('fiber'),
      sugar: readNum('sugar'),
      sodium: readNum('sodium'),
      vitamins: Vitamins.fromJson(vitaminsJson),
    );
  }
}

class FoodAnalysisResult {
  final String name;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double sodium;
  final Vitamins vitamins;
  final double confidence;
  final String source;
  final String? rawLabel;
  final List<FoodPredictionCandidate> topPredictions;

  const FoodAnalysisResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.vitamins,
    this.confidence = 0,
    this.source = 'unknown',
    this.rawLabel,
    this.topPredictions = const [],
  });

  FoodAnalysisResult copyWith({
    String? name,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? fiber,
    double? sugar,
    double? sodium,
    Vitamins? vitamins,
    double? confidence,
    String? source,
    String? rawLabel,
    List<FoodPredictionCandidate>? topPredictions,
  }) {
    return FoodAnalysisResult(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      vitamins: vitamins ?? this.vitamins,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      rawLabel: rawLabel ?? this.rawLabel,
      topPredictions: topPredictions ?? this.topPredictions,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'calorie': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'vitamins': vitamins.toJson(),
        'confidence': confidence,
        'source': source,
        'raw_label': rawLabel,
        'top_predictions': topPredictions.map((item) => item.toJson()).toList(),
      };

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    final nutrition = (json['nutrition'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final vitaminsJson = (json['vitamins'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final topPredictionsJson = (json['top_predictions'] as List?)
            ?.whereType<Map>()
            .map((item) =>
                FoodPredictionCandidate.fromJson(item.cast<String, dynamic>()))
            .toList() ??
        const <FoodPredictionCandidate>[];

    double readNum(String key, {String? legacyKey}) {
      final value = nutrition[key] ??
          (legacyKey == null ? null : json[legacyKey]) ??
          json[key];
      return (value as num?)?.toDouble() ?? 0;
    }

    return FoodAnalysisResult(
      name: (json['food_name'] ?? json['name'] ?? 'Unknown Food') as String,
      calories: readNum('calories', legacyKey: 'calorie'),
      protein: readNum('protein'),
      fat: readNum('fat'),
      carbs: readNum('carbs'),
      fiber: readNum('fiber'),
      sugar: readNum('sugar'),
      sodium: readNum('sodium'),
      vitamins: Vitamins.fromJson(vitaminsJson),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      source: (json['source'] ?? 'unknown').toString(),
      rawLabel: json['raw_label'] as String?,
      topPredictions: topPredictionsJson,
    );
  }

  factory FoodAnalysisResult.fromCandidate(
    FoodPredictionCandidate candidate, {
    required List<FoodPredictionCandidate> topPredictions,
    String source = 'manual_selection',
  }) {
    return FoodAnalysisResult(
      name: candidate.displayName,
      calories: candidate.calories,
      protein: candidate.protein,
      fat: candidate.fat,
      carbs: candidate.carbs,
      fiber: candidate.fiber,
      sugar: candidate.sugar,
      sodium: candidate.sodium,
      vitamins: candidate.vitamins,
      confidence: candidate.confidence,
      source: source,
      rawLabel: candidate.label,
      topPredictions: topPredictions,
    );
  }
}
