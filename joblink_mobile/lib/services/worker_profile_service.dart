import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/worker_profile.dart';

class WorkerProfileService {
  final Dio _dio = ApiClient.dio;

  Future<WorkerProfile> getMyProfile() async {
    final response = await _dio.get('/workers/me/profile');

    return WorkerProfile.fromJson(_extractMap(response.data));
  }

  Future<WorkerProfile> updateMyProfile({
    String? fullName,
    String? phone,
    String? bio,
    String? searchArea,

    double? preferredMinSalary,
    String? preferredSalaryType,
    int? maxDistanceKm,

    List<String> skillIds = const [],
    List<String> categoryIds = const [],

    List<Map<String, dynamic>> availabilities = const [],
  }) async {
    final response = await _dio.patch(
      '/workers/me/profile',
      data: {
        'fullName': _nullableText(fullName),

        'phone': _nullableText(phone),

        'bio': _nullableText(bio),

        'searchArea': _nullableText(searchArea),

        'preferredMinSalary': preferredMinSalary,

        'preferredSalaryType': preferredSalaryType,

        'maxDistanceKm': maxDistanceKm,

        'skillIds': skillIds,

        'categoryIds': categoryIds,

        'availabilities': availabilities,
      },
    );

    return WorkerProfile.fromJson(_extractMap(response.data));
  }

  Future<List<WorkerOption>> getCategories() async {
    final response = await _dio.get('/jobs/meta/categories');

    return _extractList(response.data)
        .whereType<Map>()
        .map((item) => WorkerOption.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<WorkerOption>> getSkills() async {
    final response = await _dio.get('/jobs/meta/skills');

    return _extractList(response.data)
        .whereType<Map>()
        .map((item) => WorkerOption.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  String? _nullableText(String? value) {
    if (value == null) {
      return null;
    }

    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is! Map) {
      throw StateError('Dữ liệu backend không hợp lệ');
    }

    final map = Map<String, dynamic>.from(data);

    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }

    return map;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      for (final key in const [
        'items',
        'data',
        'categories',
        'skills',
        'results',
      ]) {
        final value = data[key];

        if (value is List) {
          return value;
        }

        if (value is Map) {
          for (final nestedKey in const [
            'items',
            'data',
            'categories',
            'skills',
            'results',
          ]) {
            final nested = value[nestedKey];

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
