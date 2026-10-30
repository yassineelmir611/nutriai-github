import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/local_repository.dart';
import '../data/repositories/local_repository_impl.dart';
import '../data/services/api_client.dart';
import '../data/services/chatbot_service.dart';
import '../data/services/food_analysis_service.dart';
import '../data/services/nutrition_calculator_service.dart';
import '../data/services/step_counter_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final nutritionCalculatorProvider =
    Provider<NutritionCalculatorService>((ref) => NutritionCalculatorService());
final stepCounterServiceProvider =
    Provider<StepCounterService>((ref) => StepCounterService());

final foodAnalysisServiceProvider = Provider<FoodAnalysisService>(
  (ref) => FoodAnalysisService(ref.read(apiClientProvider)),
);

final chatbotServiceProvider = Provider<ChatbotService>(
  (ref) => ChatbotService(ref.read(apiClientProvider)),
);

final localRepositoryProvider =
    Provider<LocalRepository>((ref) => LocalRepositoryImpl());
