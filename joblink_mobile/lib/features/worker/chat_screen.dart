import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/chat_socket_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversation,
  });

  final ChatConversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final Map<String, DateTime>
  _memberReadAt = {};
  final ChatSocketService
  _chatSocketService = ChatSocketService();

  final Set<String> _typingUserIds = <String>{};
  final Set<String> _onlineUserIds = <String>{};

  Timer? _typingTimer;
  bool _typingSent = false;
  bool _presenceLoaded = false;

  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  List<ChatMessage> _messages = [];

  bool _loading = true;
  bool _sending = false;
  bool _uploadingFile = false;
  bool _socketConnected = false;

  String _currentUserId = '';

  ChatMessage? _replyingTo;

  ChatConversation get conversation =>
      widget.conversation;

  String _displayNameForUser(String userId) {
    for (final member in conversation.members) {
      if (member.userId == userId) {
        return member.displayName;
      }
    }

    return 'Ai đó';
  }

  String? get _typingStatusText {
    if (_typingUserIds.isEmpty) {
      return null;
    }

    final names = _typingUserIds
        .map(_displayNameForUser)
        .toList();

    if (names.length == 1) {
      return '${names.first} đang nhập...';
    }

    if (names.length == 2) {
      return '${names[0]} và ${names[1]} đang nhập...';
    }

    return '${names[0]}, ${names[1]} và ${names.length - 2} người khác đang nhập...';
  }


  String? get _presenceStatusText {
    if (!_presenceLoaded ||
        _currentUserId.isEmpty) {
      return null;
    }

    final otherMembers =
    conversation.members
        .where(
          (member) =>
      member.userId !=
          _currentUserId,
    )
        .toList();

    if (conversation.type == 'PRIVATE') {
      if (otherMembers.isEmpty) {
        return null;
      }

      final otherUserId =
          otherMembers.first.userId;

      return _onlineUserIds.contains(
        otherUserId,
      )
          ? 'Đang hoạt động'
          : 'Ngoại tuyến';
    }

    final onlineCount =
        otherMembers
            .where(
              (member) =>
              _onlineUserIds.contains(
                member.userId,
              ),
        )
            .length;

    if (onlineCount <= 0) {
      return null;
    }

    return '$onlineCount người đang hoạt động';
  }

  bool get _statusDotActive {
    if (!_socketConnected) {
      return false;
    }

    if (_typingStatusText != null) {
      return true;
    }

    if (conversation.type == 'PRIVATE' &&
        _presenceLoaded) {
      final otherMembers =
      conversation.members
          .where(
            (member) =>
        member.userId !=
            _currentUserId,
      )
          .toList();

      if (otherMembers.isEmpty) {
        return false;
      }

      return _onlineUserIds.contains(
        otherMembers.first.userId,
      );
    }

    return true;
  }

  void _handleTypingChanged(String value) {
    if (!_canSend || !_socketConnected) {
      return;
    }

    if (value.trim().isEmpty) {
      _stopTyping();
      return;
    }

    if (!_typingSent) {
      _chatSocketService.setTyping(
        conversationId: conversation.id,
        isTyping: true,
      );

      _typingSent = true;
    }

    _typingTimer?.cancel();

    _typingTimer = Timer(
      const Duration(milliseconds: 1200),
      _stopTyping,
    );
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    _typingTimer = null;

    if (!_typingSent) {
      return;
    }

    if (_socketConnected) {
      _chatSocketService.setTyping(
        conversationId: conversation.id,
        isTyping: false,
      );
    }

    _typingSent = false;
  }

  bool _isLastOwnMessage(
      int index,
      ) {
    for (
    var i = index + 1;
    i < _messages.length;
    i++
    ) {
      if (_messages[i].senderId ==
          _currentUserId) {
        return false;
      }
    }

    return true;
  }

  String? _getReceiptText(
      ChatMessage message,
      ) {
    final sentAt =
        message.sentAt;

    if (sentAt == null) {
      return null;
    }

    int readCount = 0;

    for (final entry
    in _memberReadAt.entries) {
      if (entry.key ==
          _currentUserId) {
        continue;
      }

      if (!entry.value
          .isBefore(sentAt)) {
        readCount++;
      }
    }

    if (conversation.type ==
        'PRIVATE') {
      return readCount > 0
          ? 'Đã xem'
          : 'Đã gửi';
    }

    return readCount > 0
        ? 'Đã xem bởi $readCount'
        : 'Đã gửi';
  }

  bool get _canSend {
    if (conversation.type != 'APPLICANT_GROUP') {
      return true;
    }

    for (final member in conversation.members) {
      if (member.userId == _currentUserId &&
          member.memberRole == 'OWNER') {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    for (final member
    in conversation.members) {
      final lastReadAt =
          member.lastReadAt;

      if (lastReadAt != null) {
        _memberReadAt[
        member.userId
        ] = lastReadAt;
      }
    }
    _load();
  }

  Future<void> _connectSocket() async {
    try {
      await _chatSocketService.connect(
        conversationId:
        conversation.id,

        onConnected: () {
          if (!mounted) return;

          setState(() {
            _socketConnected = true;
          });
        },

        onDisconnected: () {
          if (!mounted) return;

          setState(() {
            _socketConnected = false;
            _typingUserIds.clear();
            _onlineUserIds.clear();
            _presenceLoaded = false;
          });

          _typingSent = false;
          _typingTimer?.cancel();
          _typingTimer = null;
        },

        onPresenceSnapshot: (
            onlineUserIds,
            ) {
          if (!mounted) return;

          setState(() {
            _onlineUserIds
              ..clear()
              ..addAll(
                onlineUserIds,
              );

            _presenceLoaded = true;
          });
        },

        onPresence: (
            userId,
            isOnline,
            ) {
          if (!mounted) return;

          setState(() {
            if (isOnline) {
              _onlineUserIds.add(
                userId,
              );
            } else {
              _onlineUserIds.remove(
                userId,
              );
              _typingUserIds.remove(
                userId,
              );
            }

            _presenceLoaded = true;
          });
        },

        onTyping: (
            userId,
            isTyping,
            ) {
          if (!mounted ||
              userId == _currentUserId) {
            return;
          }

          setState(() {
            if (isTyping) {
              _typingUserIds.add(userId);
            } else {
              _typingUserIds.remove(userId);
            }
          });
        },

        onConversationRead: (
            userId,
            lastReadAt,
            ) {
          if (!mounted) return;

          if (userId ==
              _currentUserId) {
            return;
          }

          setState(() {
            _memberReadAt[userId] =
                lastReadAt;
          });
        },
        onMessage: (message) {
          if (!mounted) return;

          final exists =
          _messages.any(
                (item) =>
            item.id == message.id,
          );

          if (exists) {
            return;
          }

          setState(() {
            _messages.add(message);
            _typingUserIds.remove(
              message.senderId,
            );
          });

          if (message.senderId !=
              _currentUserId) {
            _chatService
                .markConversationRead(
              conversation.id,
            );
          }

          WidgetsBinding.instance
              .addPostFrameCallback(
                (_) {
              _scrollToBottom();
            },
          );
        },

        onError: (error) {
          debugPrint(
            'Chat Socket error: $error',
          );
        },
      );
    } catch (error) {
      debugPrint(
        'Không thể kết nối Socket.IO: $error',
      );

      if (!mounted) return;

      setState(() {
        _socketConnected = false;
      });
    }
  }

  Future<void> _load() async {
    try {
      final userId =
      await _chatService.getCurrentUserId();

      final messages =
      await _chatService.getMessages(
        conversation.id,
      );

      await _chatService
          .markConversationRead(
        conversation.id,
      );

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
        _messages = messages;
      });

      await _connectSocket();

      WidgetsBinding.instance.addPostFrameCallback(
            (_) {
          _scrollToBottom();
        },
      );
    } catch (_) {
      if (!mounted) return;

      _showChatMessage(
        'Không thể tải tin nhắn',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text =
    _messageController.text.trim();

    if (text.isEmpty ||
        _sending ||
        !_canSend) {
      return;
    }

    if (!_socketConnected) {
      _showChatMessage(
        'Đang mất kết nối realtime. '
            'Vui lòng thử lại.',
        error: true,
      );

      return;
    }

    final replyId =
        _replyingTo?.id;

    setState(() {
      _sending = true;
    });

    _stopTyping();

    try {
      await _chatSocketService.sendText(
        conversationId:
        conversation.id,
        content: text,
        replyToId: replyId,
      );

      if (!mounted) return;

      _messageController.clear();

      setState(() {
        _replyingTo = null;
      });

    } catch (error) {
      if (!mounted) return;

      _showChatMessage(
        error
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ==============================
  // ATTACHMENT
  // ==============================

  Future<void> _showAttachmentMenu() async {
    if (_uploadingFile || !_canSend) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Gửi đính kèm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF2563EB,
                      ).withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                      BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: const Text(
                    'Hình ảnh',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Chọn ảnh từ thiết bị',
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    _pickAndUpload(
                      FileType.image,
                    );
                  },
                ),

                const SizedBox(height: 4),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF7C3AED,
                      ).withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                      BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.attach_file_rounded,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  title: const Text(
                    'Tệp',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'PDF, tài liệu hoặc tệp khác',
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    _pickAndUpload(
                      FileType.any,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(
      FileType type,
      ) async {
    try {
      final pickedFile =
      await FilePicker.pickFile(
        type: type,
      );

      if (pickedFile == null) {
        return;
      }

      final filePath = pickedFile.path;

      if (filePath == null) {
        _showChatMessage(
          'Không thể đọc tệp đã chọn.',
          error: true,
        );

        return;
      }

      final fileSize =
          pickedFile.lengthSync() ??
              await pickedFile.length();

      const maxFileSize =
          10 * 1024 * 1024;

      if (fileSize == null) {
        _showChatMessage(
          'Không thể xác định kích thước tệp.',
          error: true,
        );

        return;
      }

      if (fileSize > maxFileSize) {
        _showChatMessage(
          'Tệp không được vượt quá 10 MB.',
          error: true,
        );

        return;
      }

      setState(() {
        _uploadingFile = true;
      });

      await _chatService.uploadFile(
        conversationId:
        conversation.id,
        filePath: filePath,
        fileName: pickedFile.name,
      );

      if (!mounted) return;

    } on DioException catch (e) {
      if (!mounted) return;

      _showChatMessage(
        _dioErrorMessage(
          e,
          fallback:
          'Không thể gửi tệp',
        ),
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showChatMessage(
        'Không thể gửi tệp: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingFile = false;
        });
      }
    }
  }

  Future<void> _openAttachment(
      String fileUrl,
      ) async {
    try {
      final resolvedUrl =
      _chatService.resolveFileUrl(
        fileUrl,
      );

      final uri = Uri.parse(
        resolvedUrl,
      );

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showChatMessage(
          'Không thể mở tệp đính kèm.',
          error: true,
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showChatMessage(
        'Không thể mở tệp đính kèm.',
        error: true,
      );
    }
  }

  String _dioErrorMessage(
      DioException error, {
        required String fallback,
      }) {
    final data = error.response?.data;

    if (data is Map &&
        data['message'] != null) {
      final rawMessage = data['message'];

      if (rawMessage is List) {
        return rawMessage.join('\n');
      }

      return rawMessage.toString();
    }

    return fallback;
  }

  void _showChatMessage(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          error ? Colors.red.shade700 : null,
          content: Text(message),
        ),
      );
  }

  // ==============================
  // UI HELPERS
  // ==============================

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration:
      const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  ChatMessage? _findReplyMessage(
      String? replyToId,
      ) {
    if (replyToId == null ||
        replyToId.isEmpty) {
      return null;
    }

    for (final message in _messages) {
      if (message.id == replyToId) {
        return message;
      }
    }

    return null;
  }

  IconData _conversationIcon() {
    switch (conversation.type) {
      case 'APPLICANT_GROUP':
        return Icons.groups_rounded;

      case 'SELECTED_GROUP':
        return Icons.group_work_rounded;

      default:
        return Icons.person_rounded;
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();

    if (_typingSent) {
      _chatSocketService.setTyping(
        conversationId: conversation.id,
        isTyping: false,
      );
    }

    _chatSocketService.disconnect();

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,

        title: Row(
          children: [
            Container(
              width: 41,
              height: 41,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF2563EB,
                ).withValues(
                  alpha: 0.09,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _conversationIcon(),
                color:
                const Color(0xFF2563EB),
                size: 22,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Text(
                    conversation.displayName,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _statusDotActive
                              ? Colors.green
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Flexible(
                        child: Text(
                          !_socketConnected
                              ? 'Đang kết nối...'
                              : (_typingStatusText ??
                              _presenceStatusText ??
                              conversation.subtitle),
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                            Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (conversation.jobTitle !=
                      null &&
                      conversation
                          .jobTitle!
                          .isNotEmpty) ...[
                    const SizedBox(height: 1),

                    Text(
                      conversation.jobTitle!,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color:
                        Color(0xFF2563EB),
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          if (!_canSend && !_loading)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              color:
              const Color(0xFFFFF7ED),
              child: const Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 17,
                    color:
                    Color(0xFFEA580C),
                  ),

                  SizedBox(width: 6),

                  Flexible(
                    child: Text(
                      'Nhóm ứng viên chỉ nhận thông báo từ nhà tuyển dụng.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF9A3412),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : _messages.isEmpty
                ? _buildEmptyMessages()
                : ListView.builder(
              controller:
              _scrollController,
              padding:
              const EdgeInsets
                  .fromLTRB(
                16,
                18,
                16,
                18,
              ),
              itemCount:
              _messages.length,
              itemBuilder:
                  (context, index) {
                final message =
                _messages[index];

                final replyMessage =
                _findReplyMessage(
                  message.replyToId,
                );

                final mine =
                    message.senderId ==
                        _currentUserId;

                final receiptText =
                mine &&
                    _isLastOwnMessage(
                      index,
                    )
                    ? _getReceiptText(
                  message,
                )
                    : null;
                return _MessageBubble(
                  message: message,
                  replyMessage:
                  replyMessage,

                  mine: mine,

                  receiptText:
                  receiptText,

                  showSenderName:
                  conversation.type !=
                      'PRIVATE',

                  attachmentUrl:
                  message.fileUrl ==
                      null
                      ? null
                      : _chatService
                      .resolveFileUrl(
                    message
                        .fileUrl!,
                  ),

                  onOpenAttachment:
                  message.fileUrl ==
                      null
                      ? null
                      : () {
                    _openAttachment(
                      message
                          .fileUrl!,
                    );
                  },

                  onReply: _canSend
                      ? () {
                    setState(() {
                      _replyingTo =
                          message;
                    });
                  }
                      : null,
                );
              },
            ),
          ),

          if (_canSend)
            _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color:
              const Color(0xFF2563EB)
                  .withValues(
                alpha: 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .chat_bubble_outline_rounded,
              size: 34,
              color:
              Color(0xFF2563EB),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Chưa có tin nhắn',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            conversation.type ==
                'APPLICANT_GROUP'
                ? 'Thông báo từ nhà tuyển dụng sẽ xuất hiện tại đây.'
                : 'Hãy bắt đầu cuộc trò chuyện.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.04,
              ),
              blurRadius: 12,
              offset: const Offset(
                0,
                -4,
              ),
            ),
          ],
        ),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            if (_replyingTo != null)
              _buildReplyPreview(),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Đính kèm',
                  onPressed: _uploadingFile
                      ? null
                      : _showAttachmentMenu,

                  icon: _uploadingFile
                      ? const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons
                        .add_circle_outline_rounded,
                  ),

                  color:
                  const Color(0xFF2563EB),
                ),

                Expanded(
                  child: TextField(
                    controller:
                    _messageController,
                    onChanged:
                    _handleTypingChanged,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization:
                    TextCapitalization
                        .sentences,
                    textInputAction:
                    TextInputAction.newline,

                    decoration:
                    InputDecoration(
                      hintText:
                      'Nhập tin nhắn...',

                      filled: true,

                      fillColor:
                      const Color(
                        0xFFF1F5F9,
                      ),

                      contentPadding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),

                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          22,
                        ),
                        borderSide:
                        BorderSide.none,
                      ),

                      enabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          22,
                        ),
                        borderSide:
                        BorderSide.none,
                      ),

                      focusedBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          22,
                        ),
                        borderSide:
                        const BorderSide(
                          color: Color(
                            0xFFBFDBFE,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  width: 45,
                  height: 45,
                  decoration:
                  const BoxDecoration(
                    color:
                    Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed:
                    _sending
                        ? null
                        : _send,

                    icon: _sending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons
                          .send_rounded,
                      color:
                      Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final reply = _replyingTo!;

    String preview =
        reply.content ?? 'Tin nhắn';

    if (reply.messageType == 'IMAGE') {
      preview = '📷 Hình ảnh';
    } else if (reply.messageType ==
        'FILE') {
      preview = '📎 Tệp đính kèm';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        4,
        8,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFEFF6FF),
        borderRadius:
        BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(
            color:
            Color(0xFF2563EB),
            width: 3,
          ),
        ),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  reply.senderId ==
                      _currentUserId
                      ? 'Trả lời chính bạn'
                      : 'Trả lời ${reply.senderName}',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                    Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  preview,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// MESSAGE BUBBLE
// ========================================

class _MessageBubble
    extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.showSenderName,
    required this.replyMessage,
    required this.attachmentUrl,
    required this.onOpenAttachment,
    required this.onReply,
    required this.receiptText,
  });

  final ChatMessage message;
  final ChatMessage? replyMessage;

  final bool mine;
  final bool showSenderName;

  final String? attachmentUrl;
  final String? receiptText;

  final VoidCallback?
  onOpenAttachment;

  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: GestureDetector(
        onLongPress: onReply,

        child: Container(
          constraints:
          const BoxConstraints(
            maxWidth: 290,
          ),

          margin:
          const EdgeInsets.only(
            bottom: 9,
          ),

          padding:
          const EdgeInsets.fromLTRB(
            13,
            9,
            13,
            7,
          ),

          decoration: BoxDecoration(
            color: mine
                ? const Color(
              0xFF2563EB,
            )
                : Colors.white,

            borderRadius:
            BorderRadius.only(
              topLeft:
              const Radius.circular(
                17,
              ),
              topRight:
              const Radius.circular(
                17,
              ),
              bottomLeft:
              Radius.circular(
                mine ? 17 : 5,
              ),
              bottomRight:
              Radius.circular(
                mine ? 5 : 17,
              ),
            ),

            boxShadow: mine
                ? null
                : [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.035,
                ),
                blurRadius: 7,
                offset:
                const Offset(
                  0,
                  2,
                ),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!mine &&
                  showSenderName) ...[
                Text(
                  message.senderName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF2563EB),
                  ),
                ),

                const SizedBox(height: 5),
              ],

              if (message.replyToId !=
                  null)
                _ReplyInsideBubble(
                  replyMessage:
                  replyMessage,
                  mine: mine,
                ),

              if (message.messageType ==
                  'IMAGE' &&
                  attachmentUrl != null)
                _buildImageAttachment(),

              if (message.messageType ==
                  'FILE' &&
                  attachmentUrl != null)
                _buildFileAttachment(),

              if (message.messageType ==
                  'TEXT')
                Text(
                  message.content ?? '',
                  style: TextStyle(
                    color: mine
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),

              if ((message.messageType ==
                  'IMAGE' ||
                  message.messageType ==
                      'FILE') &&
                  attachmentUrl == null)
                Text(
                  message.messageType ==
                      'IMAGE'
                      ? '📷 Hình ảnh'
                      : '📎 Tệp đính kèm',
                  style: TextStyle(
                    color: mine
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),

              const SizedBox(height: 5),

              Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  if (message.replyToId !=
                      null) ...[
                    Icon(
                      Icons.reply_rounded,
                      size: 11,
                      color: mine
                          ? Colors.white60
                          : Colors
                          .grey.shade400,
                    ),
                    const SizedBox(width: 3),
                  ],

                  Text(
                    message.timeText,
                    style: TextStyle(
                      fontSize: 10,
                      color: mine
                          ? Colors.white70
                          : Colors.grey.shade500,
                    ),
                  ),

                  if (receiptText != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      '· $receiptText',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: receiptText == 'Đã xem'
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: mine
                            ? Colors.white70
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageAttachment() {
    return GestureDetector(
      onTap: onOpenAttachment,
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(12),
        child: Image.network(
          attachmentUrl!,
          width: 220,
          height: 180,
          fit: BoxFit.cover,

          loadingBuilder: (
              context,
              child,
              progress,
              ) {
            if (progress == null) {
              return child;
            }

            return Container(
              width: 220,
              height: 180,
              alignment:
              Alignment.center,
              color:
              Colors.grey.shade200,
              child:
              const CircularProgressIndicator(),
            );
          },

          errorBuilder: (
              context,
              error,
              stackTrace,
              ) {
            return Container(
              width: 220,
              height: 130,
              alignment:
              Alignment.center,
              color:
              Colors.grey.shade200,
              child: const Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .broken_image_outlined,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Không tải được ảnh',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFileAttachment() {
    return InkWell(
      onTap: onOpenAttachment,
      borderRadius:
      BorderRadius.circular(11),
      child: Container(
        padding:
        const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mine
              ? Colors.white.withValues(
            alpha: 0.14,
          )
              : const Color(
            0xFFF1F5F9,
          ),
          borderRadius:
          BorderRadius.circular(11),
        ),

        child: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .insert_drive_file_outlined,
              color: mine
                  ? Colors.white
                  : const Color(
                0xFF7C3AED,
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                'Mở tệp đính kèm',
                style: TextStyle(
                  color: mine
                      ? Colors.white
                      : Colors.black87,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 6),

            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: mine
                  ? Colors.white70
                  : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// REPLY INSIDE MESSAGE
// ========================================

class _ReplyInsideBubble
    extends StatelessWidget {
  const _ReplyInsideBubble({
    required this.replyMessage,
    required this.mine,
  });

  final ChatMessage? replyMessage;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    String name =
        'Tin nhắn đã trả lời';

    String content =
        'Nội dung tin nhắn';

    if (replyMessage != null) {
      name = replyMessage!.senderName;

      switch (replyMessage!.messageType) {
        case 'IMAGE':
          content = '📷 Hình ảnh';
          break;

        case 'FILE':
          content = '📎 Tệp đính kèm';
          break;

        default:
          content =
              replyMessage!.content ??
                  'Tin nhắn';
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 7,
      ),
      padding: const EdgeInsets.all(8),

      decoration: BoxDecoration(
        color: mine
            ? Colors.white.withValues(
          alpha: 0.14,
        )
            : const Color(
          0xFFF1F5F9,
        ),

        borderRadius:
        BorderRadius.circular(9),

        border: Border(
          left: BorderSide(
            width: 3,
            color: mine
                ? Colors.white70
                : const Color(
              0xFF2563EB,
            ),
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight:
              FontWeight.w700,
              color: mine
                  ? Colors.white
                  : const Color(
                0xFF2563EB,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            content,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: mine
                  ? Colors.white70
                  : Colors
                  .grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
