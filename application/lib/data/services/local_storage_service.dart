import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/meal_entry.dart';
import '../models/user_profile.dart';

class LocalStorageService {
  static late Box _profileBox;
  static late Box _mealsBox;
  static late Box _chatBox;
  static late Box _appBox;

  static Future<void> init() async {
    _profileBox = await Hive.openBox(AppConstants.profileBox);
    _mealsBox = await Hive.openBox(AppConstants.mealsBox);
    _chatBox = await Hive.openBox(AppConstants.chatBox);
    _appBox = await Hive.openBox(AppConstants.appBox);
  }

  static Future<void> saveProfile(UserProfile profile) async {
    await _profileBox.put('profile', jsonEncode(profile.toJson()));
    await _appBox.put('onboarding_done', true);
  }

  static UserProfile? getProfile() {
    final raw = _profileBox.get('profile');
    if (raw == null) return null;
    return UserProfile.fromJson(
        (jsonDecode(raw as String) as Map).cast<String, dynamic>());
  }

  static bool isOnboardingDone() {
    return _appBox.get('onboarding_done', defaultValue: false) as bool;
  }

  static Future<void> saveMeals(List<MealEntry> meals) async {
    final payload = meals.map((m) => m.toJson()).toList();
    await _mealsBox.put('all', jsonEncode(payload));
  }

  static List<MealEntry> getMeals() {
    final raw = _mealsBox.get('all');
    if (raw == null) return [];
    final data = (jsonDecode(raw as String) as List)
        .map((e) => MealEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return data;
  }

  static Future<void> saveChatMessages(List<ChatMessage> messages) async {
    final payload = messages.map((m) => m.toJson()).toList();
    await _chatBox.put('messages', jsonEncode(payload));
  }

  static Future<void> clearChatMessages() async {
    await _chatBox.delete('messages');
  }

  static List<ChatMessage> getChatMessages() {
    final raw = _chatBox.get('messages');
    if (raw == null) return [];
    return (jsonDecode(raw as String) as List)
        .map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static int getDailyStepCount(String dateKey) {
    return (_appBox.get('steps_count_$dateKey', defaultValue: 0) as num)
        .toInt();
  }

  static Map<String, int> getAllDailyStepCounts() {
    final result = <String, int>{};

    for (final key in _appBox.keys) {
      final rawKey = key.toString();
      if (!rawKey.startsWith('steps_count_')) continue;

      final dateKey = rawKey.substring('steps_count_'.length);
      final value = (_appBox.get(rawKey, defaultValue: 0) as num).toInt();
      result[dateKey] = value;
    }

    return result;
  }

  static Future<void> saveDailyStepCount(String dateKey, int steps) async {
    await _appBox.put('steps_count_$dateKey', steps);
  }

  static int? getDailyStepBaseline(String dateKey) {
    final raw = _appBox.get('steps_baseline_$dateKey');
    if (raw == null) return null;
    return (raw as num).toInt();
  }

  static Future<void> saveDailyStepBaseline(
      String dateKey, int baseline) async {
    await _appBox.put('steps_baseline_$dateKey', baseline);
  }

  static String getThemeModePreference() {
    final raw = _appBox.get('theme_mode', defaultValue: 'light');
    if (raw is String && raw.isNotEmpty) {
      return raw;
    }
    return 'light';
  }

  static Future<void> saveThemeModePreference(String value) async {
    await _appBox.put('theme_mode', value);
  }
}
