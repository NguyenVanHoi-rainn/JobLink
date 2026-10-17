import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(
        seconds: 15,
      ),
      receiveTimeout: const Duration(
        seconds: 15,
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static void initialize() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
            options,
            handler,
            ) async {
          final token =
          await TokenStorage.getToken();

          if (
          token != null &&
              token.isNotEmpty) {
            options.headers['Authorization'] =
            'Bearer $token';
          }

          handler.next(options);
        },
        onError: (
            error,
            handler,
            ) async {
          if (
          error.response?.statusCode ==
              401) {
            await TokenStorage.deleteToken();
          }

          handler.next(error);
        },
      ),
    );
  }
}