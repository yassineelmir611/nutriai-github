import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../data/services/step_counter_service.dart';
import 'core_providers.dart';

enum StepTrackingStatus {
  loading,
  active,
  permissionDenied,
  unsupported,
  error,
}

class StepsState {
  const StepsState({
    required this.todaySteps,
    required this.goal,
    required this.status,
    this.message,
  });

  factory StepsState.initial() => const StepsState(
        todaySteps: 0,
        goal: AppConstants.dailyStepsGoal,
        status: StepTrackingStatus.loading,
        message: 'Starting step tracking...',
      );

  final int todaySteps;
  final int goal;
  final StepTrackingStatus status;
  final String? message;

  double get progress {
    if (goal <= 0) return 0;
    return (todaySteps / goal).clamp(0.0, 1.0).toDouble();
  }

  StepsState copyWith({
    int? todaySteps,
    int? goal,
    StepTrackingStatus? status,
    String? message,
  }) {
    return StepsState(
      todaySteps: todaySteps ?? this.todaySteps,
      goal: goal ?? this.goal,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class StepsNotifier extends StateNotifier<StepsState> {
  StepsNotifier(this._ref, this._stepCounterService)
      : super(StepsState.initial()) {
    _initialize();
  }

  final Ref _ref;
  final StepCounterService _stepCounterService;

  StreamSubscription<int>? _subscription;
  int _lastSavedSteps = -1;
  bool _isInitializing = false;

  String get _todayKey => AppDateUtils.groupKey(DateTime.now());

  Future<void> _initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    final repository = _ref.read(localRepositoryProvider);
    final cached = repository.getDailyStepCount(_todayKey);
    final profile = repository.getProfile();
    final stepsGoal = profile?.dailyStepsGoal ?? AppConstants.dailyStepsGoal;
    state = state.copyWith(
      todaySteps: cached,
      goal: stepsGoal,
      status: StepTrackingStatus.loading,
      message: 'Checking permissions...',
    );

    final permission = await _stepCounterService.requestPermission();
    switch (permission) {
      case StepPermissionStatus.granted:
        _startStepTracking();
        break;
      case StepPermissionStatus.denied:
      case StepPermissionStatus.permanentlyDenied:
        state = state.copyWith(
          status: StepTrackingStatus.permissionDenied,
          message: 'Step permission is needed to track your daily steps.',
        );
        break;
      case StepPermissionStatus.unsupported:
        state = state.copyWith(
          status: StepTrackingStatus.unsupported,
          message: 'Step tracking is not available on this device.',
        );
        break;
    }

    _isInitializing = false;
  }

  void _startStepTracking() {
    _subscription?.cancel();
    _subscription = _stepCounterService.stepCountStream().listen(
      _handleRawStepCount,
      onError: (Object error, StackTrace stackTrace) {
        state = state.copyWith(
          status: StepTrackingStatus.error,
          message: 'Unable to read steps right now. Please try again.',
        );
      },
    );

    state = state.copyWith(
      status: StepTrackingStatus.active,
      message: 'Live step tracking enabled.',
    );
  }

  void _handleRawStepCount(int rawSteps) {
    final repository = _ref.read(localRepositoryProvider);
    final dateKey = _todayKey;

    // Sensor values are cumulative since device boot.
    // We store a day baseline and compute today's steps from that baseline.
    var baseline = repository.getDailyStepBaseline(dateKey);
    if (baseline == null || rawSteps < baseline) {
      baseline = rawSteps;
      unawaited(repository.saveDailyStepBaseline(dateKey, baseline));
    }

    final todaySteps = (rawSteps - baseline).clamp(0, 500000);
    if (todaySteps != state.todaySteps) {
      state = state.copyWith(
          todaySteps: todaySteps,
          status: StepTrackingStatus.active,
          message: 'Live step tracking enabled.');
    }

    final needsPersist = _lastSavedSteps == -1 ||
        (todaySteps - _lastSavedSteps).abs() >= 5 ||
        todaySteps < _lastSavedSteps;
    if (needsPersist) {
      _lastSavedSteps = todaySteps;
      unawaited(repository.saveDailyStepCount(dateKey, todaySteps));
    }
  }

  Future<void> retry() async {
    await _initialize();
  }

  void syncGoalFromProfile() {
    final stepsGoal =
        _ref.read(localRepositoryProvider).getProfile()?.dailyStepsGoal ??
            AppConstants.dailyStepsGoal;
    if (stepsGoal != state.goal) {
      state = state.copyWith(goal: stepsGoal);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final stepsProvider = StateNotifierProvider<StepsNotifier, StepsState>(
  (ref) => StepsNotifier(ref, ref.read(stepCounterServiceProvider)),
);
