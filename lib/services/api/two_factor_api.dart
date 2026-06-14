import 'package:flutter_project/services/localization/app_localizations.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_logger.dart';
import '../storage/auth_storage.dart';
import 'api_config.dart';
import 'app_http_client.dart';

/// Базовое исключение слоя 2FA - сообщение и HTTP-код.
class TwoFactorException implements Exception {
  TwoFactorException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// 400 - неверный код, истёк OTP или backup-код уже использован.
class TwoFactorInvalidCodeException extends TwoFactorException {
  TwoFactorInvalidCodeException(super.message) : super(statusCode: 400);
}

/// 410 - pending session логина истёк или превысил лимит попыток.
class TwoFactorChallengeExpiredException extends TwoFactorException {
  TwoFactorChallengeExpiredException(super.message)
    : super(statusCode: 410);
}

/// 429 - rate-limit на enable lockout, resend cooldown или verify.
class TwoFactorRateLimitException extends TwoFactorException {
  TwoFactorRateLimitException(super.message) : super(statusCode: 429);
}

/// 403 - роль пользователя не позволяет выполнять admin-disable.
class TwoFactorForbiddenException extends TwoFactorException {
  TwoFactorForbiddenException(super.message) : super(statusCode: 403);
}

/// 401 - отсутствует X-User-Id или сессия невалидна.
class TwoFactorUnauthorizedException extends TwoFactorException {
  TwoFactorUnauthorizedException(super.message) : super(statusCode: 401);
}

/// Статус 2FA для текущего или целевого пользователя.
class TwoFactorStatus {
  const TwoFactorStatus({
    required this.enabled,
    required this.backupCodesRemaining,
  });

  final bool enabled;
  final int backupCodesRemaining;

  factory TwoFactorStatus.fromJson(Map<String, dynamic> json) {
    return TwoFactorStatus(
      enabled: json['enabled'] == true,
      backupCodesRemaining: _asInt(json['backupCodesRemaining']) ?? 0,
    );
  }
}

/// Минимальная проекция user из ответа /login.
class TwoFactorUserSession {
  const TwoFactorUserSession({
    required this.userId,
    required this.email,
    required this.role,
    this.name,
    this.supplierName,
  });

  final int userId;
  final String email;
  final String role;
  final String? name;
  final String? supplierName;

  factory TwoFactorUserSession.fromJson(Map<String, dynamic> json) {
    return TwoFactorUserSession(
      userId: _asInt(json['id']) ?? _asInt(json['userId']) ?? 0,
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'buyer',
      name: json['name']?.toString(),
      supplierName: json['supplierName']?.toString(),
    );
  }
}

/// Результат POST /auth/2fa/verify: пользователь, опциональный device-token, остаток backup-кодов.
class TwoFactorLoginResult {
  const TwoFactorLoginResult({
    required this.user,
    required this.deviceToken,
    required this.backupCodesRemaining,
  });

  final TwoFactorUserSession user;
  final String? deviceToken;
  final int backupCodesRemaining;
}

/// Клиентская обёртка над 2FA-эндпоинтами; логин-расширение живёт в LoginPage.
class TwoFactorApi {
  TwoFactorApi._();

