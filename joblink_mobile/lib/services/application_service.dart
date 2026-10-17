import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/application.dart';

class ApplicationService {
  final Dio _dio = ApiClient.dio;

  Future<List<JobApplication>>
  getMyApplications() async {
    final response = await _dio.get(
      '/applications/me',
    );

    final list = _extractList(
      response.data,
    );

    return list
        .whereType<Map>()
        .map(
          (item) =>
          JobApplication.fromJson(
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