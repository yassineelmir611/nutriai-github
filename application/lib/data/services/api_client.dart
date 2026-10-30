import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';

class ApiClient {
  final Dio dio;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.foodServerBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final responseData = error.response?.data;
          if (responseData is Map && responseData['detail'] != null) {
            handler.reject(
              error.copyWith(
                message: responseData['detail'].toString(),
              ),
            );
            return;
          }

          handler.next(error);
        },
      ),
    );
  }
}
