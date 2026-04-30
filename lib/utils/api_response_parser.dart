import 'dart:convert';

/// Парсит ответ API и возвращает поле message для отображения пользователю.
/// Обрабатывает успешные и ошибочные ответы.
String parseApiMessage(String responseBody, {String fallback = 'Unknown error'}) {
  try {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    return data['message']?.toString() ?? fallback;
  } catch (_) {
    return responseBody.trim().isEmpty ? fallback : responseBody.trim();
  }
}

/// Парсит ответ API и проверяет успешность.
/// Возвращает true для успеха, false и message для ошибок.
({bool success, String message}) parseApiResponse(String responseBody, {
  String fallbackMessage = 'Unknown error'
}) {
  try {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final success = data['success'] == true;
    final message = data['message']?.toString() ?? fallbackMessage;
    return (success: success, message: message);
  } catch (_) {
    return (success: false, message: responseBody.trim().isNotEmpty
        ? responseBody.trim()
        : fallbackMessage);
  }
}

/// Парсит ответ API с дополнительными данными.
/// Возвращает success, message и карту данных.
({bool success, String message, Map<String, dynamic> data}) parseApiResponseWithData(String responseBody, {
  String fallbackMessage = 'Unknown error'
}) {
  try {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final success = data['success'] == true;
    final message = data['message']?.toString() ?? fallbackMessage;
    final responseData = Map<String, dynamic>.from(data)..remove('success')..remove('message');
    return (success: success, message: message, data: responseData);
  } catch (_) {
    return (success: false, message: responseBody.trim().isNotEmpty
        ? responseBody.trim()
        : fallbackMessage, data: {});
  }
}