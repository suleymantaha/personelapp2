import 'package:flutter/material.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const String _keyUsername = 'session_username';
  static const String _legacyKeyRole = 'session_role';
  static const String _legacyKeyTimId = 'session_tim_id';
  static const String _keyThemeMode = 'app_theme_mode';

  /// Persists only the stable account identifier.
  ///
  /// Role and team authorization are intentionally resolved from the database
  /// on every application start instead of trusting editable preferences.
  static Future<void> saveSession(UserSessionState session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, session.username);
    await prefs.remove(_legacyKeyRole);
    await prefs.remove(_legacyKeyTimId);
  }

  static Future<UserSessionState?> loadValidatedSession(
    AppDatabase database,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername)?.trim();
    if (username == null || username.isEmpty) {
      await clearSession();
      return null;
    }

    final user = await (database.select(
      database.kullaniciTable,
    )..where((table) => table.kullaniciAdi.equals(username)))
        .getSingleOrNull();
    final role = user == null ? null : UserRole.fromStorageValue(user.rol);
    if (user == null || role == null) {
      await clearSession();
      return null;
    }

    var teamId = user.timId;
    if (role == UserRole.teamCommander && teamId == null) {
      final squad = await (database.select(
        database.timTable,
      )..where((table) => table.timKomutaniId.equals(user.id)))
          .getSingleOrNull();
      teamId = squad?.id;
    }

    return UserSessionState(
      username: user.kullaniciAdi,
      role: role,
      timId: teamId,
    );
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_legacyKeyRole);
    await prefs.remove(_legacyKeyTimId);
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_keyThemeMode);
    if (modeName == 'dark') return ThemeMode.dark;
    if (modeName == 'light') return ThemeMode.light;
    if (modeName == 'system') return ThemeMode.system;
    return ThemeMode.light;
  }
}
