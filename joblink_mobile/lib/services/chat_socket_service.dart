import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/chat_message.dart';

class ChatSocketService {
  io.Socket? _socket;

  String get _socketUrl {
    var baseUrl =
    ApiClient.dio.options.baseUrl.trim();

    while (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(
        0,
        baseUrl.length - 1,
      );
    }

    if (baseUrl.endsWith('/api/v1')) {
      baseUrl = baseUrl.substring(
        0,
        baseUrl.length -
            '/api/v1'.length,
      );
    }

    return '$baseUrl/chat';
  }

  Future<void> connect({
    required String conversationId,
    required void Function() onConnected,
    required void Function() onDisconnected,
    required void Function(
        ChatMessage message,
        ) onMessage,
    void Function(
        String userId,
        DateTime lastReadAt,
        )? onConversationRead,
    void Function(
        String userId,
        bool isTyping,
        )? onTyping,
    void Function(
        Set<String> onlineUserIds,
        )? onPresenceSnapshot,
    void Function(
        String userId,
        bool isOnline,
        )? onPresence,
    void Function(Object error)? onError,
  }) async {
    disconnect();

    final token =
    await TokenStorage.getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Không tìm thấy access token',
      );
    }

    final socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({
        'token': token,
      })
          .build(),
    );

    _socket = socket;

    socket.on(
      'connect',
          (_) {
        socket.emit(
          'joinConversation',
          {
            'conversationId':
            conversationId,
          },
        );

        onConnected();
      },
    );

    socket.on(
      'disconnect',
          (_) {
        onDisconnected();
      },
    );

    socket.on(
      'connect_error',
          (error) {
        onError?.call(
          error is Object
              ? error
              : Exception(
            error.toString(),
          ),
        );
      },
    );

    socket.on(
      'error',
          (error) {
        onError?.call(
          error is Object
              ? error
              : Exception(
            error.toString(),
          ),
        );
      },
    );

    socket.on(
      'newMessage',
          (data) {
        try {
          if (data is! Map) {
            return;
          }

          final json =
          Map<String, dynamic>.from(
            data,
          );

          final message =
          ChatMessage.fromJson(
            json,
          );

          if (message.conversationId !=
              conversationId) {
            return;
          }

          onMessage(message);
        } catch (error) {
          onError?.call(error);
        }
      },
    );

    socket.on(
      'conversationRead',
          (data) {
        try {
          if (data is! Map) {
            return;
          }

          final json =
          Map<String, dynamic>.from(
            data,
          );

          final eventConversationId =
          json['conversationId']
              ?.toString();

          if (eventConversationId !=
              conversationId) {
            return;
          }

          final userId =
          json['userId']
              ?.toString();

          final lastReadAt =
          DateTime.tryParse(
            json['lastReadAt']
                ?.toString() ??
                '',
          );

          if (userId == null ||
              userId.isEmpty ||
              lastReadAt == null) {
            return;
          }

          onConversationRead?.call(
            userId,
            lastReadAt,
          );
        } catch (error) {
          onError?.call(error);
        }
      },
    );

    socket.on(
      'typing',
          (data) {
        try {
          if (data is! Map) {
            return;
          }

          final json =
          Map<String, dynamic>.from(
            data,
          );

          final eventConversationId =
          json['conversationId']
              ?.toString();

          if (eventConversationId !=
              conversationId) {
            return;
          }

          final userId =
          json['userId']
              ?.toString();

          final isTyping =
              json['isTyping'] == true;

          if (userId == null ||
              userId.isEmpty) {
            return;
          }

          onTyping?.call(
            userId,
            isTyping,
          );
        } catch (error) {
          onError?.call(error);
        }
      },
    );

    socket.on(
      'presenceSnapshot',
          (data) {
        try {
          if (data is! Map) {
            return;
          }

          final json =
          Map<String, dynamic>.from(
            data,
          );

          final eventConversationId =
          json['conversationId']
              ?.toString();

          if (eventConversationId !=
              conversationId) {
            return;
          }

          final rawIds =
          json['onlineUserIds'];

          final onlineUserIds =
          <String>{};

          if (rawIds is List) {
            for (final rawId in rawIds) {
              final userId =
              rawId?.toString();

              if (userId != null &&
                  userId.isNotEmpty) {
                onlineUserIds.add(
                  userId,
                );
              }
            }
          }

          onPresenceSnapshot?.call(
            onlineUserIds,
          );
        } catch (error) {
          onError?.call(error);
        }
      },
    );

    socket.on(
      'presence',
          (data) {
        try {
          if (data is! Map) {
            return;
          }

          final json =
          Map<String, dynamic>.from(
            data,
          );

          final eventConversationId =
          json['conversationId']
              ?.toString();

          if (eventConversationId !=
              conversationId) {
            return;
          }

          final userId =
          json['userId']
              ?.toString();

          final isOnline =
              json['isOnline'] == true;

          if (userId == null ||
              userId.isEmpty) {
            return;
          }

          onPresence?.call(
            userId,
            isOnline,
          );
        } catch (error) {
          onError?.call(error);
        }
      },
    );

    socket.connect();
  }

  Future<ChatMessage> sendText({
    required String conversationId,
    required String content,
    String? replyToId,
  }) async {
    final socket = _socket;

    if (socket == null ||
        !socket.connected) {
      throw Exception(
        'Socket chưa kết nối',
      );
    }

    final completer =
    Completer<ChatMessage>();

    final data = <String, dynamic>{
      'conversationId': conversationId,
      'content': content.trim(),
      'messageType': 'TEXT',
      'replyToId': ?replyToId,
    };

    socket.emitWithAck(
      'sendMessage',
      data,
      ack: (response) {
        if (completer.isCompleted) {
          return;
        }

        try {
          dynamic raw = response;

          if (raw is List &&
              raw.isNotEmpty) {
            raw = raw.first;
          }

          if (raw is! Map) {
            throw Exception(
              'Phản hồi Socket không hợp lệ',
            );
          }

          final json =
          Map<String, dynamic>.from(
            raw,
          );

          completer.complete(
            ChatMessage.fromJson(json),
          );
        } catch (error) {
          completer.completeError(error);
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception(
          'Gửi tin nhắn quá thời gian chờ',
        );
      },
    );
  }

  void setTyping({
    required String conversationId,
    required bool isTyping,
  }) {
    final socket = _socket;

    if (socket == null ||
        !socket.connected) {
      return;
    }

    socket.emit(
      'typing',
      {
        'conversationId':
        conversationId,
        'isTyping': isTyping,
      },
    );
  }

  void joinConversation(
      String conversationId,
      ) {
    final socket = _socket;

    if (socket == null ||
        !socket.connected) {
      return;
    }

    socket.emit(
      'joinConversation',
      {
        'conversationId':
        conversationId,
      },
    );
  }

  void disconnect() {
    final socket = _socket;

    if (socket == null) {
      return;
    }

    socket.off('newMessage');
    socket.off('conversationRead');
    socket.off('typing');
    socket.off('presenceSnapshot');
    socket.off('presence');
    socket.off('connect');
    socket.off('disconnect');
    socket.off('connect_error');
    socket.off('error');

    socket.disconnect();
    socket.dispose();

    _socket = null;
  }
}
