import 'chat_message.dart';

class ConversationMember {
  final String userId;
  final String memberRole;
  final DateTime? lastReadAt;
  final String displayName;
  final String? role;
  final String? companyName;

  const ConversationMember({
    required this.userId,
    required this.memberRole,
    required this.displayName,
    this.role,
    this.companyName,
    this.lastReadAt,
  });

  factory ConversationMember.fromJson(
      Map<String, dynamic> json,
      ) {
    return ConversationMember(
      userId:
      json['userId']?.toString() ?? '',

      memberRole:
      json['memberRole']?.toString() ??
          'MEMBER',

      displayName:
      json['displayName']?.toString() ??
          'Người dùng',

      role:
      json['role']?.toString(),

      companyName:
      json['companyName']?.toString(),

      lastReadAt:
      json['lastReadAt'] == null
          ? null
          : DateTime.tryParse(
        json['lastReadAt']
            .toString(),
      ),
    );
  }
}

class ChatConversation {
  final String id;
  final String type;

  final String? name;
  final String? jobId;
  final String? createdBy;

  final DateTime? createdAt;

  final int unreadCount;

  // Backend mới trả thêm
  final String displayName;
  final String subtitle;
  final String? jobTitle;

  final List<ConversationMember> members;
  final ChatMessage? lastMessage;

  const ChatConversation({
    required this.id,
    required this.type,
    this.name,
    this.jobId,
    this.createdBy,
    this.createdAt,

    required this.unreadCount,
    required this.displayName,
    required this.subtitle,
    this.jobTitle,

    this.members = const [],
    this.lastMessage,
  });

  factory ChatConversation.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawMembers = json['members'];

    final members =
    <ConversationMember>[];

    if (rawMembers is List) {
      for (final item in rawMembers) {
        if (item is Map) {
          members.add(
            ConversationMember.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          );
        }
      }
    }

    ChatMessage? lastMessage;

    final rawLastMessage =
    json['lastMessage'];

    if (rawLastMessage is Map) {
      lastMessage =
          ChatMessage.fromJson(
            Map<String, dynamic>.from(
              rawLastMessage,
            ),
          );
    }

    return ChatConversation(
      id:
      json['id']?.toString() ?? '',

      type:
      json['type']?.toString() ??
          'PRIVATE',

      name:
      json['name']?.toString(),

      jobId:
      json['jobId']?.toString(),

      createdBy:
      json['createdBy']?.toString(),

      createdAt:
      json['createdAt'] == null
          ? null
          : DateTime.tryParse(
        json['createdAt']
            .toString(),
      ),

      // 3 field bạn đang hỏi chính là ở đây
      displayName:
      json['displayName']
          ?.toString() ??
          'Cuộc trò chuyện',

      subtitle:
      json['subtitle']
          ?.toString() ??
          'Tin nhắn',

      jobTitle:
      json['jobTitle']
          ?.toString(),

      unreadCount:
      int.tryParse(
        json['unreadCount']
            ?.toString() ??
            '0',
      ) ??
          0,

      members: members,

      lastMessage: lastMessage,
    );
  }

  String get typeText {
    switch (type) {
      case 'PRIVATE':
        return 'Tin nhắn riêng';

      case 'APPLICANT_GROUP':
        return 'Nhóm ứng viên';

      case 'SELECTED_GROUP':
        return 'Nhóm được chọn';

      default:
        return type;
    }
  }
}