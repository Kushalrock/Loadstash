import 'package:flutter/material.dart';
import '../../services/model_tag_service.dart';

abstract final class AppColors {
  // Dark palette
  static const bgBase = Color(0xFF0E0F12);
  static const surface1 = Color(0xFF16181D);
  static const surface2 = Color(0xFF1B1E24);
  static const borderHairline = Color(0x12FFFFFF);   // 7% white
  static const borderHairline2 = Color(0x0DFFFFFF);  // 5% white — subtler
  static const textPrimary = Color(0xFFECEEF2);
  static const textSecondary = Color(0xFF9BA0AA);
  static const textTertiary = Color(0xFF686D78);
  static const accent = Color(0xFF8B7DF6);
  static const accentText = Color(0xFFB9AEFF);       // lighter accent for icons/text
  static const accentTint = Color(0x238B7DF6);       // 14% accent
  static const accentDim = Color(0x4D8B7DF6);        // 30% accent — active borders
  static const confirm = Color(0xFF5BC58F);
  static const confirmTint = Color(0x215BC58F);      // 13% success bg

  // Light palette
  static const bgBaseLight = Color(0xFFFAFAF8);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFF0F0EE);
  static const textPrimaryLight = Color(0xFF1A1B1E);
  static const textSecondaryLight = Color(0xFF545B6A);
  static const textTertiaryLight = Color(0xFF909099);
  static const borderLight = Color(0x14000000);
  static const accentLight = Color(0xFF6F5EE0);
  static const accentTextLight = Color(0xFF5547CC);
  static const accentLightTint = Color(0x236F5EE0);
  static const accentDimLight = Color(0x4D6F5EE0);

  // Model tag colors — actual brand colors
  static const modelClaude = Color(0xFFD97757);   // Anthropic orange
  static const modelChatGpt = Color(0xFF10A37F);  // OpenAI green
  static const modelGemini = Color(0xFF5B9CF6);   // Google blue
  static const modelLocal = Color(0xFF8A909C);    // neutral grey

  // Model color by key — delegates to ModelTagService for user-customisable colours
  static Color forModel(String key) => ModelTagService.colorForKey(key);
}
