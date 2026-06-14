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
}
