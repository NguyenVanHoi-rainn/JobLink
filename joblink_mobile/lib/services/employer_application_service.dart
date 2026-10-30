import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

class EmployerApplicationService {
  final Dio _dio = ApiClient.dio;

  Future<List<Map<String, dynamic>>>
  getEmployerJobs() async {
    final response = await _dio.get(
      '/employer/jobs',
    );

    final data = response.data;

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(
          item,
        ),
      )
          .toList();
    }

    if (data is Map) {
      for (final key in [
        'items',
        'data',
        'jobs',
        'results',
      ]) {
        final value = data[key];

        if (value is List) {
          return value
              .whereType<Map>()
              .map(
                (item) =>
            Map<String, dynamic>.from(
              item,
            ),
          )
              .toList();
        }
      }
    }

    return [];
  }

  Future<List<Map<String, dynamic>>>
  getJobApplications(
      String jobId,
      ) async {
    final response = await _dio.get(
      '/employer/jobs/$jobId/applications',
    );

    final data = response.data;

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(
          item,
        ),
      )
          .toList();
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
          return value
              .whereType<Map>()
              .map(
                (item) =>
            Map<String, dynamic>.from(
              item,
            ),
          )
              .toList();
        }
      }
    }

    return [];
  }

  Future<Map<String, dynamic>>
  getApplication(
      String applicationId,
      ) async {
    final response = await _dio.get(
      '/employer/applications/$applicationId',
    );

    return _extractMap(
      response.data,
    );
  }

  Future<Map<String, dynamic>?>
  getCandidateMatch(
      String applicationId,
      ) async {
    try {
      final response = await _dio.get(
        '/employer/applications/$applicationId/match',
      );

      return _extractMap(
        response.data,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode ==
          404) {
        return null;
      }

      rethrow;
    }
  }

  Future<Map<String, dynamic>>
  updateStatus(
      String applicationId,
      String status,
      ) async {
    final response = await _dio.patch(
      '/employer/applications/$applicationId/status',
      data: {
        'status': status,
      },
    );

    return _extractMap(
      response.data,
    );
  }

  Future<Map<String, dynamic>>
  getCv(
      String applicationId,
      ) async {
    final response = await _dio.get(
      '/employer/applications/$applicationId/cv',
    );

    return _extractMap(
      response.data,
    );
  }

  String resolveBackendFileUrl(
      String fileUrl,
      ) {
    final trimmed =
    fileUrl.trim();

    if (trimmed.startsWith(
      'http://',
    ) ||
        trimmed.startsWith(
          'https://',
        )) {
      return trimmed;
    }

    var baseUrl =
    _dio.options.baseUrl.trim();

    while (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(
        0,
        baseUrl.length - 1,
      );
    }

    if (baseUrl.endsWith(
      '/api/v1',
    )) {
      baseUrl = baseUrl.substring(
        0,
        baseUrl.length -
            '/api/v1'.length,
      );
    }

    final normalized =
    trimmed.startsWith('/')
        ? trimmed.substring(1)
        : trimmed;

    return '$baseUrl/$normalized';
  }

  Map<String, dynamic> _extractMap(
      dynamic data,
      ) {
    if (data is! Map) {
      throw StateError(
        'Dữ liệu backend không hợp lệ',
      );
    }

    final map =
    Map<String, dynamic>.from(
      data,
    );

    final nested = map['data'];

    if (nested is Map) {
      return Map<String, dynamic>.from(
        nested,
      );
    }

    return map;
  }
}
