// Счётчики уведомлений профиля: загрузка с API, кэш, polling, optimistic hold.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../models/message.dart';
import '../models/notification.dart';
import 'api/api_service.dart';
import 'app_logger.dart';
import 'storage/auth_storage.dart';
import 'message/message_service_adapters.dart';
import 'message/message_store.dart';
import 'storage/shared_prefs_provider.dart';

/// Константы поведения значков и сервиса.
class NotificationBadgeConfig {
  NotificationBadgeConfig._();

  /// При превышении на значке показывается "99+".
  static const int maxCountDisplay = 99;

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration pollingInterval = Duration(seconds: 30);

  /// Старше этого - данные кэша считаются устаревшими.
  static const Duration cacheExpiration = Duration(minutes: 5);

  static const int maxRetries = 5;

  /// Удваивается на каждой попытке до 8 секунд.
  static const Duration initialRetryDelay = Duration(seconds: 1);

  /// После markAsRead/dismiss на это время игнорируем polling, чтобы он
  /// не перезаписал локальные изменения устаревшими данными с сервера.
  static const Duration optimisticHoldDuration = Duration(seconds: 5);

  /// Минимальный интервал между двумя ручными refreshNotifications.
  static const Duration refreshThrottle = Duration(seconds: 2);
}

/// Singleton-сервис со счётчиками уведомлений, фоновым polling и кэшем.
class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Счётчики уведомлений

  final ValueNotifier<int> unreadMessagesCount = ValueNotifier(0);
  final ValueNotifier<int> pendingBuyerOrdersCount = ValueNotifier(0);
  final ValueNotifier<int> pendingSupplierOrdersCount = ValueNotifier(0);
  final ValueNotifier<int> pendingReviewsCount = ValueNotifier(0);
  final ValueNotifier<int> deliveredOrdersCount = ValueNotifier(0);
  final ValueNotifier<int> pendingModerationsCount = ValueNotifier(0);

  // Внутреннее состояние

  Timer? _pollingTimer;
  bool _isPollingPaused = false;

  /// userId последнего initialize - чтобы понять, надо ли переинициализироваться.
  int? _initializedForUserId;

  /// Защита от двойной подписки при повторном initialize.
  bool _listenersSubscribed = false;

  bool _lifecycleObserverRegistered = false;

  /// Защита от параллельных refresh - второй вызов ждёт первый.
  Completer<void>? _activeRefresh;

  DateTime? _lastRefreshAt;

  /// До этого момента polling не должен перезаписывать счётчики, которые
  /// только что выставил пользователь оптимистично.
  DateTime? _optimisticHoldUntil;

  /// Счётчик попыток refresh для тестов: инкрементируется сразу после
  /// auth-guard, до throttle и до защиты от параллельных вызовов - иначе
  /// тест не отличит "пропустили из-за throttle" от "вообще не дошли".
  int _refreshAttemptCount = 0;

  /// Тестовый билдер счётчиков вместо ApiService.getNotificationCounts.
  @visibleForTesting
  Future<NotificationCounts> Function(int userId, String role)?
  countsBuilderForTesting;

  final ValueNotifier<int> _totalNotificationCount = ValueNotifier(0);

  /// Суммарный счётчик с фильтрацией по роли (см. _computeTotal).
  ValueNotifier<int> get totalNotificationCount => _totalNotificationCount;

  // Инициализация

  /// Загружает кэш, тянет свежие счётчики, запускает polling.
  /// Безопасно вызывать повторно: при смене userId перезапускает,
  /// при том же - просто обновляет данные.
  Future<void> initialize() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      AppLogger.debug(
        'NotificationService: userId не задан, инициализация пропущена',
        scope: 'notifications',
      );
      return;
    }

    if (_initializedForUserId == userId) {
      AppLogger.debug(
        'NotificationService уже инициализирован для userId=$userId, обновляем данные',
        scope: 'notifications',
      );
      await refreshNotifications();
      return;
    }

    if (_initializedForUserId != null && _initializedForUserId != userId) {
      AppLogger.info(
        'Смена пользователя: $_initializedForUserId -> $userId, сбрасываем счётчики',
        scope: 'notifications',
      );
      _resetCounters();
    }

    _initializedForUserId = userId;

    _subscribeListeners();
    _registerLifecycleObserver();

    await _loadCachedCounts(userId);
    await refreshNotifications();
    _startPolling();
  }

  /// Сбрасывает счётчики, останавливает polling, чистит кэш пользователя.
  /// Без этого следующий вошедший увидит чужие значения.
  Future<void> clearForLogout() async {
    AppLogger.info(
      'NotificationService: очистка состояния при logout',
      scope: 'notifications',
    );

    _stopPolling();
    _resetCounters();

    final prevUserId = _initializedForUserId;
    _initializedForUserId = null;
    _activeRefresh = null;
    _lastRefreshAt = null;
    _optimisticHoldUntil = null;

    if (prevUserId != null) {
      try {
        final prefs = await SharedPrefsProvider.getInstance();
        await prefs.remove(_cacheKeyForUser(prevUserId));
      } catch (e) {
        AppLogger.warning(
          'Не удалось удалить кэш уведомлений для user=$prevUserId: $e',
          scope: 'notifications',
        );
      }
    }
  }

  void _resetCounters() {
    unreadMessagesCount.value = 0;
    pendingBuyerOrdersCount.value = 0;
    pendingSupplierOrdersCount.value = 0;
    pendingReviewsCount.value = 0;
    pendingModerationsCount.value = 0;
    deliveredOrdersCount.value = 0;
  }

  /// Подписывает listeners пересчёта totalNotificationCount.
  @visibleForTesting
  void subscribeListeners() => _subscribeListeners();

  void _subscribeListeners() {
    if (_listenersSubscribed) return;
    unreadMessagesCount.addListener(_recalculateTotal);
    pendingBuyerOrdersCount.addListener(_recalculateTotal);
    pendingSupplierOrdersCount.addListener(_recalculateTotal);
    pendingReviewsCount.addListener(_recalculateTotal);
    pendingModerationsCount.addListener(_recalculateTotal);
    deliveredOrdersCount.addListener(_recalculateTotal);
    _listenersSubscribed = true;
  }

  void _registerLifecycleObserver() {
    if (_lifecycleObserverRegistered) return;
    try {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverRegistered = true;
    } catch (e) {
      // В тестах WidgetsBinding может быть недоступен - не критично.
      AppLogger.debug(
        'Не удалось зарегистрировать lifecycle observer: $e',
        scope: 'notifications',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        resumePolling();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        pausePolling();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // inactive - кратковременное состояние, polling трогать не нужно.
        break;
    }
  }

  // Загрузка данных с API

  /// Тянет счётчики с API и обновляет ValueNotifier-ы. При ошибке
  /// остаются кэшированные значения. Защищён от параллельных вызовов.
  Future<void> refreshNotifications({bool force = false}) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    // Считаем попытку до throttle - тестам важен сам факт прохода auth-guard.
    _refreshAttemptCount++;

    if (!force && _lastRefreshAt != null) {
      final elapsed = DateTime.now().difference(_lastRefreshAt!);
      if (elapsed < NotificationBadgeConfig.refreshThrottle) {
        AppLogger.debug(
          'Refresh throttled (прошло ${elapsed.inMilliseconds}мс)',
          scope: 'notifications',
        );
        return;
      }
    }

    if (_activeRefresh != null) {
      return _activeRefresh!.future;
    }

    final completer = Completer<void>();
    _activeRefresh = completer;

    try {
      final counts = await _retryWithBackoff(
        () => countsBuilderForTesting != null
            ? countsBuilderForTesting!(userId, AuthStorage.role ?? '')
            : ApiService.getNotificationCounts(
                userId: userId,
                role: AuthStorage.role ?? '',
              ),
      );

      // Если активен optimistic hold - не перезаписываем локальное значение,
      // которое только что выставил пользователь через markAsRead/dismiss.
      final holdActive =
          _optimisticHoldUntil != null &&
          DateTime.now().isBefore(_optimisticHoldUntil!);

      if (holdActive) {
        AppLogger.debug(
          'Optimistic hold активен, пропускаем перезапись счётчиков',
          scope: 'notifications',
        );
      } else {
        // Пока шёл запрос, пользователь мог разлогиниться - перепроверяем.
        if (AuthStorage.userId != userId) {
          AppLogger.debug(
            'userId изменился во время refresh, отменяем обновление',
            scope: 'notifications',
          );
        } else {
          unreadMessagesCount.value = counts.unreadMessages;
          pendingBuyerOrdersCount.value = counts.pendingBuyerOrders;
          pendingSupplierOrdersCount.value = counts.pendingSupplierOrders;
          pendingReviewsCount.value = counts.pendingReviews;
          pendingModerationsCount.value = counts.pendingModerations;
          deliveredOrdersCount.value = counts.deliveredOrders;
          await _cacheCounts(userId);
        }
      }

      _lastRefreshAt = DateTime.now();
    } catch (e, st) {
      AppLogger.error(
        'Не удалось обновить счётчики уведомлений после всех попыток, используем кэш',
        scope: 'notifications',
        error: e,
        stackTrace: st,
      );
    } finally {
      completer.complete();
      _activeRefresh = null;
    }
  }

  // Локальное кэширование

  static const _cacheKeyPrefix = 'notification_counts_cache';

  /// Ключ кэша уникален для каждого пользователя - иначе при смене аккаунта
  /// новый увидит счётчики предыдущего.
  String _cacheKeyForUser(int userId) => '${_cacheKeyPrefix}_$userId';

  Future<void> _loadCachedCounts(int userId) async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final raw = prefs.getString(_cacheKeyForUser(userId));
      if (raw == null) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;

      final timestampStr = data['timestamp'] as String?;
      if (timestampStr != null) {
        final cachedAt = DateTime.tryParse(timestampStr);
        if (cachedAt != null) {
          final age = DateTime.now().difference(cachedAt);
          if (age > NotificationBadgeConfig.cacheExpiration) {
            AppLogger.debug(
              'Кэш уведомлений устарел, пропускаем загрузку',
              scope: 'notifications',
            );
            return;
          }
        }
      }

      unreadMessagesCount.value =
          (data['unreadMessages'] as num?)?.toInt() ?? 0;
      pendingBuyerOrdersCount.value =
          (data['pendingBuyerOrders'] as num?)?.toInt() ?? 0;
      pendingSupplierOrdersCount.value =
          (data['pendingSupplierOrders'] as num?)?.toInt() ?? 0;
      pendingReviewsCount.value =
          (data['pendingReviews'] as num?)?.toInt() ?? 0;
      pendingModerationsCount.value =
          (data['pendingModerations'] as num?)?.toInt() ?? 0;
      deliveredOrdersCount.value =
          (data['deliveredOrders'] as num?)?.toInt() ?? 0;
    } catch (e) {
      AppLogger.warning(
        'Ошибка чтения кэша уведомлений: $e',
        scope: 'notifications',
      );
    }
  }

  Future<void> _cacheCounts(int userId) async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      final data = {
        'unreadMessages': unreadMessagesCount.value,
        'pendingBuyerOrders': pendingBuyerOrdersCount.value,
        'pendingSupplierOrders': pendingSupplierOrdersCount.value,
        'pendingReviews': pendingReviewsCount.value,
        'pendingModerations': pendingModerationsCount.value,
        'deliveredOrders': deliveredOrdersCount.value,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_cacheKeyForUser(userId), jsonEncode(data));
    } catch (e) {
      AppLogger.warning(
        'Ошибка записи кэша уведомлений: $e',
        scope: 'notifications',
      );
    }
  }

  // Фоновый polling

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      NotificationBadgeConfig.pollingInterval,
      (_) => _runPollingTick(),
    );
  }

  /// Тело одного цикла polling. Вынесено отдельно, чтобы тесты могли
  /// детерминированно прогнать одну итерацию без работы с Timer.periodic.
  void _runPollingTick() {
    if (AuthStorage.userId == null || AuthStorage.userId! <= 0) {
      AppLogger.debug(
        'Пользователь разлогинился, останавливаем polling',
        scope: 'notifications',
      );
      _stopPolling();
      return;
    }

    if (_isPollingPaused) return;

    // Hold истёк - один раз логируем и сбрасываем поле, иначе следующие
    // тики будут лить одно и то же сообщение в лог.
    if (_optimisticHoldUntil != null && !_isOptimisticHoldActive()) {
      AppLogger.debug(
        'Optimistic hold истёк, возобновляем polling',
        scope: 'notifications',
      );
      _optimisticHoldUntil = null;
    }

    // Пока активен hold - полностью пропускаем тик, чтобы не делать
    // лишний запрос и не перезаписать локальные изменения с сервера.
    if (_isOptimisticHoldActive()) {
      AppLogger.debug(
        'Polling пропущен: активен optimistic hold',
        scope: 'notifications',
      );
      return;
    }

    // force=true обходит throttle - сам polling уже даёт нужный интервал.
    refreshNotifications(force: true);
  }

  /// Тестовая обёртка над _runPollingTick.
  @visibleForTesting
  void runPollingTickForTesting() => _runPollingTick();

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Приостанавливает polling - вызывать когда приложение уходит в фон.
  void pausePolling() {
    _isPollingPaused = true;
  }

  /// Возобновляет polling и сразу обновляет данные.
  void resumePolling() {
    _isPollingPaused = false;
    // force=true игнорирует throttle, чтобы при возврате из фона данные были свежие.
    refreshNotifications(force: true);
  }

  // Retry с exponential backoff

  /// Повторяет action с удвоением задержки до 8 секунд, не больше maxAttempts попыток.
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() action, {
    int? maxAttempts,
  }) async {
    var delay = NotificationBadgeConfig.initialRetryDelay;
    const maxDelay = Duration(seconds: 8);
    final attemptsLimit = maxAttempts ?? NotificationBadgeConfig.maxRetries;

    for (var attempt = 1; attempt <= attemptsLimit; attempt++) {
      try {
        return await action();
      } catch (e, st) {
        if (attempt == attemptsLimit) {
          AppLogger.error(
            'Все $attempt попыток исчерпаны',
            scope: 'notifications',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }

        AppLogger.warning(
          'Попытка $attempt не удалась, повтор через ${delay.inSeconds}с: $e',
          scope: 'notifications',
        );
        await Future.delayed(delay);

        final nextMs = delay.inMilliseconds * 2;
        delay = Duration(
          milliseconds: nextMs > maxDelay.inMilliseconds
              ? maxDelay.inMilliseconds
              : nextMs,
        );
      }
    }

    // Недостижимо, но компилятор требует return.
    throw StateError('_retryWithBackoff: неожиданное завершение цикла');
  }

  /// Сдвигает конец optimistic hold на полный период от текущего момента.
  /// Защищает от race condition, когда пользователь делает несколько
  /// действий подряд (например, отмечает три сообщения за пару секунд).
  void _extendOptimisticHold() {
    _optimisticHoldUntil = DateTime.now().add(
      NotificationBadgeConfig.optimisticHoldDuration,
    );
  }

  bool _isOptimisticHoldActive() {
    final until = _optimisticHoldUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  @visibleForTesting
  bool get isOptimisticHoldActiveForTesting => _isOptimisticHoldActive();

  @visibleForTesting
  set optimisticHoldUntilForTesting(DateTime? value) {
    _optimisticHoldUntil = value;
  }

  @visibleForTesting
  DateTime? get optimisticHoldUntilForTesting => _optimisticHoldUntil;

  @visibleForTesting
  void extendOptimisticHoldForTesting() => _extendOptimisticHold();

  @visibleForTesting
  DateTime? get lastRefreshTimeForTesting => _lastRefreshAt;

  @visibleForTesting
  int get refreshAttemptCountForTesting => _refreshAttemptCount;

  @visibleForTesting
  void resetRefreshAttemptCountForTesting() {
    _refreshAttemptCount = 0;
  }

  @visibleForTesting
  Future<void> loadCachedCountsForTesting(int userId) =>
      _loadCachedCounts(userId);

  // Действия с уведомлениями

  /// Отмечает сообщение поддержки прочитанным с оптимистичным уменьшением счётчика.
  Future<void> markMessageAsRead(int messageId) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    if (unreadMessagesCount.value > 0) {
      unreadMessagesCount.value--;
      _extendOptimisticHold();
      await _cacheCounts(userId);
    }

    try {
      await _retryWithBackoff(
        () =>
            ApiService.markMessageAsRead(userId: userId, messageId: messageId),
      );
    } catch (e, st) {
      AppLogger.error(
        'Не удалось отметить сообщение $messageId как прочитанное',
        scope: 'notifications',
        error: e,
        stackTrace: st,
      );
      // Если бэкенд не подтвердил - polling после hold восстановит счётчик.
    }
  }

  /// Отмечает заказ просмотренным и уменьшает счётчик ожидающих заказов
  /// (buyer/supplier зависит от роли).
  Future<void> markOrderAsReviewed(String orderId) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    final role = AuthStorage.role;
    final counter = role == 'supplier'
        ? pendingSupplierOrdersCount
        : pendingBuyerOrdersCount;

    if (counter.value > 0) {
      counter.value--;
      _extendOptimisticHold();
      await _cacheCounts(userId);
    }

    try {
      await _retryWithBackoff(
        () => ApiService.markOrderAsReviewed(userId: userId, orderId: orderId),
      );
    } catch (e, st) {
      AppLogger.error(
        'Не удалось отметить заказ $orderId как просмотренный',
        scope: 'notifications',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Скрывает уведомление типа 'message' / 'order' / 'review' / 'moderation'
  /// и оптимистично уменьшает соответствующий счётчик.
  Future<void> dismissNotification(String type) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    var didDecrement = false;
    final role = AuthStorage.role;
    switch (type) {
      case 'message':
        if (unreadMessagesCount.value > 0) {
          unreadMessagesCount.value--;
          didDecrement = true;
        }
      case 'order':
        final counter = role == 'supplier'
            ? pendingSupplierOrdersCount
            : pendingBuyerOrdersCount;
        if (counter.value > 0) {
          counter.value--;
          didDecrement = true;
        }
      case 'review':
        if (pendingReviewsCount.value > 0) {
          pendingReviewsCount.value--;
          didDecrement = true;
        }
      case 'moderation':
        if (pendingModerationsCount.value > 0) {
          pendingModerationsCount.value--;
          didDecrement = true;
        }
    }

    if (didDecrement) {
      _extendOptimisticHold();
      await _cacheCounts(userId);
    }

    try {
      await _retryWithBackoff(
        () => ApiService.dismissNotification(
          userId: userId,
          notificationType: type,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Не удалось скрыть уведомление типа "$type"',
        scope: 'notifications',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Фильтрация по ролям

  void _recalculateTotal() {
    _totalNotificationCount.value = _computeTotal();
  }

  /// Считает суммарный счётчик по роли. Покупательская активность
  /// (заказы, отзывы, доставленные) плюсуется во всех ветках, потому что
  /// поставщик/модератор тоже могут быть в роли покупателя.
  int _computeTotal() {
    final role = AuthStorage.role;

    final buyerActivity =
        pendingBuyerOrdersCount.value +
        pendingReviewsCount.value +
        deliveredOrdersCount.value;

    switch (role) {
      case 'buyer':
        return unreadMessagesCount.value + buyerActivity;
      case 'supplier':
        return unreadMessagesCount.value +
            buyerActivity +
            pendingSupplierOrdersCount.value +
            pendingModerationsCount.value;
      case 'moderator':
      case 'super_admin':
        return unreadMessagesCount.value +
            buyerActivity +
            pendingModerationsCount.value;
      default:
        return 0;
    }
  }

  /// Накопленные уведомления как стандартизированные Message-объекты -
  /// для отладки, экспорта и единого отображения.
  Future<List<Message>> getNotificationMessages() async {
    return MessageStore.getByType(MessageType.notification);
  }

  /// Оборачивает уведомление в Message и сохраняет в MessageStore.
  /// Категория проставляется только если её нет в самом уведомлении.
  /// Ошибки наружу не пробрасываются - сбой логирования не должен ронять основную логику.
  // ignore: unused_element
  Future<void> _logNotificationAsMessage(
    dynamic notification, {
    String? category,
  }) async {
    try {
      final message = NotificationServiceAdapter.wrapNotification(
        notification,
        'ru',
        category: category,
      );
      await MessageStore.save(message);
    } catch (_) {
      // Логирование не должно ломать основной поток.
    }
  }

  // Lifecycle

  /// Останавливает polling, отписывает listeners, закрывает ValueNotifier-ы.
  void dispose() {
    _stopPolling();
    if (_lifecycleObserverRegistered) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {
        // ignore
      }
      _lifecycleObserverRegistered = false;
    }

    if (_listenersSubscribed) {
      unreadMessagesCount.removeListener(_recalculateTotal);
      pendingBuyerOrdersCount.removeListener(_recalculateTotal);
      pendingSupplierOrdersCount.removeListener(_recalculateTotal);
      pendingReviewsCount.removeListener(_recalculateTotal);
      pendingModerationsCount.removeListener(_recalculateTotal);
      deliveredOrdersCount.removeListener(_recalculateTotal);
      _listenersSubscribed = false;
    }

    unreadMessagesCount.dispose();
    pendingBuyerOrdersCount.dispose();
    pendingSupplierOrdersCount.dispose();
    pendingReviewsCount.dispose();
    pendingModerationsCount.dispose();
    deliveredOrdersCount.dispose();
    _totalNotificationCount.dispose();
  }
}
