import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  AuthStorage._();

  static const _rememberKey = 'auth_remember_me';
  static const _emailKey = 'auth_email';

  static bool _remembered = false;
  static String? _email;

  static bool get isRemembered => _remembered;
  static String? get email => _email;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _remembered = prefs.getBool(_rememberKey) ?? false;
    _email = prefs.getString(_emailKey);
  }

  static Future<void> remember({required String email}) async {
    _remembered = true;
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, true);
    await prefs.setString(_emailKey, email);
  }

  static Future<void> forget() async {
    _remembered = false;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, false);
    await prefs.remove(_emailKey);
  }
}
