import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/work_appointment.dart';

class WorkAppointmentService {
  final Dio _dio = ApiClient.dio;

  Future<List<WorkAppointment>> getMyAppointments() async {
    final response = await _dio.get('/workers/me/appointments');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Dữ liệu lịch làm việc không hợp lệ');
    }

    return data
        .whereType<Map>()
        .map(
          (item) => WorkAppointment.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((appointment) => appointment.id.isNotEmpty)
        .toList();
  }

  Future<void> confirm(String appointmentId, {bool ignoreConflict = false}) async {
    await _dio.patch(
      '/workers/me/appointments/$appointmentId/confirm',
      data: {'ignoreScheduleConflict': ignoreConflict},
    );
  }

  Future<void> decline(String appointmentId) async {
    await _dio.patch('/workers/me/appointments/$appointmentId/decline');
  }
}
