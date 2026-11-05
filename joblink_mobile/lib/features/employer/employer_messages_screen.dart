import 'package:flutter/material.dart';

import '../../models/chat_conversation.dart';
import '../../services/chat_service.dart';
import '../worker/chat_screen.dart';

class EmployerMessagesScreen extends StatefulWidget {
  const EmployerMessagesScreen({
    super.key,
    this.onUnreadChanged,
  });

  final ValueChanged<int>? onUnreadChanged;

  @override
  State<EmployerMessagesScreen> createState() =>
      _EmployerMessagesScreenState();
}

class _EmployerMessagesScreenState
    extends State<EmployerMessagesScreen> {
  final ChatService _chatService = ChatService();

  List<ChatConversation> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _chatService.getConversations();

      if (!mounted) return;

      setState(() {
        _conversations = data;
      });

      final totalUnread = data.fold<int>(
        0,
            (total, conversation) => total + conversation.unreadCount,
      );

      widget.onUnreadChanged?.call(totalUnread);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Không thể tải cuộc trò chuyện';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tin nhắn ứng viên',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Trao đổi với ứng viên và các nhóm làm việc.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(_error!),
                  ),
                ),
              )
            else if (_conversations.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyMessages(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  sliver: SliverList.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];

                      return _ConversationCard(
                        conversation: conversation,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversation: conversation,
                              ),
                            ),
                          );

                          await _load();
                        },
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = conversation.lastMessage;

    String preview = 'Chưa có tin nhắn';

    if (last != null) {
      if (last.messageType == 'TEXT') {
        preview = last.content ?? 'Tin nhắn';
      } else if (last.messageType == 'IMAGE') {
        preview = '📷 Hình ảnh';
      } else {
        preview = '📎 Tệp đính kèm';
      }
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(conversation.type),
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.displayName, // Sử dụng chuẩn displayName giống Worker
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (last != null)
                          Text(
                            last.timeText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      conversation.typeText,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              if (conversation.unreadCount > 0)
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 23,
                    minHeight: 23,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    conversation.unreadCount > 99
                        ? '99+'
                        : conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'APPLICANT_GROUP':
        return Icons.groups_rounded;
      case 'SELECTED_GROUP':
        return Icons.group_work_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa có tin nhắn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các cuộc trò chuyện với ứng viên sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}