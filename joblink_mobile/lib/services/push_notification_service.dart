import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/navigation/app_navigator.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/worker/chat_screen.dart';
import '../features/worker/worker_application_detail_screen.dart';
import '../features/employer/employer_application_detail_screen.dart';
import '../firebase_options.dart';
import 'chat_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
  PushNotificationService._();

  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final StreamController<void>
  _notificationReceivedController =
  StreamController<void>.broadcast();

  Map<String, dynamic>? _pendingNavigationData;

  String? _currentFid;
  Completer<String>? _fidCompleter;

  Stream<void> get onNotificationReceived =>
      _notificationReceivedController.stream;

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _messaging.onRegistered.listen(
          (fid) {
        _currentFid = fid;

        final completer = _fidCompleter;

        if (completer != null &&
            !completer.isCompleted) {
          completer.complete(fid);
        }

        unawaited(
          _sendFidToBackend(fid),
        );
      },
      onError: (Object error) {
        debugPrint(
          'Không thể đăng ký FCM bằng FID: $error',
        );

        final completer = _fidCompleter;

        if (completer != null &&
            !completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    FirebaseMessaging.onMessage.listen(
          (message) {
        debugPrint(
          'FCM foreground: ${message.messageId}',
        );

        _notificationReceivedController.add(null);
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
          (message) {
        _pendingNavigationData =
        Map<String, dynamic>.from(
          message.data,
        );

        _notificationReceivedController.add(null);

        unawaited(
          handlePendingNavigation(),
        );
      },
    );

    final initialMessage =
    await _messaging.getInitialMessage();

    if (initialMessage != null) {
      _pendingNavigationData =
      Map<String, dynamic>.from(
        initialMessage.data,
      );
    }

    // firebase_messaging 17 dùng Firebase Installation ID (FID).
    // Subscribe onRegistered trước rồi mới gọi register().
    await _messaging.register();
  }

  // Giữ tên syncToken để không phải sửa các file đang gọi hàm này.
  // Từ firebase_messaging 17, giá trị đồng bộ thực tế là FID.
  Future<void> syncToken({
    String? tokenOverride,
  }) async {
    try {
      final fid =
          tokenOverride ??
              await _getOrRegisterFid();

      if (fid == null ||
          fid.isEmpty) {
        return;
      }

      await _sendFidToBackend(fid);
    } catch (error) {
      debugPrint(
        'Không thể đồng bộ Firebase Installation ID: $error',
      );
    }
  }

  Future<void> _sendFidToBackend(
      String fid,
      ) async {
    final accessToken =
    await TokenStorage.getToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      return;
    }

    await ApiClient.dio.post(
      '/notifications/device-token',
      data: {
        // Backend hiện giữ tên field "token" để không cần
        // đổi API/database lần nữa. Giá trị này là FID.
        'token': fid,
        'platform': 'android',
      },
    );

    debugPrint(
      'Firebase Installation ID đã đồng bộ với backend',
    );
  }

  Future<String?> _getOrRegisterFid() async {
    final current = _currentFid;

    if (current != null &&
        current.isNotEmpty) {
      return current;
    }

    final existingCompleter =
        _fidCompleter;

    if (existingCompleter != null &&
        !existingCompleter.isCompleted) {
      return existingCompleter.future.timeout(
        const Duration(seconds: 10),
      );
    }

    final completer =
    Completer<String>();

    _fidCompleter = completer;

    try {
      await _messaging.register();

      return await completer.future.timeout(
        const Duration(seconds: 10),
      );
    } on TimeoutException {
      debugPrint(
        'Hết thời gian chờ Firebase Installation ID',
      );

      return null;
    } finally {
      if (identical(
        _fidCompleter,
        completer,
      )) {
        _fidCompleter = null;
      }
    }
  }

  Future<void> unregisterCurrentToken() async {
    try {
      final accessToken =
      await TokenStorage.getToken();

      if (accessToken == null ||
          accessToken.isEmpty) {
        return;
      }

      final fid =
      await _getOrRegisterFid();

      if (fid == null ||
          fid.isEmpty) {
        return;
      }

      await ApiClient.dio.delete(
        '/notifications/device-token',
        data: {
          // Giá trị gửi lên là Firebase Installation ID.
          'token': fid,
        },
      );
    } catch (error) {
      debugPrint(
        'Không thể gỡ Firebase Installation ID khỏi backend: $error',
      );
    }
  }

  Future<bool>
  handlePendingNavigation() async {
    final data =
        _pendingNavigationData;

    if (data == null) {
      return false;
    }

    final accessToken =
    await TokenStorage.getToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      return false;
    }

    final referenceType =
    data['referenceType']
        ?.toString();

    final referenceId =
    data['referenceId']
        ?.toString();

    final type =
    data['type']
        ?.toString();

    if (referenceId == null ||
        referenceId.isEmpty) {
      _pendingNavigationData = null;
      return false;
    }

    final navigator =
        appNavigatorKey.currentState;

    if (navigator == null) {
      return false;
    }

    if (referenceType ==
        'CONVERSATION') {
      return _openConversation(
        navigator,
        referenceId,
      );
    }

    if (referenceType ==
        'APPLICATION') {
      if (_isWorkerApplicationType(
        type,
      )) {
        _pendingNavigationData = null;

        await navigator.push(
          MaterialPageRoute(
            builder: (_) =>
                WorkerApplicationDetailScreen(
                  applicationId:
                  referenceId,
                ),
          ),
        );

        return true;
      }

      if (_isEmployerApplicationType(
        type,
      )) {
        _pendingNavigationData = null;

        await navigator.push(
          MaterialPageRoute(
            builder: (_) =>
                EmployerApplicationDetailScreen(
                  applicationId:
                  referenceId,
                ),
          ),
        );

        return true;
      }
    }

    _pendingNavigationData = null;
    return false;
  }

  bool _isWorkerApplicationType(
      String? type,
      ) {
    return type ==
        'APPLICATION_REVIEWING' ||
        type ==
            'APPLICATION_ACCEPTED' ||
        type ==
            'APPLICATION_REJECTED';
  }

  bool _isEmployerApplicationType(
      String? type,
      ) {
    return type ==
        'APPLICATION_CREATED' ||
        type ==
            'APPLICATION_WITHDRAWN';
  }

  Future<bool> _openConversation(
      NavigatorState navigator,
      String conversationId,
      ) async {
    try {
      final conversations =
      await ChatService()
          .getConversations();

      dynamic conversation;

      for (final item
      in conversations) {
        if (item.id ==
            conversationId) {
          conversation = item;
          break;
        }
      }

      if (conversation == null) {
        return false;
      }

      _pendingNavigationData = null;

      await navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(
                conversation:
                conversation,
              ),
        ),
      );

      return true;
    } catch (error) {
      debugPrint(
        'Không thể mở chat từ notification: $error',
      );

      return false;
    }
  }
}
