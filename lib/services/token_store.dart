import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _kToken = 'auth_token';
  static const _kEmail = 'auth_email';

  Future<void> saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kToken, token);
  }

  Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString(_kToken);
    if (t == null || t.trim().isEmpty) return null;
    return t;
  }

  Future<void> clearToken() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kToken);
  }

  Future<void> saveEmail(String email) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kEmail, email);
  }

  Future<String?> getEmail() async {
    final sp = await SharedPreferences.getInstance();
    final e = sp.getString(_kEmail);
    if (e == null || e.trim().isEmpty) return null;
    return e;
  }

  Future<void> clearEmail() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kEmail);
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kToken);
    await sp.remove(_kEmail);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
