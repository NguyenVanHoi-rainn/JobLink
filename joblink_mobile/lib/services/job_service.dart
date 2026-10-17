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
        'items',
        'data',
        'jobs',
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

  Future<bool> isJobSaved(
      String jobId,
      ) async {
    final response = await _dio.get(
      '/saved-jobs/$jobId/check',
    );

    final data = response.data;

    if (data is Map) {
      return data['isSaved'] == true;
    }

    return false;
  }

  Future<void> saveJob(
      String jobId,
      ) async {
    await _dio.post(
      '/saved-jobs/$jobId',
    );
  }

  Future<void> unsaveJob(
      String jobId,
      ) async {
    await _dio.delete(
      '/saved-jobs/$jobId',
    );
  }

  Future<List<Map<String, dynamic>>>
  getMyCvs() async {
    final response = await _dio.get(
      '/workers/me/cvs',
    );

    final data = response.data;

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(item),
      )
          .toList();
    }

    return [];
  }

  Future<bool> hasApplied(
      String jobId,
      ) async {
    final response = await _dio.get(
      '/applications/me',
    );

    final list = _extractList(
      response.data,
      keys: [
        'items',
        'data',
        'applications',
        'results',
      ],
    );

    for (final item in list) {
      if (item is! Map) continue;

      final application =
      Map<String, dynamic>.from(item);

      final directJobId =
      application['jobId']?.toString();

      String? nestedJobId;

      final rawJob = application['job'];

      if (rawJob is Map) {
        nestedJobId =
            rawJob['id']?.toString();
      }

      final status =
      application['status']?.toString();

      if ((directJobId == jobId ||
          nestedJobId == jobId) &&
          status != 'WITHDRAWN') {
        return true;
      }
    }

    return false;
  }

  Future<void> applyToJob({
    required String jobId,
    String? cvId,
    String? note,
  }) async {
    final data = <String, dynamic>{};

    if (cvId != null &&
        cvId.isNotEmpty) {
      data['cvId'] = cvId;
    }

    if (note != null &&
        note.trim().isNotEmpty) {
      data['note'] = note.trim();
    }

    await _dio.post(
      '/jobs/$jobId/apply',
      data: data,
    );
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
            'items',
            'data',
            'jobs',
            'applications',
            'recommendations',
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