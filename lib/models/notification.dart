/// Модель данных для счётчиков уведомлений, получаемых с API.
class NotificationCounts {
  /// Количество непрочитанных сообщений поддержки.
  final int unreadMessages;

  /// Количество заказов, ожидающих действия пользователя.
  final int pendingOrders;

  /// Количество товаров, ожидающих отзыва от покупателя.
  final int pendingReviews;

  /// Количество товаров, ожидающих модерации (для поставщиков и модераторов).
  final int pendingModerations;

  /// Количество доставленных заказов, ожидающих подтверждения получения покупателем.
  final int deliveredOrders;

  /// Временная метка последнего обновления данных на сервере.
  final DateTime? timestamp;

  const NotificationCounts({
    required this.unreadMessages,
    required this.pendingOrders,
    required this.pendingReviews,
    required this.pendingModerations,
    this.deliveredOrders = 0,
    this.timestamp,
  });

  /// Создаёт экземпляр из JSON-ответа API.
  factory NotificationCounts.fromJson(Map<String, dynamic> json) {
    return NotificationCounts(
      unreadMessages: (json['unreadMessages'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      pendingReviews: (json['pendingReviews'] as num?)?.toInt() ?? 0,
      pendingModerations: (json['pendingModerations'] as num?)?.toInt() ?? 0,
      deliveredOrders: (json['deliveredOrders'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  /// Сериализует в JSON для кэширования или отладки.
  Map<String, dynamic> toJson() {
    return {
      'unreadMessages': unreadMessages,
      'pendingOrders': pendingOrders,
      'pendingReviews': pendingReviews,
      'pendingModerations': pendingModerations,
      'deliveredOrders': deliveredOrders,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  /// Пустые счётчики — используются как fallback при ошибках.
  static const NotificationCounts empty = NotificationCounts(
    unreadMessages: 0,
    pendingOrders: 0,
    pendingReviews: 0,
    pendingModerations: 0,
    deliveredOrders: 0,
  );

  @override
  String toString() {
    return 'NotificationCounts('
        'unreadMessages: $unreadMessages, '
        'pendingOrders: $pendingOrders, '
        'pendingReviews: $pendingReviews, '
        'pendingModerations: $pendingModerations, '
        'deliveredOrders: $deliveredOrders'
        ')';
  }
}
