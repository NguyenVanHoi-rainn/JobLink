import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/job.dart';

class JobService {
  final Dio _dio = ApiClient.dio;

  Future<List<Job>> getJobs() async {
    final response = await _dio.get(
      '/jobs',
      queryParameters: {
        'page': 1,
        'limit': 20,
      },
    );

    final list = _extractList(
      response.data,
      keys: [
        'data',
        'jobs',
        'items',
        'results',
      ],
    );

    return list
        .whereType<Map>()
        .map(
          (item) => Job.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .where(
          (job) => job.id.isNotEmpty,
    )
        .toList();
  }

  Future<List<JobRecommendation>>
  getRecommendations() async {
    final response = await _dio.get(
      '/workers/me/recommendations/jobs',
    );

    final list = _extractList(
      response.data,
      keys: [
        'recommendations',
        'data',
        'items',
        'results',
      ],
    );

    return list
        .whereType<Map>()
        .map(
          (item) => JobRecommendation.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .where(
          (item) => item.job.id.isNotEmpty,
    )
        .toList();
  }

  List<dynamic> _extractList(
      dynamic data, {
        required List<String> keys,
      }) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      for (final key in keys) {
        final value = data[key];

        if (value is List) {
          return value;
        }

        if (value is Map) {
          for (final nestedKey in [
            'data',
            'items',
            'jobs',
            'results',
            'recommendations',
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