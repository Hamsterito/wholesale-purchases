class SupportMessage {
  final String id;
  final int chatId;
  final int userId;
  final String senderRole;
  final int? senderUserId;
  final String category;
  final String subject;
  final String text;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.senderRole,
    required this.senderUserId,
    required this.category,
    required this.subject,
    required this.text,
    required this.createdAt,
  });

  bool get isFromModerator => senderRole == 'moderator';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value.toString());
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed ?? DateTime.now();
    }

    final senderRole = json['senderRole']?.toString().trim().toLowerCase();

    return SupportMessage(
      id: json['id']?.toString() ?? '',
      chatId: parseInt(json['chatId']),
      userId: parseInt(json['userId']),
      senderRole: senderRole == 'moderator' ? 'moderator' : 'user',
      senderUserId: parseNullableInt(json['senderUserId']),
      category: json['category']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
    );
  }
}

class SupportChat {
  final int id;
  final int userId;
  final String status;
  final String category;
  final String subject;
  final String closeReason;
  final DateTime createdAt;
  final DateTime? closedAt;
  final int? closedByUserId;

  SupportChat({
    required this.id,
    required this.userId,
    required this.status,
    required this.category,
    required this.subject,
    required this.closeReason,
    required this.createdAt,
    required this.closedAt,
    required this.closedByUserId,
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  factory SupportChat.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value.toString());
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.tryParse(value.toString());
    }

    final statusRaw = json['status']?.toString().trim().toLowerCase();
    final status = statusRaw == 'closed' ? 'closed' : 'open';

    return SupportChat(
      id: parseInt(json['id']),
      userId: parseInt(json['userId']),
      status: status,
      category: json['category']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      closeReason: json['closeReason']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      closedAt: parseNullableDate(json['closedAt']),
      closedByUserId: parseNullableInt(json['closedByUserId']),
    );
  }
}

class SupportChatThread {
  final SupportChat? chat;
  final List<SupportMessage> messages;

  SupportChatThread({required this.chat, required this.messages});

  bool get hasChat => chat != null;

  factory SupportChatThread.fromJson(Map<String, dynamic> json) {
    final chatJson = json['chat'];
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
              .map(
                (item) => SupportMessage.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
        : <SupportMessage>[];

    return SupportChatThread(
      chat: chatJson is Map
          ? SupportChat.fromJson(Map<String, dynamic>.from(chatJson))
          : null,
      messages: messages,
    );
  }
}

class SupportChatSummary {
  final int chatId;
  final int userId;
  final String status;
  final String category;
  final String subject;
  final String userName;
  final String userEmail;
  final String userRole;
  final String supplierName;
  final String lastMessage;
  final String lastSenderRole;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final DateTime? closedAt;
  final String closeReason;

  SupportChatSummary({
    required this.chatId,
    required this.userId,
    required this.status,
    required this.category,
    required this.subject,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.supplierName,
    required this.lastMessage,
    required this.lastSenderRole,
    required this.createdAt,
    required this.lastMessageAt,
    required this.closedAt,
    required this.closeReason,
  });

  bool get isOpen => status == 'open';
  bool get lastMessageFromModerator => lastSenderRole == 'moderator';

  factory SupportChatSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.tryParse(value.toString());
    }

    final senderRole = json['lastSenderRole']?.toString().trim().toLowerCase();
    final statusRaw = json['status']?.toString().trim().toLowerCase();
    final status = statusRaw == 'closed' ? 'closed' : 'open';

    return SupportChatSummary(
      chatId: parseInt(json['chatId']),
      userId: parseInt(json['userId']),
      status: status,
      category: json['category']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      userRole: json['userRole']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastSenderRole: senderRole == 'moderator' ? 'moderator' : 'user',
      createdAt: parseDate(json['createdAt']),
      lastMessageAt: parseDate(json['lastMessageAt']),
      closedAt: parseNullableDate(json['closedAt']),
      closeReason: json['closeReason']?.toString() ?? '',
    );
  }
}