  static const String _scope = 'two_factor_api';

  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<TwoFactorStatus> getStatus({int? targetUserId}) async {
    final query = <String, String>{};
    if (targetUserId != null && targetUserId > 0) {
      query['targetUserId'] = targetUserId.toString();
    }
    final uri = Uri.parse(
      '$_baseUrl/auth/2fa/status',
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await AppHttpClient.instance.get(
      uri,
      headers: await _ownerHeaders(),
    );
    final data = _parseResponse(response);
    return TwoFactorStatus.fromJson(data ?? const {});
  }

  static Future<void> requestEnable() async {
    final response = await _formPost(
      '/auth/2fa/enable/request',
      body: const {},
    );
    _parseResponse(response);
  }

  // Возвращает 10 backup-кодов в открытом виде - показываем единожды.
  static Future<List<String>> verifyEnable(String code) async {
    final response = await _formPost(
      '/auth/2fa/enable/verify',
      body: {'code': code},
    );
    final data = _parseResponse(response);
    return _readBackupCodes(data);
  }

  static Future<void> requestDisable() async {
    final response = await _formPost(
      '/auth/2fa/disable/request',
      body: const {},
    );
    _parseResponse(response);
  }

  // Scope-специфичный канал OTP для регенерации backup-кодов.
  static Future<void> requestRegenerateBackupCodes() async {
    final response = await _formPost(
      '/auth/2fa/backup-codes/request',
      body: const {},
    );
    _parseResponse(response);
  }

  // Scope-специфичный канал OTP для отзыва доверенных устройств.
  static Future<void> requestRevokeTrustedDevices() async {
    final response = await _formPost(
      '/auth/2fa/trusted-devices/request',
      body: const {},
    );
    _parseResponse(response);
  }

  static Future<void> verifyDisable(String code) async {
    final response = await _formPost(
      '/auth/2fa/disable/verify',
      body: {'code': code},
    );
    _parseResponse(response);
  }

  // X-User-Id не нужен - пользователь ещё не авторизован.
  static Future<TwoFactorLoginResult> verifyLogin({
    required String challengeId,
    String? code,
    String? backupCode,
    bool rememberDevice = false,
  }) async {
    final body = <String, String>{'challengeId': challengeId};
    if (code != null && code.isNotEmpty) {
      body['code'] = code;
    }
    if (backupCode != null && backupCode.isNotEmpty) {
      body['backupCode'] = backupCode;
    }
    if (rememberDevice) {
      body['rememberDevice'] = 'true';
    }
    final response = await _formPost(
      '/auth/2fa/verify',
      body: body,
      includeOwnerHeader: false,
    );
    final data = _parseResponse(response) ?? const <String, dynamic>{};
    final userJson = data['user'];
    if (userJson is! Map) {
      throw TwoFactorException(
        AppLocalizations.current.getString('auto_server_vernul_pustye_dannye_polzova'),
      );
    }
    return TwoFactorLoginResult(
      user: TwoFactorUserSession.fromJson(Map<String, dynamic>.from(userJson)),
      deviceToken: data['deviceToken']?.toString(),
      backupCodesRemaining: _asInt(data['backupCodesRemaining']) ?? 0,
    );
  }

  static Future<void> resendChallenge(String challengeId) async {
    final response = await _formPost(
      '/auth/2fa/resend',
      body: {'challengeId': challengeId},
      includeOwnerHeader: false,
    );
    _parseResponse(response);
  }

  static Future<List<String>> regenerateBackupCodes(String code) async {
    final response = await _formPost(
      '/auth/2fa/backup-codes/regenerate',
      body: {'code': code},
    );
    final data = _parseResponse(response);
    return _readBackupCodes(data);
  }

  static Future<void> revokeAllTrustedDevices(String code) async {
    final response = await _formPost(
      '/auth/2fa/trusted-devices/revoke-all',
      body: {'code': code},
    );
    _parseResponse(response);
  }

  // X-User-Id указывает модератора-актора.
  static Future<void> adminDisable(int targetUserId) async {
    final response = await _formPost(
      '/auth/2fa/admin-disable',
      body: {'userId': targetUserId.toString()},
    );
    _parseResponse(response);
  }

  // x-www-form-urlencoded; X-User-Id - по требованию.
  static Future<http.Response> _formPost(
    String path, {
    required Map<String, String> body,
    bool includeOwnerHeader = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
    };
    if (includeOwnerHeader) {
      headers.addAll(await _ownerHeaders());
    }
    return AppHttpClient.instance.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      encoding: utf8,
      body: body,
    );
  }

  // X-User-Id из AuthStorage; пустое - 401 на сервере.
  static Future<Map<String, String>> _ownerHeaders() async {
    final userId = AuthStorage.userId;
    if (userId == null || userId <= 0) {
      return const {};
    }
    return {'X-User-Id': userId.toString()};
  }

  // Разбор конверта {success, message, data} с маппингом статусов в исключения.
  static Map<String, dynamic>? _parseResponse(http.Response response) {
    final status = response.statusCode;
    final raw = utf8.decode(response.bodyBytes, allowMalformed: true).trim();

    Map<String, dynamic>? envelope;
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          envelope = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        AppLogger.warning(
          'Не удалось распарсить тело 2FA-ответа: $e',
          scope: _scope,
        );
      }
    }

    final message = envelope?['message']?.toString() ?? _defaultMessage(status);
    final dynamic dataNode = envelope?['data'];
    final data = dataNode is Map ? Map<String, dynamic>.from(dataNode) : null;

    if (status >= 200 && status < 300 && envelope?['success'] == true) {
      return data;
    }

    switch (status) {
      case 400:
        throw TwoFactorInvalidCodeException(message);
      case 401:
        throw TwoFactorUnauthorizedException(message);
      case 403:
        throw TwoFactorForbiddenException(message);
      case 410:
        throw TwoFactorChallengeExpiredException(message);
      case 429:
        throw TwoFactorRateLimitException(message);
      default:
        throw TwoFactorException(message, statusCode: status);
    }
  }

  static List<String> _readBackupCodes(Map<String, dynamic>? data) {
    final list = data?['backupCodes'];
    if (list is! List) {
      return const [];
    }
    return list.map((e) => e.toString()).toList(growable: false);
  }

  static String _defaultMessage(int status) {
    switch (status) {
      case 400:
        return AppLocalizations.current.getString('auto_nevernyy_kod_ili_istk_srok_deystviy');
      case 401:
        return AppLocalizations.current.getString('auto_trebuetsya_avtorizatsiya');
      case 403:
        return AppLocalizations.current.getString('auto_deystvie_nedostupno_dlya_vashey_rol');
      case 410:
        return AppLocalizations.current.getString('auto_srok_deystviya_koda_istk_povtorite');
      case 429:
        return AppLocalizations.current.getString('auto_slishkom_mnogo_popytok_poprobuyte_p');
      default:
        return 'Не удалось выполнить запрос (HTTP $status)';
    }
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
