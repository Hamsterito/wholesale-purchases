import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'app_logger.dart';

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

  // Список моделей для fallback (пробуем по очереди при ошибках лимита)
  static const List<String> _fallbackModels = [
    'google/gemma-4-31b-it:free',
    'deepseek/deepseek-v4-flash:free',
    'nvidia/nemotron-3-super-120b-a12b:free',
    'openai/gpt-oss-120b:free',
    'openai/gpt-oss-20b:free',
    'z-ai/glm-4.5-air:free',
    'nvidia/nemotron-3-nano-30b-a3b:free',
    'arcee-ai/trinity-large-thinking:free',
    'minimax/minimax-m2.5:free',
    'baidu/cobuddy:free',
  ];

  /// Генерирует резюме производительности поставщика на русском языке
  /// Принимает карту статистики и возвращает 3-5 предложений на русском языке
  /// с выделением положительных показателей, проблем и рекомендаций
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
    final primaryModel = ApiConfig.aiModel;
    final modelsToTry = [
      primaryModel,
      ..._fallbackModels.where((m) => m != primaryModel),
    ];

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
        // Продолжаем со следующей моделью
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

  /// Пробует сгенерировать резюме с конкретной моделью
  static Future<String> _tryGenerateWithModel(
    String apiKey,
    String model,
    Map<String, dynamic> stats,
  ) async {
    // Реализуем логику повторных попыток с экспоненциальной задержкой
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final prompt = _constructPrompt(stats);

        final response = await http
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
                        'Ты AI-аналитик поставщиков. Отвечай кратко и профессионально на русском языке.',
                  },
                  {'role': 'user', 'content': prompt},
                ],
                'temperature': 0.7,
                'max_tokens': 300,
              }),
            )
            .timeout(_timeout);

        return _handleResponse(response);
      } on TimeoutException catch (e) {
        throw AiException(
          message: 'Request timeout: $e',
          userMessage: 'Запрос занял слишком долго',
        );
      } on SocketException catch (e) {
        throw AiException(
          message: 'Network error: $e',
          userMessage: 'Проверьте подключение к интернету',
        );
      } on AiException catch (e) {
        // Если это ошибка лимита (429), пробуем другую модель без повторов
        if (_isRateLimitError(e.message)) {
          AppLogger.info(
            'Лимит запросов для модели $model, переходим на другую',
            scope: 'ai',
          );
          rethrow; // Выбрасываем, чтобы перейти на следующую модель в generateSupplierSummary
        }

        if (_shouldRetry(e.message) && attempt < _maxRetries - 1) {
          final delaySeconds = 1 << attempt; // 2^attempt
          AppLogger.info(
            'Повтор через $delaySeconds сек (попытка ${attempt + 1}/$_maxRetries)',
            scope: 'ai',
          );
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }
        rethrow;
      } catch (e) {
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
  static String _handleResponse(http.Response response) {
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
      // Пробуем распарсить OpenRouter error body
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

      // OpenRouter использует стандартный формат OpenAI
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

      // Постобработка: убираем markdown форматирование
      return _cleanMarkdown(content);
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException(
        message: 'Error parsing response: $e',
        userMessage: 'Ошибка при обработке ответа',
      );
    }
  }

  /// Убирает markdown форматирование из текста
  static String _cleanMarkdown(String text) {
    String cleaned = text;

    // Убираем жирный текст (**text** или __text__)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__([^_]+)__'), r'$1');

    // Убираем курсив (*text* или _text_)
    cleaned = cleaned.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'_([^_]+)_'), r'$1');

    // Убираем заголовки (## text)
    cleaned = cleaned.replaceAll(RegExp(r'^#+\s+', multiLine: true), '');

    // Убираем bullet points (- text или * text)
    cleaned = cleaned.replaceAll(RegExp(r'^[\-\*]\s+', multiLine: true), '');

    // Убираем нумерованные списки (1. text)
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');

    return cleaned.trim();
  }

  /// Определяет, нужно ли повторять попытку для данной ошибки
  static bool _shouldRetry(String message) {
    // Повторяем для транзиентных ошибок (429, 5xx)
    // OpenRouter free иногда временно возвращает 429
    return message.contains('Server error') || message.contains('Rate limit');
  }

  /// Проверяет, является ли ошибка ошибкой лимита запросов
  static bool _isRateLimitError(String message) {
    return message.contains('Rate limit');
  }

  /// Конструирует промпт на английском языке на основе статистики
  static String _constructPrompt(Map<String, dynamic> stats) {
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

    return '''You are a professional business analyst. Analyze supplier performance data and write a clear, actionable summary in Russian.

Performance Data:
• Total Revenue: ₸$totalRevenue
• Monthly Revenue: ₸$monthlyRevenue  
• Total Orders: $totalOrders
• Average Order Value: ₸$averageOrderValue
• Customer Rating: $averageRating/5.0 ($totalReviews reviews)
• Repeat Buyers: $repeatBuyersPercentage%
• New Buyers This Month: $newBuyersThisMonth
• Top Performing Products: $topProductsCount
• Products With Zero Sales: $productsWithZeroSales
• Average Fulfillment Time: $averageFulfillmentDays days
• Cancelled Orders: $cancelledOrdersPercentage%

Write a professional analysis in Russian (3-4 sentences) with this structure:

Paragraph 1: Highlight key strengths
- Focus on positive metrics (high revenue, good rating, repeat buyers)
- Use specific numbers to support points

Paragraph 2: Identify areas for improvement
- Point out concerning metrics (low AOV, cancellations, zero sales products)
- Explain business impact

Paragraph 3: Provide actionable recommendations
- Give 2 specific, practical recommendations
- Focus on revenue growth and customer satisfaction

IMPORTANT FORMATTING RULES:
- Write in plain Russian text only
- DO NOT use markdown formatting (no **, __, ##, etc.)
- DO NOT use bullet points or numbered lists
- Use natural paragraphs separated by blank lines
- Write in a professional, conversational tone
- Be specific with numbers and metrics''';
  }
}
