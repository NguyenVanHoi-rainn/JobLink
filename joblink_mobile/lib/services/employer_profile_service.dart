import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

class EmployerProfileService {
  final Dio _dio =
      ApiClient.dio;

  // =====================================================
  // GET PROFILE
  // =====================================================

  Future<Map<String, dynamic>>
  getProfile() async {
    final response =
    await _dio.get(
      '/employers/me/profile',
    );

    return _extractMap(
      response.data,
    );
  }

  // =====================================================
  // UPDATE
  // =====================================================

  Future<Map<String, dynamic>>
  updateProfile({
    required String companyName,
    required String contactName,
    required String phone,
    required String address,
    required String description,
    required String taxCode,
    required String businessLicense,
  }) async {
    final response =
    await _dio.patch(
      '/employers/me/profile',

      data: {
        'companyName':
        companyName.trim(),

        'contactName':
        contactName.trim(),

        'phone':
        phone.trim(),

        'address':
        address.trim(),

        'description':
        description.trim(),

        'taxCode':
        taxCode.trim(),

        'businessLicense':
        businessLicense.trim(),
      },
    );

    return _extractMap(
      response.data,
    );
  }

  // =====================================================
  // SUBMIT VERIFICATION
  // =====================================================

  Future<Map<String, dynamic>>
  submitVerification() async {
    final response =
    await _dio.patch(
      '/employers/me/profile/submit-verification',
    );

    return _extractMap(
      response.data,
    );
  }

  // =====================================================
  // HELPER
  // =====================================================

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

    final nested =
    map['data'];

    if (nested is Map) {
      return Map<String, dynamic>.from(
        nested,
      );
    }

    return map;
  }
}