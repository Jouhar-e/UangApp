import 'package:shared_preferences/shared_preferences.dart';

/// Cache ringan agar app tahu user pernah login (bantu restore sesi Google).
class AuthSessionStore {
  static const _keyEmail = 'auth_last_email';

  Future<void> saveEmail(String email) async {
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  Future<String?> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    return (email != null && email.isNotEmpty) ? email : null;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
  }
}
