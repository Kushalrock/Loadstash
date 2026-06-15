import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyStarterSeeded = 'starter_seeded';

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  static Future<bool> isStarterSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyStarterSeeded) ?? false;
  }

  static Future<void> markStarterSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStarterSeeded, true);
  }

  // Quick add save location
  static const _keyQuickAddPath = 'quick_add_path';

  static Future<List<String>> getQuickAddPath() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyQuickAddPath);
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  static Future<void> setQuickAddPath(List<String> path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuickAddPath, jsonEncode(path));
  }

  // Theme mode
  static const _keyThemeMode = 'theme_mode';

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'dark';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }
}
