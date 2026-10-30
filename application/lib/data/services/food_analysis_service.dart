import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../models/food_analysis_result.dart';
import 'api_client.dart';
import 'mock/mock_backend.dart';

class FoodAnalysisService {
  FoodAnalysisService(this._apiClient);

  final ApiClient _apiClient;

  Future<FoodAnalysisResult> analyzeFood(File imageFile) async {
    if (AppConstants.useMockApi) {
      final json = await MockBackend.analyzeFoodMock();
      return FoodAnalysisResult.fromJson(json);
    }

    final filename = imageFile.uri.pathSegments.isEmpty
        ? 'meal.jpg'
        : imageFile.uri.pathSegments.last;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: filename,
      ),
    });

    final response = await _apiClient.dio.post(
      AppConstants.analyzeFoodEndpoint,
      data: formData,
    );
    return FoodAnalysisResult.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }
}
