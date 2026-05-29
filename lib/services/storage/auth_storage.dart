import 'shared_prefs_provider.dart';

class AuthStorage {
  AuthStorage._();

  static const _rememberKey = 'auth_remember_me';
  static const _emailKey = 'auth_email';
  static const _roleKey = 'auth_role';
  static const _userIdKey = 'auth_user_id';
  static const _nameKey = 'auth_name';
  static const _supplierNameKey = 'auth_supplier_name';
  static const _avatarUrlKey = 'auth_avatar_url';
  static const _selectedAddressKeyPrefix = 'selected_address_id_';
  static const _deviceTokenKeyPrefix = 'device_token_';
  static const _deviceTokenEmailKeyPrefix = 'device_token_email_';

  static bool _remembered = false;
  static String? _email;
  static String? _role;
  static int? _userId;
  static String? _name;
  static String? _supplierName;
  static String? _avatarUrl;
  static int? _selectedAddressId;

  static bool get isRemembered => _remembered;
  static String? get email => _email;
  static String? get role => _role;
  static int? get userId => _userId;
  static String? get name => _name;
  static String? get supplierName => _supplierName;
  static String? get avatarUrl => _avatarUrl;
  static int? get selectedAddressId => _selectedAddressId;

  // Пустую строку нормализуем в null - сервер может прислать "" вместо null.
  static String? _normalizeAvatarUrl(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // Хелпер для UI: проверка роли главного администратора без преобразования
  // самой сохранённой роли
  static bool get isSuperAdmin => _role?.trim().toLowerCase() == 'super_admin';

  static String _selectedAddressKey(int userId) =>
      '$_selectedAddressKeyPrefix$userId';

  static String _deviceTokenKey(int userId) => '$_deviceTokenKeyPrefix$userId';

  static String _deviceTokenEmailKey(String email) =>
      '$_deviceTokenEmailKeyPrefix${_normalizeEmail(email)}';

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  // Инициализация хранилища аутентификации
  // Вызывается в main() ДО runApp для предотвращения ошибок зоны
  static Future<void> init() async {
    try {
      final prefs = await SharedPrefsProvider.getInstance();
      _remembered = prefs.getBool(_rememberKey) ?? false;
      _email = prefs.getString(_emailKey);
      _role = prefs.getString(_roleKey);
      _userId = prefs.getInt(_userIdKey);
      _name = prefs.getString(_nameKey);
      _supplierName = prefs.getString(_supplierNameKey);
      _avatarUrl = _normalizeAvatarUrl(prefs.getString(_avatarUrlKey));

      // Безопасная инициализация selectedAddressId
      if (_userId != null && _userId! > 0) {
        _selectedAddressId = prefs.getInt(_selectedAddressKey(_userId!));
      } else {
        _selectedAddressId = null;
      }
    } catch (e) {
      // В случае ошибки инициализации сбрасываем все значения
      _remembered = false;
      _email = null;
      _role = null;
      _userId = null;
      _name = null;
      _supplierName = null;
      _avatarUrl = null;
      _selectedAddressId = null;
      rethrow;
    }
  }

  static Future<void> remember({
    required String email,
    required String role,
    required int userId,
    String? name,
    String? supplierName,
    String? avatarUrl,
  }) async {
    _remembered = true;
    _email = email;
    _role = role;
    _userId = userId;
    _name = name;
    _supplierName = supplierName;
    _avatarUrl = _normalizeAvatarUrl(avatarUrl);
    final prefs = await SharedPrefsProvider.getInstance();
    await prefs.setBool(_rememberKey, true);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_roleKey, role);
    await prefs.setInt(_userIdKey, userId);
    if (name != null) {
      await prefs.setString(_nameKey, name);
    } else {
      await prefs.remove(_nameKey);
    }
    if (supplierName != null) {
      await prefs.setString(_supplierNameKey, supplierName);
    } else {
      await prefs.remove(_supplierNameKey);
    }
    if (_avatarUrl != null) {
      await prefs.setString(_avatarUrlKey, _avatarUrl!);
    } else {
      await prefs.remove(_avatarUrlKey);
    }
    _selectedAddressId = prefs.getInt(_selectedAddressKey(userId));
  }

  static Future<void> setSession({
    required String email,
    required String role,
    required int userId,
    String? name,
    String? supplierName,
    String? avatarUrl,
  }) async {
    _email = email;
    _role = role;
    _userId = userId;
    _name = name;
    _supplierName = supplierName;
    _avatarUrl = _normalizeAvatarUrl(avatarUrl);
    final prefs = await SharedPrefsProvider.getInstance();
    _selectedAddressId = prefs.getInt(_selectedAddressKey(userId));
  }

