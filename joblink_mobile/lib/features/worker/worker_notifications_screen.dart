import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../models/chat_conversation.dart';

import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';

import 'chat_screen.dart';
import 'worker_application_detail_screen.dart';

class WorkerNotificationsScreen
    extends StatefulWidget {
  const WorkerNotificationsScreen({
    super.key,
  });

  @override
  State<WorkerNotificationsScreen>
  createState() =>
      _WorkerNotificationsScreenState();
}

class _WorkerNotificationsScreenState
    extends State<WorkerNotificationsScreen> {
  static const Color _primaryColor =
  Color(0xFF2563EB);

  final NotificationService
  _notificationService =
  NotificationService();

  final ChatService _chatService =
  ChatService();

  List<AppNotification>
  _notifications = [];

  bool _loading = true;
  bool _markingAll = false;

  String? _error;

  StreamSubscription<void>?
  _notificationSubscription;

  bool get _hasUnread {
    return _notifications.any(
          (item) => !item.isRead,
    );
  }

  @override
  void initState() {
    super.initState();

    _load();

    _notificationSubscription =
        PushNotificationService
            .instance
            .onNotificationReceived
            .listen(
              (_) {
            _load();
          },
        );
  }

  @override
  void dispose() {
    _notificationSubscription
        ?.cancel();

    super.dispose();
  }

  // =====================================================
  // LOAD
  // =====================================================

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data =
      await _notificationService
          .getNotifications();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = data;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            _dioErrorMessage(
              error,
              fallback:
              'Không thể tải thông báo',
            );
      });
    } catch (error) {
      debugPrint(
        'Load worker notifications failed: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _error =
        'Không thể tải thông báo';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =====================================================
  // MARK ALL READ
  // =====================================================

  Future<void>
  _markAllAsRead() async {
    if (_markingAll ||
        !_hasUnread) {
      return;
    }

    setState(() {
      _markingAll = true;
    });

    try {
      await _notificationService
          .markAllAsRead();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications =
            _notifications
                .map(
                  (item) =>
                  item.copyWith(
                    isRead: true,
                  ),
            )
                .toList();
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _dioErrorMessage(
          error,
          fallback:
          'Không thể đánh dấu tất cả là đã đọc',
        ),
        error: true,
      );
    } catch (error) {
      _showMessage(
        'Không thể đánh dấu tất cả là đã đọc',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _markingAll = false;
        });
      }
    }
  }

  // =====================================================
  // NOTIFICATION TAP
  // =====================================================

  Future<void>
  _handleNotificationTap(
      AppNotification notification,
      ) async {
    var current =
        notification;

    // Đánh dấu đã đọc trước.
    if (!notification.isRead) {
      try {
        current =
        await _notificationService
            .markAsRead(
          notification.id,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _notifications =
              _notifications.map(
                    (item) {
                  if (item.id ==
                      current.id) {
                    return current;
                  }

                  return item;
                },
              ).toList();
        });
      } on DioException catch (error) {
        if (!mounted) {
          return;
        }

        _showMessage(
          _dioErrorMessage(
            error,
            fallback:
            'Không thể đánh dấu thông báo đã đọc',
          ),
          error: true,
        );

        return;
      }
    }

    final referenceType =
        current.referenceType;

    final referenceId =
        current.referenceId;

    if (referenceId == null ||
        referenceId.isEmpty) {
      return;
    }

    // ===================================================
    // CHAT
    // ===================================================

    if (referenceType ==
        'CONVERSATION') {
      await _openConversation(
        referenceId,
      );

      return;
    }

    // ===================================================
    // APPLICATION
    // ===================================================

    if (referenceType ==
        'APPLICATION' &&
        _isWorkerApplicationType(
          current.type,
        )) {
      await _openApplication(
        referenceId,
      );

      return;
    }
  }

  bool _isWorkerApplicationType(
      String type,
      ) {
    return type ==
        'APPLICATION_REVIEWING' ||
        type ==
            'APPLICATION_ACCEPTED' ||
        type ==
            'APPLICATION_REJECTED' ||
        type ==
            'APPLICATION_STATUS' ||
        type ==
            'APPLICATION';
  }

  // =====================================================
  // OPEN APPLICATION
  // =====================================================

  Future<void> _openApplication(
      String applicationId,
      ) async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              WorkerApplicationDetailScreen(
                applicationId:
                applicationId,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _load();
    } catch (error) {
      debugPrint(
        'Open worker application from notification failed: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể mở hồ sơ ứng tuyển',
        error: true,
      );
    }
  }

  // =====================================================
  // OPEN CHAT
  // =====================================================

  Future<void> _openConversation(
      String conversationId,
      ) async {
    try {
      final conversations =
      await _chatService
          .getConversations();

      ChatConversation? target;

      for (final conversation
      in conversations) {
        if (conversation.id ==
            conversationId) {
          target = conversation;
          break;
        }
      }

      if (!mounted) {
        return;
      }

      if (target == null) {
        _showMessage(
          'Cuộc trò chuyện không còn khả dụng.',
          error: true,
        );

        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(
                conversation:
                target!,
              ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _load();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _dioErrorMessage(
          error,
          fallback:
          'Không thể mở cuộc trò chuyện',
        ),
        error: true,
      );
    } catch (error) {
      debugPrint(
        'Open conversation failed: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể mở cuộc trò chuyện',
        error: true,
      );
    }
  }

  // =====================================================
  // ERROR HELPERS
  // =====================================================

  String _dioErrorMessage(
      DioException error, {
        required String fallback,
      }) {
    final data =
        error.response?.data;

    if (data is Map &&
        data['message'] != null) {
      final message =
      data['message'];

      if (message is List) {
        return message.join(
          '\n',
        );
      }

      return message.toString();
    }

    return fallback;
  }

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          error
              ? Colors.red.shade700
              : null,
          content:
          Text(message),
        ),
      );
  }

  // =====================================================
  // NOTIFICATION ICON
  // =====================================================

  IconData _iconForType(
      String type,
      ) {
    switch (type) {
      case 'CHAT_MESSAGE':
        return Icons
            .chat_bubble_outline_rounded;

      case 'APPLICATION_REVIEWING':
        return Icons
            .visibility_outlined;

      case 'APPLICATION_ACCEPTED':
        return Icons
            .check_circle_outline_rounded;

      case 'APPLICATION_REJECTED':
        return Icons
            .cancel_outlined;

      case 'APPLICATION_STATUS':
      case 'APPLICATION':
        return Icons
            .work_outline_rounded;

      case 'WORK_APPOINTMENT':
      case 'APPOINTMENT':
        return Icons
            .event_available_outlined;

      case 'EMPLOYER_VERIFICATION':
      case 'VERIFICATION':
        return Icons
            .verified_user_outlined;

      case 'REPORT':
        return Icons
            .report_outlined;

      default:
        return Icons
            .notifications_none_rounded;
    }
  }

  // =====================================================
  // NOTIFICATION COLOR
  // =====================================================

  Color _colorForType(
      String type,
      ) {
    switch (type) {
      case 'CHAT_MESSAGE':
        return const Color(
          0xFF2563EB,
        );

      case 'APPLICATION_REVIEWING':
        return const Color(
          0xFFF59E0B,
        );

      case 'APPLICATION_ACCEPTED':
        return const Color(
          0xFF16A34A,
        );

      case 'APPLICATION_REJECTED':
        return const Color(
          0xFFDC2626,
        );

      case 'APPLICATION_STATUS':
      case 'APPLICATION':
        return const Color(
          0xFF7C3AED,
        );

      case 'WORK_APPOINTMENT':
      case 'APPOINTMENT':
        return const Color(
          0xFF0891B2,
        );

      case 'EMPLOYER_VERIFICATION':
      case 'VERIFICATION':
        return const Color(
          0xFF7C3AED,
        );

      case 'REPORT':
        return const Color(
          0xFFEA580C,
        );

      default:
        return const Color(
          0xFF475569,
        );
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF5F7FB,
      ),

      appBar: AppBar(
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,

        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          TextButton(
            onPressed:
            _hasUnread &&
                !_markingAll
                ? _markAllAsRead
                : null,

            child: _markingAll
                ? const SizedBox(
              width: 16,
              height: 16,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Đọc tất cả',
            ),
          ),

          const SizedBox(
            width: 6,
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _ErrorState(
        message:
        _error!,
        onRetry:
        _load,
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh:
        _load,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 150,
            ),
            _EmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
      _load,

      child: ListView.separated(
        physics:
        const AlwaysScrollableScrollPhysics(),

        padding:
        const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          28,
        ),

        itemCount:
        _notifications.length,

        separatorBuilder:
            (_, _) =>
        const SizedBox(
          height: 10,
        ),

        itemBuilder:
            (
            context,
            index,
            ) {
          final notification =
          _notifications[index];

          final color =
          _colorForType(
            notification.type,
          );

          return Material(
            color:
            Colors.white,

            borderRadius:
            BorderRadius.circular(
              18,
            ),

            child: InkWell(
              borderRadius:
              BorderRadius.circular(
                18,
              ),

              onTap: () =>
                  _handleNotificationTap(
                    notification,
                  ),

              child: Container(
                padding:
                const EdgeInsets.all(
                  15,
                ),

                decoration:
                BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),

                  border:
                  Border.all(
                    color:
                    notification
                        .isRead
                        ? Colors
                        .grey
                        .shade200
                        : _primaryColor
                        .withValues(
                      alpha:
                      0.18,
                    ),
                  ),
                ),

                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    // =====================================
                    // ICON
                    // =====================================

                    Container(
                      width: 46,
                      height: 46,

                      decoration:
                      BoxDecoration(
                        color:
                        color.withValues(
                          alpha:
                          0.09,
                        ),

                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),

                      child: Icon(
                        _iconForType(
                          notification
                              .type,
                        ),
                        color:
                        color,
                        size:
                        23,
                      ),
                    ),

                    const SizedBox(
                      width: 13,
                    ),

                    // =====================================
                    // CONTENT
                    // =====================================

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [
                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            children: [
                              Expanded(
                                child:
                                Text(
                                  notification
                                      .title,

                                  style:
                                  TextStyle(
                                    fontSize:
                                    14.5,

                                    fontWeight:
                                    notification
                                        .isRead
                                        ? FontWeight
                                        .w600
                                        : FontWeight
                                        .w800,

                                    color:
                                    const Color(
                                      0xFF0F172A,
                                    ),
                                  ),
                                ),
                              ),

                              if (!notification
                                  .isRead) ...[
                                const SizedBox(
                                  width: 8,
                                ),

                                Container(
                                  width: 8,
                                  height: 8,

                                  margin:
                                  const EdgeInsets.only(
                                    top: 5,
                                  ),

                                  decoration:
                                  const BoxDecoration(
                                    color:
                                    _primaryColor,
                                    shape:
                                    BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            notification
                                .content,

                            style:
                            TextStyle(
                              color: Colors
                                  .grey
                                  .shade700,

                              fontSize:
                              13,

                              height:
                              1.35,
                            ),
                          ),

                          if (notification
                              .timeText
                              .isNotEmpty) ...[
                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              notification
                                  .timeText,

                              style:
                              TextStyle(
                                color: Colors
                                    .grey
                                    .shade500,

                                fontSize:
                                11.5,
                              ),
                            ),
                          ],

                          // =================================
                          // HINT
                          // =================================

                          if (_canOpen(
                            notification,
                          )) ...[
                            const SizedBox(
                              height: 9,
                            ),

                            Row(
                              children: [
                                Text(
                                  _openText(
                                    notification,
                                  ),

                                  style:
                                  const TextStyle(
                                    color:
                                    _primaryColor,

                                    fontSize:
                                    12,

                                    fontWeight:
                                    FontWeight
                                        .w700,
                                  ),
                                ),

                                const SizedBox(
                                  width: 3,
                                ),

                                const Icon(
                                  Icons
                                      .chevron_right_rounded,

                                  color:
                                  _primaryColor,

                                  size:
                                  18,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _canOpen(
      AppNotification notification,
      ) {
    if (notification.referenceId ==
        null ||
        notification.referenceId!
            .isEmpty) {
      return false;
    }

    if (notification.referenceType ==
        'CONVERSATION') {
      return true;
    }

    if (notification.referenceType ==
        'APPLICATION' &&
        _isWorkerApplicationType(
          notification.type,
        )) {
      return true;
    }

    return false;
  }

  String _openText(
      AppNotification notification,
      ) {
    if (notification.referenceType ==
        'CONVERSATION') {
      return 'Mở cuộc trò chuyện';
    }

    if (notification.referenceType ==
        'APPLICATION') {
      return 'Xem hồ sơ ứng tuyển';
    }

    return 'Xem chi tiết';
  }
}

// =========================================================
// EMPTY STATE
// =========================================================

class _EmptyState
    extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Container(
              width: 82,
              height: 82,

              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFF2563EB,
                ).withValues(
                  alpha:
                  0.08,
                ),

                shape:
                BoxShape.circle,
              ),

              child:
              const Icon(
                Icons
                    .notifications_none_rounded,

                size:
                38,

                color:
                Color(
                  0xFF2563EB,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Chưa có thông báo',

              style: TextStyle(
                fontSize:
                17,

                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Các cập nhật về việc làm, ứng tuyển và tin nhắn sẽ xuất hiện tại đây.',

              textAlign:
              TextAlign.center,

              style:
              TextStyle(
                color: Colors
                    .grey
                    .shade600,

                height:
                1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// ERROR STATE
// =========================================================

class _ErrorState
    extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          28,
        ),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            const Icon(
              Icons
                  .cloud_off_rounded,

              size:
              48,

              color:
              Colors.redAccent,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              message,

              textAlign:
              TextAlign.center,
            ),

            const SizedBox(
              height: 14,
            ),

            OutlinedButton.icon(
              onPressed:
              onRetry,

              icon:
              const Icon(
                Icons
                    .refresh_rounded,
              ),

              label:
              const Text(
                'Thử lại',
              ),
            ),
          ],
        ),
      ),
    );
  }
}