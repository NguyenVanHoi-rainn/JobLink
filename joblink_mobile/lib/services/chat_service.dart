import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

class ChatService {
  final Dio _dio = ApiClient.dio;

  Future<List<ChatConversation>>
  getConversations() async {
    final response = await _dio.get(
      '/conversations',
    );

    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) =>
          ChatConversation.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .where(
          (item) => item.id.isNotEmpty,
    )
        .toList();
  }

  Future<List<ChatMessage>> getMessages(
      String conversationId,
      ) async {
    final response = await _dio.get(
      '/conversations/$conversationId/messages',
      queryParameters: {
        'page': 1,
        'limit': 50,
      },
    );

    final data = response.data;

    if (data is! Map) {
      return [];
    }

    final items = data['items'];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map(
          (item) =>
          ChatMessage.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  Future<ChatMessage> sendText({
    required String conversationId,
    required String content,
    String? replyToId,
  }) async {
    final response = await _dio.post(
      '/conversations/$conversationId/messages',
      data: {
        'content': content.trim(),
        'replyToId': ?replyToId,
      },
    );

    return ChatMessage.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  Future<String> getCurrentUserId() async {
    final response = await _dio.get(
      '/auth/me',
    );

    final data =
    Map<String, dynamic>.from(
      response.data,
    );

    return (data['sub'] ?? data['id'])
        ?.toString() ??
        '';
  }

  Future<void> markConversationRead(
      String conversationId,
      ) async {
    await _dio.patch(
      '/conversations/$conversationId/read',
    );
  }

  Future<ChatMessage> uploadFile({
    required String conversationId,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/conversations/$conversationId/files',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return ChatMessage.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  String resolveFileUrl(
      String fileUrl,
      ) {
    if (fileUrl.startsWith('http://') ||
        fileUrl.startsWith('https://')) {
      return fileUrl;
    }

    var baseUrl = _dio.options.baseUrl;

    // http://10.0.2.2:3000
    baseUrl = baseUrl.replaceFirst(
      RegExp(r'/api/v1/?$'),
      '',
    );

    final cleanPath =
    fileUrl.startsWith('/')
        ? fileUrl.substring(1)
        : fileUrl;

    return '$baseUrl/$cleanPath';
  }

  Future<int> getTotalUnreadCount() async {
    final conversations =
    await getConversations();

    return conversations.fold<int>(
      0,
          (total, conversation) =>
      total + conversation.unreadCount,
    );
  }
}