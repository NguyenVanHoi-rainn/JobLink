import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

class EmployerJobService {
  final Dio _dio = ApiClient.dio;

  // =====================================================
  // GET JOBS
  // =====================================================

  Future<List<Map<String, dynamic>>> getMyJobs() async {
    final response = await _dio.get('/employers/me/jobs');

    return _extractList(response.data);
  }

  Future<Map<String, dynamic>> getMyJobById(String jobId) async {
    final response = await _dio.get('/employers/me/jobs/$jobId');

    return _extractMap(response.data);
  }

  // =====================================================
  // META
  // =====================================================

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _dio.get('/employers/me/jobs/meta/categories');

    return _extractList(response.data);
  }

  Future<List<Map<String, dynamic>>> getSkills() async {
    final response = await _dio.get('/employers/me/jobs/meta/skills');

    return _extractList(response.data);
  }

  // =====================================================
  // CREATE JOB
  // =====================================================

  Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required String categoryId,

    required double salary,
    required String salaryType,

    required String location,

    double? latitude,
    double? longitude,

    required String shiftType,
    required String startTime,
    required String endTime,
    required List<String> workDays,

    required bool urgent,
    DateTime? urgentUntil,

    required bool cvRequired,
    DateTime? deadline,

    List<String> skillIds = const [],
  }) async {
    final data = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'categoryId': categoryId,

      'salary': salary,
      'salaryType': salaryType,

      'location': location.trim(),

      'shiftType': shiftType,
      'startTime': startTime,
      'endTime': endTime,
      'workDays': workDays,

      'urgent': urgent,

      'cvRequired': cvRequired,

      'skillIds': skillIds,
    };

    if (latitude != null) {
      data['latitude'] = latitude;
    }

    if (longitude != null) {
      data['longitude'] = longitude;
    }

    if (urgent && urgentUntil != null) {
      data['urgentUntil'] = urgentUntil.toUtc().toIso8601String();
    }

    if (deadline != null) {
      data['deadline'] = deadline.toUtc().toIso8601String();
    }

    final response = await _dio.post('/employers/me/jobs', data: data);

    return _extractMap(response.data);
  }

  // =====================================================
  // UPDATE JOB
  //
  // Giữ positional jobId để tương thích màn
  // employer_edit_job_screen.dart hiện tại.
  // =====================================================

  Future<Map<String, dynamic>> updateJob({
    required String jobId,
    String? title,
    String? description,
    String? categoryId,

    double? salary,
    String? salaryType,

    String? location,

    double? latitude,
    double? longitude,

    String? shiftType,
    String? startTime,
    String? endTime,
    List<String>? workDays,

    bool? urgent,
    DateTime? urgentUntil,

    bool? cvRequired,
    DateTime? deadline,

    List<String>? skillIds,

    bool clearDeadline = false,
    bool clearUrgentUntil = false,
  }) async {
    final data = <String, dynamic>{};

    if (title != null) {
      data['title'] = title.trim();
    }

    if (description != null) {
      data['description'] = description.trim();
    }

    if (categoryId != null) {
      data['categoryId'] = categoryId;
    }

    if (salary != null) {
      data['salary'] = salary;
    }

    if (salaryType != null) {
      data['salaryType'] = salaryType;
    }

    if (location != null) {
      data['location'] = location.trim();
    }

    if (latitude != null) {
      data['latitude'] = latitude;
    }

    if (longitude != null) {
      data['longitude'] = longitude;
    }

    if (shiftType != null) {
      data['shiftType'] = shiftType;
    }

    if (startTime != null) {
      data['startTime'] = startTime;
    }

    if (endTime != null) {
      data['endTime'] = endTime;
    }

    if (workDays != null) {
      data['workDays'] = workDays;
    }

    if (urgent != null) {
      data['urgent'] = urgent;
    }

    if (clearUrgentUntil) {
      data['urgentUntil'] = null;
    } else if (urgentUntil != null) {
      data['urgentUntil'] = urgentUntil.toUtc().toIso8601String();
    }

    if (cvRequired != null) {
      data['cvRequired'] = cvRequired;
    }

    if (clearDeadline) {
      data['deadline'] = null;
    } else if (deadline != null) {
      data['deadline'] = deadline.toUtc().toIso8601String();
    }

    if (skillIds != null) {
      data['skillIds'] = skillIds;
    }

    final response = await _dio.patch('/employers/me/jobs/$jobId', data: data);

    return _extractMap(response.data);
  }

  // =====================================================
  // PUBLISH
  // =====================================================

  Future<Map<String, dynamic>> publishJob(String jobId) async {
    final response = await _dio.patch('/employers/me/jobs/$jobId/publish');

    return _extractMap(response.data);
  }

  // =====================================================
  // CLOSE
  // =====================================================

  Future<Map<String, dynamic>> closeJob(String jobId) async {
    final response = await _dio.patch('/employers/me/jobs/$jobId/close');

    return _extractMap(response.data);
  }

  // =====================================================
  // REPUBLISH
  // =====================================================

  Future<Map<String, dynamic>> republishJob(String jobId) async {
    final response = await _dio.patch('/employers/me/jobs/$jobId/republish');

    return _extractMap(response.data);
  }

  // =====================================================
  // RESPONSE HELPERS
  // =====================================================

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map) {
      for (final key in const ['items', 'data', 'jobs', 'results']) {
        final value = data[key];

        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        if (value is Map) {
          for (final nestedKey in const ['items', 'jobs', 'results']) {
            final nested = value[nestedKey];

            if (nested is List) {
              return nested
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            }
          }
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is! Map) {
      throw StateError('Dữ liệu backend không hợp lệ');
    }

    final map = Map<String, dynamic>.from(data);

    final nested = map['data'];

    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    return map;
  }
}
