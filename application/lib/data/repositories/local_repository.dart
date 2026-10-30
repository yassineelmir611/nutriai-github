import '../models/chat_message.dart';
import '../models/meal_entry.dart';
import '../models/user_profile.dart';

abstract class LocalRepository {
  UserProfile? getProfile();
  Future<void> saveProfile(UserProfile profile);

  List<MealEntry> getMeals();
  Future<void> saveMeals(List<MealEntry> meals);

  List<ChatMessage> getChatMessages();
  Future<void> saveChatMessages(List<ChatMessage> messages);
  Future<void> clearChatMessages();

  bool isOnboardingDone();

  int getDailyStepCount(String dateKey);
  Map<String, int> getAllDailyStepCounts();
  Future<void> saveDailyStepCount(String dateKey, int steps);

  int? getDailyStepBaseline(String dateKey);
  Future<void> saveDailyStepBaseline(String dateKey, int baseline);

  String getThemeModePreference();
  Future<void> saveThemeModePreference(String value);
}
