class Message {
  /// Уникальный идентификатор в формате UUID v4.
  final String id;

  /// Тип сообщения - определяет источник и обработку.
  final MessageType type;

  /// Уровень критичности - влияет на стилизацию и приоритет отображения.
  final MessageSeverity severity;

  /// Краткий заголовок (обязателен для error и notification).
  final String title;

  /// Основное содержимое сообщения.
  final String body;

  /// Код ошибки или категории сообщения (например, ORDER_NOT_FOUND).
  final String? code;

  /// Время создания сообщения.
  final DateTime timestamp;

  /// Код языка сообщения. По умолчанию 'ru' - поддерживается только русский.
  final String language;

  /// Дополнительный контекст: userId, orderId, endpoint и т.п.
  final Map<String, dynamic> metadata;

  Message({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    this.code,
    required this.timestamp,
    this.language = 'ru',
    this.metadata = const {},
  });

  /// Короткий идентификатор для отображения в UI и логах - первые 8 символов id.
  String get displayId => id.length >= 8 ? id.substring(0, 8) : id;

  /// Сериализация в JSON. timestamp кодируется как ISO 8601, enum'ы - как строки.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'severity': severity.value,
      'title': title,
      'body': body,
      if (code != null) 'code': code,
      'timestamp': timestamp.toIso8601String(),
      'language': language,
      'metadata': metadata,
    };
  }

  /// Десериализация из JSON. Неизвестные значения enum'ов приводят к ArgumentError.
  factory Message.fromJson(Map<String, dynamic> json) {
    final timestampRaw = json['timestamp'];
    final parsedTimestamp = timestampRaw is DateTime
        ? timestampRaw
        : DateTime.parse(timestampRaw.toString());

    final metadataRaw = json['metadata'];
    final parsedMetadata = metadataRaw is Map
        ? Map<String, dynamic>.from(metadataRaw)
        : <String, dynamic>{};

    return Message(
      id: json['id']?.toString() ?? '',
      type: MessageType.fromValue(json['type']?.toString() ?? ''),
      severity: MessageSeverity.fromValue(json['severity']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      code: json['code']?.toString(),
      timestamp: parsedTimestamp,
      language: json['language']?.toString() ?? 'ru',
      metadata: parsedMetadata,
    );
  }

  /// Возвращает копию сообщения с заменой указанных полей.
  ///
  /// Чтобы явно сбросить опциональный code в null, используйте
  /// clearCode: true - иначе текущее значение сохраняется.
  Message copyWith({
    String? id,
    MessageType? type,
    MessageSeverity? severity,
    String? title,
    String? body,
    String? code,
    bool clearCode = false,
    DateTime? timestamp,
    String? language,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      body: body ?? this.body,
      code: clearCode ? null : (code ?? this.code),
      timestamp: timestamp ?? this.timestamp,
      language: language ?? this.language,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Тип сообщения - определяет, откуда оно пришло и как обрабатывается.
enum MessageType {
  apiResponse('api_response'),
  error('error'),
  notification('notification'),
  supportChat('support_chat'),
  aiGenerated('ai_generated');

  final String value;
  const MessageType(this.value);

  /// Преобразует строковое значение в enum. Бросает ArgumentError, если значение неизвестно.
  static MessageType fromValue(String value) {
    for (final t in MessageType.values) {
      if (t.value == value) return t;
    }
    throw ArgumentError('Неизвестный MessageType: "$value"');
  }
}

/// Уровень критичности сообщения - влияет на стилизацию и приоритет.
enum MessageSeverity {
  info('info'),
  warning('warning'),
  error('error'),
  critical('critical');

  final String value;
  const MessageSeverity(this.value);

  /// Преобразует строковое значение в enum. Бросает ArgumentError, если значение неизвестно.
  static MessageSeverity fromValue(String value) {
    for (final s in MessageSeverity.values) {
      if (s.value == value) return s;
    }
    throw ArgumentError('Неизвестный MessageSeverity: "$value"');
  }
}
