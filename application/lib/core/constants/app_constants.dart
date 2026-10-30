class AppConstants {
  static const String appName = 'NutriAI';

  // Compile-time configuration. BASE_URL is a host without a port.
  // FOOD_API_URL and CHAT_API_URL accept complete URLs without a trailing slash.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://127.0.0.1',
  );
  static const bool useMockApi = bool.fromEnvironment('USE_MOCK_API');

  static const String foodServerBaseUrl = String.fromEnvironment(
    'FOOD_API_URL',
    defaultValue: '$baseUrl:8000',
  );
  static const String chatServerBaseUrl = String.fromEnvironment(
    'CHAT_API_URL',
    defaultValue: '$baseUrl:8001',
  );

  static const String analyzeFoodEndpoint = '$foodServerBaseUrl/analyze-food';
  static const String nutritionChatEndpoint =
      '$chatServerBaseUrl/nutrition-chat';
  static const int dailyStepsGoal = 8000;

  static const String profileBox = 'profile_box';
  static const String mealsBox = 'meals_box';
  static const String chatBox = 'chat_box';
  static const String appBox = 'app_box';
}
