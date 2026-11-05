import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

class EmployerApplicationService {
  final Dio _dio = ApiClient.dio;

  Future<List<Map<String, dynamic>>> getJobApplications(
      String jobId,
      ) async {
    final response = await _dio.get(
      '/employers/me/jobs/$jobId/applications',
    );
    return _extractList(response.data);
  }

  Future<Map<String, dynamic>> getApplicationDetail(
      String applicationId,
      ) async {
    final response = await _dio.get(
      '/employers/me/applications/$applicationId',
    );
    return _extractMap(response.data);
  }

  Future<Map<String, dynamic>> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    final response = await _dio.patch(
      '/employers/me/applications/$applicationId/status',
      data: {'status': status},
    );
    return _extractMap(response.data);
  }

  Future<Map<String, dynamic>> getCandidateMatch(
      String applicationId,
      ) async {
    final response = await _dio.get(
      '/employers/me/applications/$applicationId/match',
    );
    return _extractMap(response.data);
  }

  Future<Map<String, dynamic>> createPrivateChat(
      String targetUserId,
      ) async {
    final response = await _dio.post(
      '/conversations/private',
      data: {'targetUserId': targetUserId},
    );
    return _extractMap(response.data);
  }

  // Tạo Selected Group cho các ứng viên đậu
  Future<Map<String, dynamic>> createSelectedGroup({
    required String jobId,
    required String groupName,
    required List<String> workerUserIds,
  }) async {
    final response = await _dio.post(
      '/conversations/selected-group',
      data: {
        'jobId': jobId,
        'groupName': groupName,
        'workerUserIds': workerUserIds,
      },
    );

    return _extractMap(response.data);
  }

  String resolveFileUrl(String fileUrl) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }

    var baseUrl = _dio.options.baseUrl;
    baseUrl = baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');

    final cleanPath = fileUrl.startsWith('/')
        ? fileUrl.substring(1)
        : fileUrl;

    return '$baseUrl/$cleanPath';
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map) {
      for (final key in const ['items', 'data', 'applications', 'results']) {
        final value = data[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is! Map) {
      throw StateError('Dữ liệu không hợp lệ');
    }

    final map = Map<String, dynamic>.from(data);
    final nested = map['data'];

    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    return map;
  }
}