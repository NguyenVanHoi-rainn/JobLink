import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/auth_user.dart';

class AuthService {
  final Dio _dio =
      ApiClient.dio;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response =
    await _dio.post(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data =
    Map<String, dynamic>.from(
      response.data,
    );

    final token =
    data['accessToken']?.toString();

    if (
    token == null ||
        token.isEmpty) {
      throw Exception(
        'Backend không trả accessToken',
      );
    }

    await TokenStorage.saveToken(
      token,
    );

    return getMe();
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) async {
    await _dio.post(
      '/auth/register',
      data: {
        'email': email.trim(),
        'password': password,
        'role': role,
      },
    );
  }

  Future<AuthUser> getMe() async {
    final response =
    await _dio.get(
      '/auth/me',
    );

    return AuthUser.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  Future<bool> hasToken() async {
    final token =
    await TokenStorage.getToken();

    return token != null &&
        token.isNotEmpty;
  }

  Future<void> logout() async {
    await TokenStorage.deleteToken();
  }
}