  // Точечное обновление avatarUrl - после загрузки/удаления через профиль.
  // Если пользователь не remembered, обновляем только in-memory значение.
  static Future<void> setAvatarUrl(String? value) async {
    _avatarUrl = _normalizeAvatarUrl(value);
    if (!_remembered) {
      return;
    }
    final prefs = await SharedPrefsProvider.getInstance();
    if (_avatarUrl == null) {
      await prefs.remove(_avatarUrlKey);
    } else {
      await prefs.setString(_avatarUrlKey, _avatarUrl!);
    }
  }

  static Future<void> updateProfile({
    String? name,
    String? email,
    String? supplierName,
  }) async {
    if (name != null) {
      _name = name;
    }
    if (email != null) {
      _email = email;
    }
    if (supplierName != null) {
      _supplierName = supplierName;
    }

    if (!_remembered) {
      return;
    }

    final prefs = await SharedPrefsProvider.getInstance();

    if (name != null) {
      if (name.isEmpty) {
        await prefs.remove(_nameKey);
      } else {
        await prefs.setString(_nameKey, name);
      }
    }

    if (email != null) {
      if (email.isEmpty) {
        await prefs.remove(_emailKey);
      } else {
        await prefs.setString(_emailKey, email);
      }
    }

    if (supplierName != null) {
      if (supplierName.isEmpty) {
        await prefs.remove(_supplierNameKey);
      } else {
        await prefs.setString(_supplierNameKey, supplierName);
      }
    }
  }

  // Device-токен 2FA намеренно НЕ трогаем - доверенное устройство должно
  // переживать обычный выход, иначе «запомнить устройство» теряет смысл.
  // Токен отзывается только сервером (смена пароля, отключение 2FA, ручной
  // отзыв) либо через явный clearDeviceToken.
  static Future<void> forget() async {
    _remembered = false;
    _email = null;
    _role = null;
    _userId = null;
    _name = null;
    _supplierName = null;
    _avatarUrl = null;
    _selectedAddressId = null;
    final prefs = await SharedPrefsProvider.getInstance();
    await prefs.setBool(_rememberKey, false);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_supplierNameKey);
    await prefs.remove(_avatarUrlKey);
  }

  static Future<void> saveSelectedAddressId(int? addressId) async {
    final currentUserId = _userId;
    _selectedAddressId = addressId;
    if (currentUserId == null || currentUserId <= 0) {
      return;
    }

    final prefs = await SharedPrefsProvider.getInstance();
    final key = _selectedAddressKey(currentUserId);
    if (addressId == null || addressId <= 0) {
      await prefs.remove(key);
      _selectedAddressId = null;
      return;
    }

    await prefs.setInt(key, addressId);
  }

  // Device-токен 2FA: храним под двумя ключами - по userId (после логина)
  // и по нормализованному email (чтобы подставить X-Device-Token до логина,
  // когда userId ещё неизвестен).
  static Future<void> setDeviceToken({
    required int userId,
    required String email,
    required String token,
  }) async {
    final prefs = await SharedPrefsProvider.getInstance();
    await prefs.setString(_deviceTokenKey(userId), token);
    final normalized = _normalizeEmail(email);
    if (normalized.isNotEmpty) {
      await prefs.setString(_deviceTokenEmailKey(normalized), token);
    }
  }

  static Future<String?> getDeviceTokenForLogin(String email) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty) {
      return null;
    }
    final prefs = await SharedPrefsProvider.getInstance();
    return prefs.getString(_deviceTokenEmailKey(normalized));
  }

  static Future<String?> getDeviceTokenForUser(int userId) async {
    if (userId <= 0) {
      return null;
    }
    final prefs = await SharedPrefsProvider.getInstance();
    return prefs.getString(_deviceTokenKey(userId));
  }

  static Future<void> clearDeviceToken(int userId, {String? email}) async {
    final prefs = await SharedPrefsProvider.getInstance();
    if (userId > 0) {
      await prefs.remove(_deviceTokenKey(userId));
    }
    if (email != null) {
      final normalized = _normalizeEmail(email);
      if (normalized.isNotEmpty) {
        await prefs.remove(_deviceTokenEmailKey(normalized));
      }
    }
  }
}
