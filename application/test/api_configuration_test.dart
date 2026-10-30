import 'package:flutter_test/flutter_test.dart';
import 'package:nutriai/core/constants/app_constants.dart';

void main() {
  test('each endpoint uses its configured service URL', () {
    const configuration = String.fromEnvironment(
      'TEST_CONFIGURATION',
      defaultValue: 'local',
    );
    final (food, chat, mock) = switch (configuration) {
      'separate' => (
        'https://food.example.test/analyze-food',
        'https://chat.example.test/nutrition-chat',
        true,
      ),
      'emulator' => (
        'http://10.0.2.2:8000/analyze-food',
        'http://10.0.2.2:8001/nutrition-chat',
        false,
      ),
      _ => (
        'http://127.0.0.1:8000/analyze-food',
        'http://127.0.0.1:8001/nutrition-chat',
        false,
      ),
    };
    expect(AppConstants.analyzeFoodEndpoint, food);
    expect(AppConstants.nutritionChatEndpoint, chat);
    expect(AppConstants.useMockApi, mock);
  });
}
