import '../../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/daily_nutrition_totals.dart';
import '../models/user_profile.dart';
import 'api_client.dart';
import 'mock/mock_backend.dart';

class ChatbotService {
  ChatbotService(this._apiClient);

  final ApiClient _apiClient;

  Future<String> sendMessage({
    required UserProfile profile,
    required List<ChatMessage> history,
    required String newMessage,
    required DailyNutritionTotals today,
    required List<String> foods,
    required List<String> mealSummaries,
  }) async {
    final payload = {
      'name': profile.name,
      'msg_history': history
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList(),
      'foods': foods,
      'meal_summaries': mealSummaries,
      'new_msg': newMessage,
      'Nutritional goals': {
        'Calories': profile.dailyCaloriesGoal,
        'Protein': profile.dailyProteinGoal,
        'Fat': profile.dailyFatGoal,
      },
      'Current_consumption': {
        'Calories': today.calories,
        'Protein': today.protein,
        'Fat': today.fat,
      }
    };

    if (AppConstants.useMockApi) {
      final result = await MockBackend.chatMock(payload);
      return result['response'] as String;
    }

    final response = await _apiClient.dio
        .post(AppConstants.nutritionChatEndpoint, data: payload);
    return (response.data as Map<String, dynamic>)['response'] as String;
  }
}
