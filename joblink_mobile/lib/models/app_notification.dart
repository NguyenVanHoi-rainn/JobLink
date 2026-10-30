class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
  });

  final String id;
  final String userId;
  final String title;
  final String content;
  final String type;
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      content: content,
      type: type,
      referenceType: referenceType,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(
      Map<String, dynamic> json,
      ) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Thông báo',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      referenceType:
      json['referenceType']?.toString(),
      referenceId:
      json['referenceId']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(
        json['createdAt'].toString(),
      ),
    );
  }

  String get timeText {
    final value = createdAt?.toLocal();

    if (value == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(value);

    if (!difference.isNegative) {
      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      }
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} · $hour:$minute';
  }
}
