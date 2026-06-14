import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loadstash/core/theme/app_colors.dart';
import 'package:loadstash/core/theme/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // Helper to capture theme synchronously while swallowing async google_fonts
  // font-load errors that fire after the test body completes.
  T _captureTheme<T>(T Function() fn) {
    late T result;
    runZonedGuarded(
      () => result = fn(),
      (e, _) {
        // swallow google_fonts async font-load exceptions only
        if (!e.toString().contains('google_fonts') &&
            !e.toString().contains('GoogleFonts')) {
          throw e;
        }
      },
    );
    return result;
  }

  test('dark theme scaffold background is bgBase', () {
    final bg = _captureTheme(() => AppTheme.dark.scaffoldBackgroundColor);
    expect(bg, AppColors.bgBase);
  });

  test('dark theme primary color is accent', () {
    final primary = _captureTheme(() => AppTheme.dark.colorScheme.primary);
    expect(primary, AppColors.accent);
  });

  test('bgBase is not pure black', () {
    expect(AppColors.bgBase, isNot(const Color(0xFF000000)));
  });

  test('accent has periwinkle-like tone', () {
    const c = AppColors.accent;
    expect(c.red, greaterThan(100));
    expect(c.blue, greaterThan(200));
    expect(c.green, lessThan(150));
  });
}
