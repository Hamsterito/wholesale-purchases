// Сервис управления уведомлениями и значками (badges) для профиля пользователя

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart';
import 'api_service.dart';
import 'app_logger.dart';
import 'auth_storage.dart';
import 'message/message_service_adapters.dart';
import 'message/message_store.dart';

/// Конфигурационные константы для системы уведомлений.
/// Позволяют централизованно управлять поведением значков и сервиса.
class NotificationBadgeConfig {
  NotificationBadgeConfig._();

  /// Максимальное число, отображаемое на значке — при превышении показывается "99+"
  static const int maxCountDisplay = 99;

  /// Длительность анимации появления/исчезновения значка
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Интервал фонового опроса API для обновления счётчиков
  static const Duration pollingInterval = Duration(seconds: 30);

  /// Время жизни локального кэша — после истечения данные считаются устаревшими
  static const Duration cacheExpiration = Duration(minutes: 5);

  /// Максимальное количество повторных попыток при ошибке API
  static const int maxRetries = 5;

  /// Начальная задержка перед первой повторной попыткой (удваивается с каждой попыткой)
  static const Duration initialRetryDelay = Duration(seconds: 1);

  /// После явного действия пользователя (markAsRead, dismiss) — на это время
  /// игнорируем polling, чтобы он не перезаписал локальные изменения
  /// устаревшими данными с сервера.
  static const Duration optimisticHoldDuration = Duration(seconds: 5);

  /// Минимальный интервал между двумя ручными вызовами refreshNotifications().
  /// Защищает от спама запросов при быстрых переключениях экранов.
  static const Duration refreshThrottle = Duration(seconds: 2);
}

/// Сервис управления счётчиками уведомлений.
/// Реализует singleton-паттерн, фоновый polling, кэширование и retry-логику.
class NotificationService with WidgetsBindingObserver {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Счётчики уведомлений

  /// Количество непрочитанных сообщений поддержки
  final ValueNotifier<int> unreadMessagesCount = ValueNotifier(0);

  /// Количество заказов покупателя, ожидающих действия (для покупателей)
  final ValueNotifier<int> pendingBuyerOrdersCount = ValueNotifier(0);

  /// Количество заказов поставщика, ожидающих действия (для поставщиков)
  final ValueNotifier<int> pendingSupplierOrdersCount = ValueNotifier(0);

  /// Количество товаров, ожидающих отзыва (только для покупателей)
  final ValueNotifier<int> pendingReviewsCount = ValueNotifier(0);

  /// Количество доставленных заказов, ожидающих подтверждения получения (только для покупателей)
  final ValueNotifier<int> deliveredOrdersCount = ValueNotifier(0);

  /// Количество товаров на модерации (для поставщиков и модераторов)
  final ValueNotifier<int> pendingModerationsCount = ValueNotifier(0);

  // Внутреннее состояние

  Timer? _pollingTimer;
  bool _isPollingPaused = false;

  /// userId, для которого был последний раз вызван initialize().
  /// Используется чтобы определить, нужно ли переинициализировать сервис при смене пользователя.
  int? _initializedForUserId;

  /// Подписаны ли уже listeners — защищает от двойной подписки при повторном initialize().
  bool _listenersSubscribed = false;

  /// Зарегистрирован ли наблюдатель lifecycle — нужен для авто-pause/resume polling.
  bool _lifecycleObserverRegistered = false;

  /// Идёт ли сейчас refreshNotifications — защита от параллельных вызовов.
  Completer<void>? _activeRefresh;

  /// Время последнего успешного refresh — для throttling.
  DateTime? _lastRefreshAt;

  /// До этого времени polling не должен перезаписывать счётчики оптимистичным значением,
  /// которое только что выставил пользователь через markAsRead/dismiss.
  DateTime? _optimisticHoldUntil;

  /// Счётчик обращений к refreshNotifications — нужен только для тестов,
  /// чтобы доказать, что polling после истечения hold-а действительно вызвал
  /// refresh. Инкрементируется сразу после проверки авторизации, до throttle
  /// и до защиты от параллельных вызовов — иначе тест не отличит "пропустили
  /// из-за throttle" от "вообще не дошли до refresh".
  int _refreshAttemptCount = 0;

  // Кэшируем ValueNotifier для totalNotificationCount, чтобы UI мог на него подписаться
  final ValueNotifier<int> _totalNotificationCount = ValueNotifier(0);

  /// Суммарный счётчик уведомлений с фильтрацией по роли пользователя.
  /// Buyer: сообщения + заказы + отзывы.
  /// Supplier: сообщения + заказы + модерации.
  /// Moderator: сообщения + модерации.
  ValueNotifier<int> get totalNotificationCount => _totalNotificationCount;

