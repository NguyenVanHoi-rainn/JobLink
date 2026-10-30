import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../models/chat_conversation.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';

import '../worker/chat_screen.dart';
import 'employer_application_detail_screen.dart';

class EmployerNotificationsScreen
    extends StatefulWidget {
  const EmployerNotificationsScreen({
    super.key,
  });

  @override
  State<EmployerNotificationsScreen>
  createState() =>
      _EmployerNotificationsScreenState();
}

class _EmployerNotificationsScreenState
    extends State<EmployerNotificationsScreen> {
  static const Color _primary =
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
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            _dioErrorMessage(
              e,
              fallback:
              'Không thể tải thông báo',
            );
      });
    } catch (e) {
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
    } catch (e) {
      _showMessage(
        'Không thể đánh dấu thông báo',
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

  Future<void>
  _handleNotificationTap(
      AppNotification notification,
      ) async {
    var current =
        notification;

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
      } catch (e) {
        _showMessage(
          'Không thể đánh dấu đã đọc',
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

    if (referenceType ==
        'APPLICATION') {
      await _openApplication(
        referenceId,
      );

      return;
    }

    if (referenceType ==
        'CONVERSATION') {
      await _openConversation(
        referenceId,
      );
    }
  }

  Future<void> _openApplication(
      String applicationId,
      ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EmployerApplicationDetailScreen(
              applicationId:
              applicationId,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _load();
  }

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
          'Cuộc trò chuyện không còn khả dụng',
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
    } catch (e) {
      _showMessage(
        'Không thể mở cuộc trò chuyện',
        error: true,
      );
    }
  }

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

  IconData _iconForType(
      String type,
      ) {
    switch (type) {
      case 'APPLICATION_CREATED':
        return Icons
            .person_add_alt_1_rounded;

      case 'APPLICATION_WITHDRAWN':
        return Icons
            .person_remove_alt_1_rounded;

      case 'CHAT_MESSAGE':
        return Icons
            .chat_bubble_outline_rounded;

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

  Color _colorForType(
      String type,
      ) {
    switch (type) {
      case 'APPLICATION_CREATED':
        return const Color(
          0xFF16A34A,
        );

      case 'APPLICATION_WITHDRAWN':
        return const Color(
          0xFFF59E0B,
        );

      case 'CHAT_MESSAGE':
        return const Color(
          0xFF2563EB,
        );

      case 'EMPLOYER_VERIFICATION':
      case 'VERIFICATION':
        return const Color(
          0xFF7C3AED,
        );

      case 'REPORT':
        return const Color(
          0xFFDC2626,
        );

      default:
        return const Color(
          0xFF475569,
        );
    }
  }

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
              width: 17,
              height: 17,
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
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .cloud_off_rounded,
                size: 48,
                color:
                Colors.redAccent,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _error!,
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(
                height: 14,
              ),
              OutlinedButton.icon(
                onPressed: _load,
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

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(
              height: 130,
            ),
            Icon(
              Icons
                  .notifications_none_rounded,
              size: 64,
              color:
              Colors.grey.shade400,
            ),
            const SizedBox(
              height: 14,
            ),
            const Text(
              'Chưa có thông báo',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'Thông báo ứng viên và tin nhắn sẽ xuất hiện tại đây.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
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
            (context, index) {
          final notification =
          _notifications[index];

          final color =
          _colorForType(
            notification.type,
          );

          return Material(
            color: Colors.white,
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
                  border: Border.all(
                    color: notification
                        .isRead
                        ? Colors
                        .grey
                        .shade200
                        : _primary
                        .withValues(
                      alpha:
                      0.20,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration:
                      BoxDecoration(
                        color:
                        color.withValues(
                          alpha:
                          0.10,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
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
                      ),
                    ),
                    const SizedBox(
                      width: 13,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child:
                                Text(
                                  notification
                                      .title,
                                  style:
                                  TextStyle(
                                    fontWeight:
                                    notification
                                        .isRead
                                        ? FontWeight
                                        .w600
                                        : FontWeight
                                        .w800,
                                  ),
                                ),
                              ),
                              if (!notification
                                  .isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration:
                                  const BoxDecoration(
                                    color:
                                    _primary,
                                    shape: BoxShape
                                        .circle,
                                  ),
                                ),
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
                              height:
                              1.35,
                            ),
                          ),
                          if (notification
                              .timeText
                              .isNotEmpty) ...[
                            const SizedBox(
                              height: 7,
                            ),
                            Text(
                              notification
                                  .timeText,
                              style:
                              TextStyle(
                                fontSize:
                                11,
                                color: Colors
                                    .grey
                                    .shade500,
                              ),
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
}