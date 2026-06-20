import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/message.dart';
import 'api_config.dart';
import '../app_logger.dart';
import '../message/message_store.dart';
import '../message/message_service_adapters.dart';

class AiException implements Exception {
  final String message;
  final String? userMessage;

  AiException({required this.message, this.userMessage});

  @override
  String toString() => message;
}

class AiService {
  AiService._();

  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 45);

  // HTTP-клиент для запросов к модели. В продакшене - реальный http.Client,
  // в тестах подменяется на MockClient через httpClient.
  static http.Client _client = http.Client();

  /// Подменяет HTTP-клиент - нужно для перехвата запросов в тестах через
  /// MockClient из package:http/testing.dart.
  @visibleForTesting
  static set httpClient(http.Client client) => _client = client;

  /// Возвращает реальный http.Client по умолчанию - сброс после тестов.
  @visibleForTesting
  static void resetHttpClient() => _client = http.Client();

  // RegExp для очистки markdown - компилируем один раз на класс,
  // cleanMarkdown зовётся на каждый ответ модели.
  static final RegExp _markdownBoldStarsRegExp = RegExp(r'\*\*([^*]+)\*\*');
  static final RegExp _markdownBoldUnderscoresRegExp = RegExp(r'__([^_]+)__');
  static final RegExp _markdownItalicStarsRegExp = RegExp(r'\*([^*]+)\*');
  static final RegExp _markdownItalicUnderscoresRegExp = RegExp(r'_([^_]+)_');
  static final RegExp _markdownHeadingRegExp = RegExp(
    r'^#+\s+',
    multiLine: true,
  );
  static final RegExp _markdownBulletRegExp = RegExp(
    r'^[\-\*]\s+',
    multiLine: true,
  );
  static final RegExp _markdownNumberedListRegExp = RegExp(
    r'^\d+\.\s+',
    multiLine: true,
  );

  // Список моделей для fallback (пробуем по очереди при ошибках лимита).
  // Только модели с уверенной поддержкой русского языка.
  static const List<String> _fallbackModels = [
    'google/gemma-4-31b-it:free',
    'deepseek/deepseek-v4-flash:free',
    'openai/gpt-oss-120b:free',
    'openai/gpt-oss-20b:free',
    'nvidia/nemotron-3-super-120b-a12b:free',
  ];

  /// Генерирует AI-резюме по статистике поставщика - 3-5 предложений на русском.
  static Future<String> generateSupplierSummary(
    Map<String, dynamic> stats,
  ) async {
    final apiKey = ApiConfig.aiApiKey;
    if (apiKey.isEmpty) {
      throw AiException(
        message: 'AI API key is not configured',
        userMessage: 'Ошибка конфигурации API',
      );
    }

    // Пробуем основную модель, затем fallback модели
    final modelsToTry = buildModelList(ApiConfig.aiModel, _fallbackModels);

    AiException? lastException;

    for (final model in modelsToTry) {
      try {
        AppLogger.info('Пробуем модель: $model', scope: 'ai');
        return await _tryGenerateWithModel(apiKey, model, stats);
      } on AiException catch (e) {
        lastException = e;
        AppLogger.warning(
          'Модель $model не сработала: ${e.message}',
          scope: 'ai',
        );
        continue;
      }
    }

    // Если все модели не сработали, выбрасываем последнюю ошибку
    throw lastException ??
        AiException(
          message: 'All models failed',
          userMessage: 'Не удалось сформировать AI-резюме',
        );
  }

  /// Строит список моделей для перебора: primary первым, затем fallback
  /// в исходном порядке, без повторного вхождения primary.
  @visibleForTesting
  static List<String> buildModelList(String primary, List<String> fallbacks) {
    return [primary, ...fallbacks.where((m) => m != primary)];
  }

  /// Пробует сгенерировать резюме с конкретной моделью
  static Future<String> _tryGenerateWithModel(
    String apiKey,
    String model,
    Map<String, dynamic> stats,
  ) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final prompt = constructPrompt(stats);

        const temperature = 0.7;
        const maxTokens = 300;

        final response = await _client
            .post(
              Uri.parse('${ApiConfig.aiEndpoint}/chat/completions'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $apiKey',
                'HTTP-Referer': 'https://github.com/yourusername/wholesale-app',
                'X-Title': 'Wholesale App',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'You are an AI analyst for suppliers. You MUST respond ONLY in Russian language. '
                        'All your responses must be 100% in Russian. '
                        'Never use any other language under any circumstances. '
                        'If the request is not in Russian, still respond in Russian. '
                        'Ты AI-аналитик поставщиков. ОБЯЗАТЕЛЬНО отвечай ТОЛЬКО на русском языке. '
                        'Все твои ответы должны быть на 100% на русском. '
                        'Никогда не используй другие языки ни при каких обстоятельствах.',
                  },
                  {'role': 'user', 'content': prompt},
                ],
                'temperature': temperature,
                'max_tokens': maxTokens,
              }),
            )
            .timeout(_timeout);

        final generated = handleResponse(response);

        // Параллельно логируем сгенерированный контент в MessageStore
        // для аналитики и отладки. Сбой логирования не должен ронять основной поток.
        try {
          await createAiMessage(generated, model, <String, dynamic>{
            'temperature': temperature,
            'maxTokens': maxTokens,
          });
        } catch (_) {}

        return generated;
      } on TimeoutException catch (e, stack) {
        await _logAiError(e, stack, model: model);
        throw AiException(
          message: 'Request timeout: $e',
          userMessage: 'Запрос занял слишком долго',
        );
      } on SocketException catch (e, stack) {
        await _logAiError(e, stack, model: model);
        throw AiException(
          message: 'Network error: $e',
          userMessage: 'Проверьте подключение к интернету',
        );
      } on AiException catch (e) {
        // Если это ошибка лимита (429), пробуем другую модель без повторов
        if (isRateLimitError(e.message)) {
          AppLogger.info(
            'Лимит запросов для модели $model, переходим на другую',
            scope: 'ai',
          );
          rethrow; // Выбрасываем, чтобы перейти на следующую модель в generateSupplierSummary
        }

        if (shouldRetry(e.message) && attempt < _maxRetries - 1) {
          final delaySeconds = 1 << attempt; // 2^attempt
          AppLogger.info(
            'Повтор через $delaySeconds сек (попытка ${attempt + 1}/$_maxRetries)',
            scope: 'ai',
          );
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }
        rethrow;
      } catch (e, stack) {
        await _logAiError(e, stack, model: model);
        throw AiException(
          message: 'Unexpected error: $e',
          userMessage: 'Не удалось сформировать AI-резюме',
        );
      }
    }

    throw AiException(
      message: 'Max retries exceeded',
      userMessage: 'Не удалось сформировать AI-резюме',
    );
  }

  /// Обрабатывает ответ от AI API
  @visibleForTesting
  static String handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw AiException(
        message: 'Unauthorized: Invalid API key',
        userMessage: 'Ошибка конфигурации API',
      );
    }

    if (response.statusCode == 429) {
      // Ошибка лимита - выбрасываем без userMessage, чтобы не показывать пользователю
      throw AiException(message: 'Rate limit exceeded', userMessage: null);
    }

    if (response.statusCode >= 500) {
      throw AiException(
        message: 'Server error: ${response.statusCode}',
        userMessage: 'Ошибка сервера. Попробуем другую модель',
      );
    }

    if (response.statusCode != 200) {
      // Пробуем распарсить error body
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final error = body['error'];

        if (error != null) {
          final errorMessage = error is Map
              ? (error['message'] as String? ?? 'Unknown API error')
              : error.toString();

          throw AiException(
            message: 'API error: $errorMessage',
            userMessage: 'Ошибка AI сервиса',
          );
        }
      } catch (e) {
        // Если не удалось распарсить, используем стандартное сообщение
        if (e is AiException) rethrow;
      }

      throw AiException(
        message: 'HTTP ${response.statusCode}: ${response.body}',
        userMessage: 'Ошибка при обработке ответа',
      );
    }

    try {
      final responseBody = utf8.decode(response.bodyBytes);
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

      // Использует стандартный формат OpenAI
      final choices = jsonResponse['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw AiException(
          message: 'No choices in response',
          userMessage: 'Ошибка при обработке ответа',
        );
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      if (message == null) {
        throw AiException(
          message: 'No message in choice',
          userMessage: 'Ошибка при обработке ответа',
        );
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        throw AiException(
          message: 'No content in message',
          userMessage: 'Ошибка при обработке ответа',
        );
      }

      AppLogger.info('AI-резюме успешно сгенерировано', scope: 'ai');

      return cleanMarkdown(content);
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException(
        message: 'Error parsing response: $e',
        userMessage: 'Ошибка при обработке ответа',
      );
    }
  }

  /// Убирает markdown форматирование из текста
  @visibleForTesting
  static String cleanMarkdown(String text) {
    String cleaned = text;

    // replaceAllMapped, а не replaceAll с $1 - в Dart replaceAll вставляет
    // строку замены буквально, без подстановки групп, поэтому **текст** иначе
    // превратился бы в литерал $1, а не в содержимое разметки.
    cleaned = cleaned.replaceAllMapped(
      _markdownBoldStarsRegExp,
      (m) => m.group(1)!,
    );
    cleaned = cleaned.replaceAllMapped(
      _markdownBoldUnderscoresRegExp,
      (m) => m.group(1)!,
    );
    cleaned = cleaned.replaceAllMapped(
      _markdownItalicStarsRegExp,
      (m) => m.group(1)!,
    );
    cleaned = cleaned.replaceAllMapped(
      _markdownItalicUnderscoresRegExp,
      (m) => m.group(1)!,
    );
    cleaned = cleaned.replaceAll(_markdownHeadingRegExp, '');
    cleaned = cleaned.replaceAll(_markdownBulletRegExp, '');
    cleaned = cleaned.replaceAll(_markdownNumberedListRegExp, '');

    return cleaned.trim();
  }

  /// Определяет, нужно ли повторять попытку для данной ошибки
  @visibleForTesting
  static bool shouldRetry(String message) {
    // Повторяем для транзиентных ошибок (429, 5xx)
    // API иногда временно возвращает 429
    return message.contains('Server error') || message.contains('Rate limit');
  }

  /// Проверяет, является ли ошибка ошибкой лимита запросов
  @visibleForTesting
  static bool isRateLimitError(String message) {
    return message.contains('Rate limit');
  }

  /// Сохраняет AI-ответ как Message в MessageStore - для аналитики и отладки.
  static Future<Message> createAiMessage(
    String content,
    String model,
    Map<String, dynamic> params,
  ) async {
    final message = AiServiceAdapter.wrapAiResponse(content, model, params);
    await MessageStore.save(message);
    return message;
  }

  /// Сохраняет ошибку AI-вызова как Message в MessageStore.
  static Future<Message> _logAiError(
    Object e,
    StackTrace? stack, {
    String? model,
  }) async {
    final message = AiServiceAdapter.wrapAiError(e, stack, 'ru', model: model);
    try {
      await MessageStore.save(message);
    } catch (_) {
      // Логирование ошибки не должно ломать основной поток
    }
    return message;
  }

  /// Конструирует промпт на русском языке на основе статистики поставщика
  @visibleForTesting
  static String constructPrompt(Map<String, dynamic> stats) {
    final totalRevenue = stats['totalRevenue'] ?? 0;
    final monthlyRevenue = stats['monthlyRevenue'] ?? 0;
    final totalOrders = stats['totalOrders'] ?? 0;
    final averageOrderValue = stats['averageOrderValue'] ?? 0;
    final averageRating = stats['averageRating'] ?? 0.0;
    final totalReviews = stats['totalReviews'] ?? 0;
    final repeatBuyersPercentage = stats['repeatBuyersPercentage'] ?? 0;
    final newBuyersThisMonth = stats['newBuyersThisMonth'] ?? 0;
    final topProductsCount = stats['topProductsCount'] ?? 0;
    final productsWithZeroSales = stats['productsWithZeroSales'] ?? 0;
    final averageFulfillmentDays = stats['averageFulfillmentDays'] ?? 0;
    final cancelledOrdersPercentage = stats['cancelledOrdersPercentage'] ?? 0;

    return '''ВАЖНО: Отвечай ТОЛЬКО на русском языке! Весь твой ответ должен быть на 100% на русском.

Ты опытный бизнес-аналитик оптовой торговой площадки. Проанализируй показатели работы поставщика и подготовь короткое, конкретное и полезное резюме на русском языке.

Показатели поставщика:
• Общая выручка: $totalRevenue
• Выручка за месяц: $monthlyRevenue
• Всего заказов: $totalOrders
• Средний чек: $averageOrderValue
• Рейтинг покупателей: $averageRating из 5.0 (отзывов: $totalReviews)
• Доля повторных покупателей: $repeatBuyersPercentage%
• Новых покупателей за месяц: $newBuyersThisMonth
• Товаров-лидеров продаж: $topProductsCount
• Товаров без продаж: $productsWithZeroSales
• Среднее время выполнения заказа: $averageFulfillmentDays дн.
• Доля отменённых заказов: $cancelledOrdersPercentage%

Структура резюме - три коротких абзаца, разделённых пустой строкой:

Абзац 1. Сильные стороны.
Назови главные достижения, опираясь на положительные метрики (высокая выручка, хороший рейтинг, повторные покупатели). Подкрепляй выводы конкретными цифрами.

Абзац 2. Зоны роста.
Укажи проблемные метрики (низкий средний чек, отмены заказов, товары без продаж) и кратко объясни, как они влияют на бизнес.

Абзац 3. Рекомендации.
Дай 2 конкретные и выполнимые рекомендации, нацеленные на рост выручки и удовлетворённость покупателей.

Требования к ответу:
- Пиши только на русском языке, грамотно и в деловом, но живом тоне.
- Не используй markdown-разметку (никаких **, __, ##, ---).
- Не используй списки и нумерацию - только связные абзацы.
- Опирайся на конкретные цифры из показателей выше.
- Не выдумывай данные, которых нет в показателях.
- Объём - 5-7 предложений суммарно по трём абзацам.

ПОВТОРЯЮ: Твой ответ должен быть ПОЛНОСТЬЮ на русском языке!''';
  }
}