  // Инициализация

  /// Инициализирует сервис: загружает кэш, запрашивает актуальные данные,
  /// запускает фоновый polling. Вызывать при старте приложения и после login.
  /// Безопасно вызывать повторно — при смене userId перезапустит polling
  /// с правильными данными, при том же userId — пропустит инициализацию.
  Future<void> initialize() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      AppLogger.debug(
        'NotificationService: userId не задан, инициализация пропущена',
        scope: 'notifications',
      );
      return;
    }

    // Если уже инициализирован для того же пользователя — просто обновляем данные
    if (_initializedForUserId == userId) {
      AppLogger.debug(
        'NotificationService уже инициализирован для userId=$userId, обновляем данные',
        scope: 'notifications',
      );
      await refreshNotifications();
      return;
    }

    // Если был инициализирован для другого пользователя — сбрасываем
    if (_initializedForUserId != null && _initializedForUserId != userId) {
      AppLogger.info(
        'Смена пользователя: $_initializedForUserId → $userId, сбрасываем счётчики',
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

  /// Сбрасывает все счётчики, останавливает polling и очищает состояние пользователя.
  /// Вызывать при logout — иначе следующий вошедший увидит чужие значения.
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
        final prefs = await SharedPreferences.getInstance();
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

  /// Подписывает внутренние слушатели для пересчёта totalNotificationCount.
  /// Вызывается из initialize() и может быть вызван в тестах напрямую.
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

  /// Регистрирует наблюдатель WidgetsBinding — авто-pause polling в фоне.
  void _registerLifecycleObserver() {
    if (_lifecycleObserverRegistered) return;
    try {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverRegistered = true;
    } catch (e) {
      // В тестах WidgetsBinding может быть недоступен — это не критично
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
        // Приложение вернулось в фокус — сразу обновляем данные
        resumePolling();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        pausePolling();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // inactive — кратковременное состояние, polling трогать не нужно
        break;
    }
  }

  // Загрузка данных с API

  /// Загружает актуальные счётчики с API и обновляет ValueNotifier-ы.
  /// При ошибке использует кэшированные значения.
  /// Защищён от параллельных вызовов: второй вызов дождётся завершения первого.
  Future<void> refreshNotifications({bool force = false}) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    // Считаем попытку сразу после прохождения auth-guard и до throttle —
    // тестам важен сам факт, что polling дошёл до refresh после hold-а
    _refreshAttemptCount++;

    // Throttling: если только что обновлялись и не force — пропускаем
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

    // Защита от параллельных вызовов — ждём текущий и не запускаем новый
    if (_activeRefresh != null) {
      return _activeRefresh!.future;
    }

    final completer = Completer<void>();
    _activeRefresh = completer;

    try {
      final counts = await _retryWithBackoff(
        () => ApiService.getNotificationCounts(
          userId: userId,
          role: AuthStorage.role ?? '',
        ),
      );

      // Проверяем optimistic hold: если пользователь только что нажал markAsRead,
      // не перезаписываем его локальное значение результатом polling-а
      final holdActive =
          _optimisticHoldUntil != null &&
          DateTime.now().isBefore(_optimisticHoldUntil!);

      if (holdActive) {
        AppLogger.debug(
          'Optimistic hold активен, пропускаем перезапись счётчиков',
          scope: 'notifications',
        );
      } else {
        // Перепроверяем userId — пока шёл запрос, пользователь мог разлогиниться
        if (AuthStorage.userId != userId) {
          AppLogger.debug(
            'userId изменился во время refresh, отменяем обновление',
            scope: 'notifications',
          );
        } else {
          final role = AuthStorage.role;
          unreadMessagesCount.value = counts.unreadMessages;
          // pendingOrders с сервера приходит уже отфильтрованный по роли —
          // раскладываем его в соответствующий счётчик
          if (role == 'supplier') {
            pendingSupplierOrdersCount.value = counts.pendingOrders;
            pendingBuyerOrdersCount.value = 0;
          } else {
            pendingBuyerOrdersCount.value = counts.pendingOrders;
            pendingSupplierOrdersCount.value = 0;
          }
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
      // Кэшированные значения уже загружены в initialize()
    } finally {
      completer.complete();
      _activeRefresh = null;
    }
  }

  // Локальное кэширование

  static const _cacheKeyPrefix = 'notification_counts_cache';

  /// Ключ кэша уникален для каждого пользователя — иначе при смене аккаунта
  /// новый пользователь увидит счётчики предыдущего.
  String _cacheKeyForUser(int userId) => '${_cacheKeyPrefix}_$userId';

  /// Загружает счётчики из локального кэша SharedPreferences.
  /// Если кэш устарел (> 5 минут), данные игнорируются.
  Future<void> _loadCachedCounts(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKeyForUser(userId));
      if (raw == null) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;

      // Проверяем актуальность кэша
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

  /// Сохраняет текущие счётчики в SharedPreferences с временной меткой.
  Future<void> _cacheCounts(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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

  /// Запускает периодический опрос API каждые 30 секунд.
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      NotificationBadgeConfig.pollingInterval,
      (_) => _runPollingTick(),
    );
  }

  /// Тело одного цикла polling-а. Вынесено в отдельный метод, чтобы тесты
  /// могли детерминированно прогнать одну итерацию без работы с таймером.
  void _runPollingTick() {
    // Проверяем, что пользователь всё ещё авторизован — иначе останавливаем polling
    if (AuthStorage.userId == null || AuthStorage.userId! <= 0) {
      AppLogger.debug(
        'Пользователь разлогинился, останавливаем polling',
        scope: 'notifications',
      );
      _stopPolling();
      return;
    }

    if (_isPollingPaused) return;

    // Если hold уже стоял, но истёк — логируем один раз и очищаем поле,
    // чтобы следующие тики не лили одно и то же сообщение в лог.
    if (_optimisticHoldUntil != null && !_isOptimisticHoldActive()) {
      AppLogger.debug(
        'Optimistic hold истёк, возобновляем polling',
        scope: 'notifications',
      );
      _optimisticHoldUntil = null;
    }

    // Если активен optimistic hold — пользователь только что выполнил
    // действие, и polling может перезаписать локальные изменения
    // устаревшими данными. Полностью пропускаем цикл, чтобы не делать
    // лишний запрос и дождаться истечения hold-а.
    if (_isOptimisticHoldActive()) {
      AppLogger.debug(
        'Polling пропущен: активен optimistic hold',
        scope: 'notifications',
      );
      return;
    }

    // Внутри polling вызываем с force=true, чтобы обойти throttle —
    // сам polling уже даёт нужный интервал
    refreshNotifications(force: true);
  }

  /// Тестовый запуск одной итерации polling-а — позволяет детерминированно
  /// проверить логику тика без подмены реального Timer.periodic.
  @visibleForTesting
  void runPollingTickForTesting() => _runPollingTick();

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Приостанавливает polling — вызывать когда приложение уходит в фон.
  void pausePolling() {
    _isPollingPaused = true;
  }

  /// Возобновляет polling и сразу обновляет данные — вызывать при возврате в фокус.
  void resumePolling() {
    _isPollingPaused = false;
    // force=true — игнорируем throttle, чтобы при возврате из фона получить свежие данные
    refreshNotifications(force: true);
  }

  // Retry с exponential backoff

  /// Выполняет action с повторными попытками. Задержки удваиваются от
  /// initialRetryDelay до 8 секунд, попыток maxRetries по умолчанию.
  /// maxAttempts позволяет точечно сократить число попыток.
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

        // Удваиваем задержку, но не превышаем максимум
        final nextMs = delay.inMilliseconds * 2;
        delay = Duration(
          milliseconds: nextMs > maxDelay.inMilliseconds
              ? maxDelay.inMilliseconds
              : nextMs,
        );
      }
    }

    // Недостижимо, но компилятор требует return
    throw StateError('_retryWithBackoff: неожиданное завершение цикла');
  }

  /// Продлевает или активирует optimistic hold — на N секунд polling не будет
  /// перезаписывать значения счётчиков ответом сервера.
  /// Если hold уже активен, метод сдвигает его конец на полный период от
  /// текущего момента — это защищает от race condition, когда пользователь
  /// быстро выполняет несколько действий подряд (например, отмечает три
  /// сообщения прочитанными за пару секунд).
  /// Если hold ещё не активен, создаёт новый.
  void _extendOptimisticHold() {
    _optimisticHoldUntil = DateTime.now().add(
      NotificationBadgeConfig.optimisticHoldDuration,
    );
  }

  /// Проверяет, активен ли optimistic hold.
  /// Возвращает true, если пользователь недавно выполнил действие и polling
  /// нужно пропустить, чтобы не перезаписать локальные изменения данными
  /// с сервера, которые ещё не успели обновиться.
  bool _isOptimisticHoldActive() {
    final until = _optimisticHoldUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  /// Тестовый геттер для проверки активности optimistic hold.
  @visibleForTesting
  bool get isOptimisticHoldActiveForTesting => _isOptimisticHoldActive();

  /// Тестовый сеттер для установки конца optimistic hold напрямую,
  /// без обращения к API через markMessageAsRead/dismiss.
  @visibleForTesting
  set optimisticHoldUntilForTesting(DateTime? value) {
    _optimisticHoldUntil = value;
  }

  /// Тестовый геттер времени окончания optimistic hold.
  /// Парный к сеттеру выше — нужен тестам, чтобы проверить,
  /// что _extendOptimisticHold действительно сдвигает дедлайн вперёд
  /// при повторных действиях пользователя.
  @visibleForTesting
  DateTime? get optimisticHoldUntilForTesting => _optimisticHoldUntil;

  /// Тестовый враппер вокруг приватного _extendOptimisticHold —
  /// позволяет проверить логику продления holdа без реального обращения
  /// к API через markMessageAsRead/dismiss/markOrderAsReviewed.
  @visibleForTesting
  void extendOptimisticHoldForTesting() => _extendOptimisticHold();

  /// Тестовый геттер времени последнего успешного refresh —
  /// позволяет проверить, что polling действительно был пропущен
  /// (значение должно остаться прежним после runPollingTickForTesting).
  @visibleForTesting
  DateTime? get lastRefreshTimeForTesting => _lastRefreshAt;

  /// Тестовый геттер счётчика попыток refresh — растёт при каждом вызове
  /// refreshNotifications, прошедшем проверку userId. Позволяет тестам
  /// доказать, что polling после истечения hold-а реально дошёл до refresh,
  /// независимо от того, успел ли API-вызов завершиться.
  @visibleForTesting
  int get refreshAttemptCountForTesting => _refreshAttemptCount;

  /// Тестовый сброс счётчика попыток — нужен, чтобы изолировать тесты
  /// друг от друга в условиях singleton-сервиса.
  @visibleForTesting
  void resetRefreshAttemptCountForTesting() {
    _refreshAttemptCount = 0;
  }

  // Действия с уведомлениями

  /// Отмечает сообщение поддержки как прочитанное и уменьшает счётчик локально.
  Future<void> markMessageAsRead(int messageId) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    // Оптимистично уменьшаем счётчик сразу — UI отреагирует мгновенно
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
      // Если бэкенд не подтвердил — следующий polling после holdа восстановит счётчик
    }
  }

  /// Отмечает заказ как просмотренный и уменьшает счётчик ожидающих заказов.
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

  /// Скрывает уведомление указанного типа и обновляет счётчик.
  /// type: 'message', 'order', 'review', 'moderation'.
  Future<void> dismissNotification(String type) async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) return;

    // Оптимистично уменьшаем счётчик соответствующего типа
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

  /// Пересчитывает суммарный счётчик с учётом роли пользователя.
  /// Вызывается автоматически при изменении любого из счётчиков.
  void _recalculateTotal() {
    _totalNotificationCount.value = _computeTotal();
  }

  /// Вычисляет суммарный счётчик по роли:
  /// - buyer: сообщения + заказы + отзывы
  /// - supplier: сообщения + заказы + модерации + чаты с модераторами
  /// - moderator: сообщения + модерации + чаты с поставщиками
  /// - остальные: 0
  int _computeTotal() {
    final role = AuthStorage.role;

    switch (role) {
      case 'buyer':
        return unreadMessagesCount.value +
            pendingBuyerOrdersCount.value +
            pendingReviewsCount.value +
            deliveredOrdersCount.value;
      case 'supplier':
        return unreadMessagesCount.value +
            pendingSupplierOrdersCount.value +
            pendingModerationsCount.value;
      case 'moderator':
      case 'super_admin':
        return unreadMessagesCount.value + pendingModerationsCount.value;
      default:
        return 0;
    }
  }

  /// Возвращает накопленные уведомления в виде стандартизированных Message-объектов.
  /// Полезно для отладки, экспорта и единообразного отображения.
  Future<List<Message>> getNotificationMessages() async {
    return MessageStore.getByType(MessageType.notification);
  }

  /// Оборачивает уведомление в стандартизированный Message и сохраняет
  /// в MessageStore. Категория проставляется только если её нет в самом
  /// уведомлении. Ошибки логирования не пробрасываются.
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
      // Логирование уведомления не должно ломать основную логику
    }
  }

  // Lifecycle

  /// Освобождает ресурсы: останавливает polling и закрывает ValueNotifier-ы.
  /// Вызывать при выходе из приложения.
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
