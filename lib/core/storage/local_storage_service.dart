import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_session.dart';

class LocalStorageService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _rolesKey = 'user_roles';

  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_userIdKey, session.userId);
    await prefs.setString(_usernameKey, session.username);
    await prefs.setStringList(_rolesKey, session.roles);
  }

  Future<AuthSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userId = prefs.getString(_userIdKey);
    final username = prefs.getString(_usernameKey);
    final roles = prefs.getStringList(_rolesKey);

    if (token == null ||
        userId == null ||
        username == null ||
        roles == null ||
        roles.isEmpty) {
      return null;
    }

    return AuthSession(
      token: token,
      userId: userId,
      username: username,
      roles: roles,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_rolesKey);
  }
}
