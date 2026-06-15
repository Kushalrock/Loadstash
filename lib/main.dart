import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'services/model_tag_service.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ModelTagService.initialize();
  final savedTheme = await PreferencesService.getThemeMode();
  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark,
        ),
      ],
      child: const LoadstashApp(),
    ),
  );
}
