import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/nutrition_utils.dart';
import '../data/models/food_analysis_result.dart';
import 'core_providers.dart';

class AnalysisState {
  final File? imageFile;
  final FoodAnalysisResult? per100gResult;
  final bool isLoading;
  final String? error;

  const AnalysisState({
    this.imageFile,
    this.per100gResult,
    this.isLoading = false,
    this.error,
  });

  AnalysisState copyWith({
    File? imageFile,
    FoodAnalysisResult? per100gResult,
    bool? isLoading,
    String? error,
  }) {
    return AnalysisState(
      imageFile: imageFile ?? this.imageFile,
      per100gResult: per100gResult ?? this.per100gResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  AnalysisNotifier(this._ref) : super(const AnalysisState());

  final Ref _ref;

  void setImage(File file) {
    state = state.copyWith(imageFile: file, error: null);
  }

  void clear() {
    state = const AnalysisState();
  }

  Future<void> analyze() async {
    final file = state.imageFile;
    if (file == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result =
          await _ref.read(foodAnalysisServiceProvider).analyzeFood(file);
      state = state.copyWith(isLoading: false, per100gResult: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  FoodAnalysisResult? forGrams(double grams) {
    final base = state.per100gResult;
    if (base == null) return null;
    return NutritionUtils.scaleResult(base, grams);
  }
}

final analysisProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier(ref);
});
