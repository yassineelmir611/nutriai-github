import '../models/chat_message.dart';
import '../models/meal_entry.dart';
import '../models/user_profile.dart';
import '../services/local_storage_service.dart';
import 'local_repository.dart';

class LocalRepositoryImpl implements LocalRepository {
  @override
  UserProfile? getProfile() => LocalStorageService.getProfile();

  @override
  List<MealEntry> getMeals() => LocalStorageService.getMeals();

  @override
  int? getDailyStepBaseline(String dateKey) =>
      LocalStorageService.getDailyStepBaseline(dateKey);

  @override
  int getDailyStepCount(String dateKey) =>
      LocalStorageService.getDailyStepCount(dateKey);

  @override
  Map<String, int> getAllDailyStepCounts() =>
      LocalStorageService.getAllDailyStepCounts();

  @override
  String getThemeModePreference() =>
      LocalStorageService.getThemeModePreference();

  @override
  List<ChatMessage> getChatMessages() => LocalStorageService.getChatMessages();

  @override
  bool isOnboardingDone() => LocalStorageService.isOnboardingDone();

  @override
  Future<void> saveChatMessages(List<ChatMessage> messages) =>
      LocalStorageService.saveChatMessages(messages);

  @override
  Future<void> clearChatMessages() => LocalStorageService.clearChatMessages();

  @override
  Future<void> saveMeals(List<MealEntry> meals) =>
      LocalStorageService.saveMeals(meals);

  @override
  Future<void> saveProfile(UserProfile profile) =>
      LocalStorageService.saveProfile(profile);

  @override
  Future<void> saveThemeModePreference(String value) =>
      LocalStorageService.saveThemeModePreference(value);

  @override
  Future<void> saveDailyStepBaseline(String dateKey, int baseline) {
    return LocalStorageService.saveDailyStepBaseline(dateKey, baseline);
  }

  @override
  Future<void> saveDailyStepCount(String dateKey, int steps) {
    return LocalStorageService.saveDailyStepCount(dateKey, steps);
  }
}
