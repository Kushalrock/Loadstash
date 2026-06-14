import 'package:flutter/material.dart';

abstract final class AppColors {
  // Dark palette
  static const bgBase = Color(0xFF0E0F12);
  static const surface1 = Color(0xFF16181D);
  static const surface2 = Color(0xFF1B1E24);
  static const borderHairline = Color(0x12FFFFFF);
  static const textPrimary = Color(0xFFECEEF2);
  static const textSecondary = Color(0xFF9BA0AA);
  static const textTertiary = Color(0xFF686D78);
  static const accent = Color(0xFF8B7DF6);
  static const accentTint = Color(0x238B7DF6);
  static const confirm = Color(0xFF5BC58F);

  // Light palette
  static const bgBaseLight = Color(0xFFFAFAF8);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF1A1B1E);
  static const textTertiaryLight = Color(0xFFA0A0A0);
  static const borderLight = Color(0x14000000);
  static const accentLight = Color(0xFF6F5EE0);
  static const accentLightTint = Color(0x236F5EE0);

  // Model tag colors
  static const modelClaude = Color(0xFFC98A5E);
  static const modelChatGpt = Color(0xFF4FB58B);
  static const modelGemini = Color(0xFF5B8DEF);
  static const modelLocal = Color(0xFFB98BD4);
}
