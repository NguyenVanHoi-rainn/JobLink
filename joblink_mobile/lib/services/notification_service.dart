import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationService {
  final Dio _dio = ApiClient.dio;

  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 50,
    bool? isRead,
    String? type,
  }) async {
    final response = await _dio.get(
      '/notifications',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (isRead != null)
          'isRead': isRead.toString(),
        if (type != null && type.isNotEmpty)
          'type': type,
      },
    );

    final data = Map<String, dynamic>.from(
      response.data as Map,
    );

    final rawItems = data['items'];

    if (rawItems is! List) {
      return [];
    }

    return rawItems
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(
      '/notifications/unread-count',
    );

    final data = Map<String, dynamic>.from(
      response.data as Map,
    );

    return int.tryParse(
      data['unreadCount']?.toString() ?? '0',
    ) ??
        0;
  }

  Future<AppNotification> markAsRead(
      String notificationId,
      ) async {
    final response = await _dio.patch(
      '/notifications/$notificationId/read',
    );

    return AppNotification.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
    );
  }

  Future<int> markAllAsRead() async {
    final response = await _dio.patch(
      '/notifications/read-all',
    );

    final data = Map<String, dynamic>.from(
      response.data as Map,
    );

    return int.tryParse(
      data['updatedCount']?.toString() ?? '0',
    ) ??
        0;
  }
}
