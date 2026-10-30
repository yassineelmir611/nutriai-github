import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../data/models/user_profile.dart';
import 'core_providers.dart';

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  final Ref _ref;

  Future<void> loadProfile() async {
    try {
      final profile = _ref.read(localRepositoryProvider).getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createProfile({
    required String name,
    required double height,
    required double weight,
    double? dailyCaloriesGoal,
    double? dailyProteinGoal,
    double? dailyFatGoal,
    int? dailyStepsGoal,
  }) async {
    final calc = _ref.read(nutritionCalculatorProvider);
    final calories = dailyCaloriesGoal ??
        calc.calculateDailyCalories(weight: weight, height: height);
    final protein =
        dailyProteinGoal ?? calc.calculateDailyProtein(weight: weight);
    final fat = dailyFatGoal ?? calc.calculateDailyFat(weight: weight);

    final profile = UserProfile(
      id: const Uuid().v4(),
      name: name,
      height: height,
      weight: weight,
      profileImagePath: null,
      dailyCaloriesGoal: calories,
      dailyProteinGoal: protein,
      dailyFatGoal: fat,
      dailyStepsGoal: dailyStepsGoal ?? AppConstants.dailyStepsGoal,
      createdAt: DateTime.now(),
    );
    await _ref.read(localRepositoryProvider).saveProfile(profile);
    state = AsyncValue.data(profile);
  }

  Future<void> updateProfile(UserProfile updated) async {
    await _ref.read(localRepositoryProvider).saveProfile(updated);
    state = AsyncValue.data(updated);
  }

  bool get isOnboardingDone =>
      _ref.read(localRepositoryProvider).isOnboardingDone();
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>(
  (ref) => ProfileNotifier(ref),
);

final onboardingDoneProvider = Provider<bool>((ref) {
  return ref.read(localRepositoryProvider).isOnboardingDone();
});
