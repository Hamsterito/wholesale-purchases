import 'dart:convert';

/// Parses API response and returns the message field for user display.
/// Handles both success and error responses.
String parseApiMessage(String responseBody, {String fallback = 'Unknown error'}) {
  try {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    return data['message']?.toString() ?? fallback;
  } catch (_) {
    return responseBody.trim().isEmpty ? fallback : responseBody.trim();
  }
}

/// Parses API response and checks if it was successful.
/// Returns true for success: false, message for errors.
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