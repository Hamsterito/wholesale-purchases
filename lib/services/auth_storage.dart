import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  AuthStorage._();

  static const _rememberKey = 'auth_remember_me';
  static const _emailKey = 'auth_email';
  static const _roleKey = 'auth_role';
  static const _userIdKey = 'auth_user_id';
  static const _nameKey = 'auth_name';
  static const _supplierNameKey = 'auth_supplier_name';
  static const _selectedAddressKeyPrefix = 'selected_address_id_';

  static bool _remembered = false;
  static String? _email;
  static String? _role;
  static int? _userId;
  static String? _name;
  static String? _supplierName;
  static int? _selectedAddressId;

  static bool get isRemembered => _remembered;
  static String? get email => _email;
  static String? get role => _role;
  static int? get userId => _userId;
  static String? get name => _name;
  static String? get supplierName => _supplierName;
  static int? get selectedAddressId => _selectedAddressId;

  static String _selectedAddressKey(int userId) =>
      '$_selectedAddressKeyPrefix$userId';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _remembered = prefs.getBool(_rememberKey) ?? false;
    _email = prefs.getString(_emailKey);
    _role = prefs.getString(_roleKey);
    _userId = prefs.getInt(_userIdKey);
    _name = prefs.getString(_nameKey);
    _supplierName = prefs.getString(_supplierNameKey);
    if (_userId != null && _userId! > 0) {
      _selectedAddressId = prefs.getInt(_selectedAddressKey(_userId!));
    } else {
      _selectedAddressId = null;
    }
  }

  static Future<void> remember({
    required String email,
    required String role,
    required int userId,
    String? name,
    String? supplierName,
  }) async {
    _remembered = true;
    _email = email;
    _role = role;
    _userId = userId;
    _name = name;
    _supplierName = supplierName;
    final prefs = await SharedPreferences.getInstance();
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
    _selectedAddressId = prefs.getInt(_selectedAddressKey(userId));
  }

  static Future<void> setSession({
    required String email,
    required String role,
    required int userId,
    String? name,
    String? supplierName,
  }) async {
    _email = email;
    _role = role;
    _userId = userId;
    _name = name;
    _supplierName = supplierName;
    final prefs = await SharedPreferences.getInstance();
    _selectedAddressId = prefs.getInt(_selectedAddressKey(userId));
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

    final prefs = await SharedPreferences.getInstance();

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

  static Future<void> forget() async {
    _remembered = false;
    _email = null;
    _role = null;
    _userId = null;
    _name = null;
    _supplierName = null;
    _selectedAddressId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, false);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_supplierNameKey);
  }

  static Future<void> saveSelectedAddressId(int? addressId) async {
    final currentUserId = _userId;
    _selectedAddressId = addressId;
    if (currentUserId == null || currentUserId <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _selectedAddressKey(currentUserId);
    if (addressId == null || addressId <= 0) {
      await prefs.remove(key);
      _selectedAddressId = null;
      return;
    }

    await prefs.setInt(key, addressId);
  }
}
