import 'package:flutter/material.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const String _keyUsername = 'session_username';
  static const String _keyRole = 'session_role';
  static const String _keyTimId = 'session_tim_id';
  static const String _keyThemeMode = 'app_theme_mode';

  /// Save active user session to SharedPreferences
  static Future<void> saveSession(UserSessionState session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, session.username);
    await prefs.setString(_keyRole, session.role);
    if (session.timId != null) {
      await prefs.setInt(_keyTimId, session.timId!);
    } else {
      await prefs.remove(_keyTimId);
    }
  }

  /// Load saved user session from SharedPreferences
  static Future<UserSessionState?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername);
    final role = prefs.getString(_keyRole);
    final timId = prefs.getInt(_keyTimId);

    if (username != null &&
        username.isNotEmpty &&
        role != null &&
        role.isNotEmpty) {
      return UserSessionState(
        username: username,
        role: role,
        timId: timId,
      );
    }
    return null;
  }

  /// Clear saved session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyTimId);
  }

  /// Save selected theme mode
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  /// Load saved theme mode
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_keyThemeMode);
    if (modeName == 'dark') return ThemeMode.dark;
    if (modeName == 'light') return ThemeMode.light;
    return ThemeMode.light;
  }
}
