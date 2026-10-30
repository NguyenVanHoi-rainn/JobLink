class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;

  final String? content;
  final String messageType;
  final String? fileUrl;
  final String? replyToId;

  final DateTime? sentAt;

  final String senderName;
  final String? senderRole;
  final String? senderCompanyName;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    required this.messageType,
    this.fileUrl,
    this.replyToId,
    this.sentAt,
    required this.senderName,
    this.senderRole,
    this.senderCompanyName,
  });

  factory ChatMessage.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawSender =
    json['sender'];

    String senderName =
        'Người dùng';

    String? senderRole;
    String? senderCompanyName;

    if (rawSender is Map) {
      senderName =
          rawSender['displayName']
              ?.toString() ??
              'Người dùng';

      senderRole =
          rawSender['role']
              ?.toString();

      senderCompanyName =
          rawSender['companyName']
              ?.toString();
    }

    return ChatMessage(
      id:
      json['id']?.toString() ??
          '',
      conversationId:
      json['conversationId']
          ?.toString() ??
          '',
      senderId:
      json['senderId']
          ?.toString() ??
          '',
      content:
      json['content']
          ?.toString(),
      messageType:
      json['messageType']
          ?.toString() ??
          'TEXT',
      fileUrl:
      json['fileUrl']
          ?.toString(),
      replyToId:
      json['replyToId']
          ?.toString(),

      sentAt:
      json['sentAt'] == null
          ? null
          : DateTime.tryParse(
        json['sentAt']
            .toString(),
      ),

      senderName: senderName,
      senderRole: senderRole,
      senderCompanyName:
      senderCompanyName,
    );
  }

  String get timeText {
    if (sentAt == null) {
      return '';
    }

    final time =
    sentAt!.toLocal();

    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}