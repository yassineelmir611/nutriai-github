import 'dart:math';

class MockBackend {
  static Future<Map<String, dynamic>> analyzeFoodMock() async {
    await Future.delayed(const Duration(seconds: 2));

    final samples = <Map<String, dynamic>>[
      {
        'name': 'Pizza',
        'calorie': 266,
        'protein': 11,
        'fat': 10,
        'carbs': 33,
        'fiber': 2.3,
        'sugar': 3.8,
        'sodium': 598,
        'vitamins': {
          'vitaminA': 0.12,
          'vitaminC': 0.0,
          'vitaminD': 0.05,
          'vitaminB12': 0.20
        }
      },
      {
        'name': 'Grilled Chicken',
        'calorie': 165,
        'protein': 31,
        'fat': 3.6,
        'carbs': 0,
        'fiber': 0,
        'sugar': 0,
        'sodium': 74,
        'vitamins': {
          'vitaminA': 0.02,
          'vitaminC': 0.0,
          'vitaminD': 0.01,
          'vitaminB12': 0.33
        }
      },
      {
        'name': 'Avocado Toast',
        'calorie': 210,
        'protein': 6,
        'fat': 12,
        'carbs': 22,
        'fiber': 7,
        'sugar': 1.4,
        'sodium': 280,
        'vitamins': {
          'vitaminA': 0.06,
          'vitaminC': 0.09,
          'vitaminD': 0.00,
          'vitaminB12': 0.0
        }
      }
    ];

    return samples[Random().nextInt(samples.length)];
  }

  static Future<Map<String, dynamic>> chatMock(
      Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 1400));

    final goals =
        (payload['nutritional_goals'] as Map?)?.cast<String, dynamic>() ?? {};
    final current =
        (payload['current_consumption'] as Map?)?.cast<String, dynamic>() ?? {};

    final pLeft = ((goals['protein'] ?? 0) as num).toDouble() -
        ((current['protein'] ?? 0) as num).toDouble();
    final cLeft = ((goals['calories'] ?? 0) as num).toDouble() -
        ((current['calories'] ?? 0) as num).toDouble();
    final fLeft = ((goals['fat'] ?? 0) as num).toDouble() -
        ((current['fat'] ?? 0) as num).toDouble();

    final response =
        'You are doing well. Remaining today: ${cLeft.toStringAsFixed(0)} kcal, ${pLeft.toStringAsFixed(1)}g protein, ${fLeft.toStringAsFixed(1)}g fat. Focus on lean protein + veggies for your next meal.';

    return {'response': response};
  }
}
