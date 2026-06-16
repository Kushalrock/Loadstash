import 'package:flutter/material.dart';
import 'app_colors.dart';

extension AppContextColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cBgBase     => _isDark ? AppColors.bgBase          : AppColors.bgBaseLight;
  Color get cSurface1   => _isDark ? AppColors.surface1        : AppColors.surfaceLight;
  Color get cSurface2   => _isDark ? AppColors.surface2        : AppColors.surface2Light;
  Color get cText1      => _isDark ? AppColors.textPrimary     : AppColors.textPrimaryLight;
  Color get cText2      => _isDark ? AppColors.textSecondary   : AppColors.textSecondaryLight;
  Color get cText3      => _isDark ? AppColors.textTertiary    : AppColors.textTertiaryLight;
  Color get cBorder     => _isDark ? AppColors.borderHairline  : AppColors.borderLight;
  Color get cBorder2    => _isDark ? AppColors.borderHairline2 : AppColors.borderLight;
  Color get cAccent     => _isDark ? AppColors.accent          : AppColors.accentLight;
  Color get cAccentText => _isDark ? AppColors.accentText      : AppColors.accentTextLight;
  Color get cAccentTint => _isDark ? AppColors.accentTint      : AppColors.accentLightTint;
  Color get cAccentDim  => _isDark ? AppColors.accentDim       : AppColors.accentDimLight;

  // Transparent-value tokens that flip polarity between themes
  Color get cSheetHandle  => _isDark ? const Color(0x2EFFFFFF) : const Color(0x18000000);
  Color get cTagBorder    => _isDark ? const Color(0x33FFFFFF) : const Color(0x25000000);
  Color get cCodeBg       => _isDark ? const Color(0x0DFFFFFF) : const Color(0x0A000000);
  Color get cIconBg       => _isDark ? const Color(0x0DFFFFFF) : const Color(0x0C000000);
  Color get cToggleBgOff  => _isDark ? const Color(0x14FFFFFF) : const Color(0x12000000);
}
