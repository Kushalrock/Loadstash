import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/library/library_screen.dart';
import 'features/overlay/overlay_screen.dart';
import 'features/editor/editor_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/tags_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/prompt_detail/prompt_detail_screen.dart';
import 'services/preferences_service.dart';

final _router = GoRouter(
  redirect: (context, state) async {
    if (state.matchedLocation == '/overlay') return null;
    if (state.matchedLocation == '/bubble-overlay') return null;
    if (state.matchedLocation == '/prompt') return null;
    final done = await PreferencesService.isOnboardingDone();
    if (!done) return '/onboarding';
    return null;
  },
  routes: [
    GoRoute(path: '/overlay', builder: (_, __) => const OverlayScreen()),
    GoRoute(
      path: '/bubble-overlay',
      builder: (_, __) => const OverlayScreen(mode: OverlayMode.bubble),
    ),
    GoRoute(
      path: '/prompt',
      builder: (_, state) => PromptDetailScreen(promptId: state.extra as int),
    ),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const LibraryScreen()),
        GoRoute(
          path: '/editor',
          builder: (_, state) => EditorScreen(promptId: state.extra as int?),
        ),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/tags', builder: (_, __) => const TagsScreen()),
      ],
    ),
  ],
);

class LoadstashApp extends ConsumerWidget {
  const LoadstashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Loadstash',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    (path: '/', icon: Icons.grid_view_rounded, label: 'Library'),
    (path: '/settings', icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          context.go(_tabs[i].path);
        },
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
