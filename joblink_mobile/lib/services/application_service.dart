import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/application.dart';

class ApplicationService {
  final Dio _dio = ApiClient.dio;

  Future<List<JobApplication>> getMyApplications() async {
    final response = await _dio.get(
      '/applications/me',
    );

    final list = _extractList(
      response.data,
    );

    return list
        .whereType<Map>()
        .map(
          (item) => JobApplication.fromJson(
        Map<String, dynamic>.from(
          item,
        ),
      ),
    )
        .where(
          (application) =>
      application.id.isNotEmpty,
    )
        .toList();
  }

  Future<Map<String, dynamic>> getMyApplicationById(
      String applicationId,
      ) async {
    final response = await _dio.get(
      '/applications/me/$applicationId',
    );

    final data = response.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(
        data,
      );

      // Hỗ trợ cả response trực tiếp và response bọc trong "data".
      final nested = map['data'];

      if (nested is Map) {
        return Map<String, dynamic>.from(
          nested,
        );
      }

      return map;
    }

    throw StateError(
      'Dữ liệu chi tiết đơn ứng tuyển không hợp lệ',
    );
  }

  Future<Map<String, dynamic>> withdrawApplication(String applicationId) async {
    final response = await _dio.patch(
      '/applications/me/$applicationId/withdraw',
    );

    final data = response.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data']);
      }
      return map;
    }

    throw StateError('Dữ liệu không hợp lệ');
  }

  String resolveFileUrl(String fileUrl) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    var baseUrl = _dio.options.baseUrl;
    baseUrl = baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    final cleanPath = fileUrl.startsWith('/') ? fileUrl.substring(1) : fileUrl;
    return '$baseUrl/$cleanPath';
  }

  List<dynamic> _extractList(
      dynamic data,
      ) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      for (final key in [
        'items',
        'data',
        'applications',
        'results',
      ]) {
        final value = data[key];

        if (value is List) {
          return value;
        }

        if (value is Map) {
          for (final nestedKey in [
            'items',
            'applications',
            'data',
            'results',
          ]) {
            final nested =
            value[nestedKey];

            if (nested is List) {
              return nested;
            }
          }
        }
      }
    }

    return [];
  }
}
