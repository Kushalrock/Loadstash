import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/seeds/starter_prompts.dart';
import '../../providers/repository_providers.dart';
import '../../services/preferences_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _seeding = true);

    final alreadySeeded = await PreferencesService.isStarterSeeded();
    if (!alreadySeeded) {
      final repo = ref.read(promptRepositoryProvider);
      for (final p in kStarterPrompts) {
        await repo.create(
          title: p['title']!,
          body: p['body']!,
          modelTags: p['modelTags']!,
          isStarter: true,
        );
      }
      await PreferencesService.markStarterSeeded();
    }

    await PreferencesService.markOnboardingDone();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'loadstash',
                style: AppTypography.screenTitle.copyWith(
                  fontSize: 32,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your prompts, ready in any app.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('How to use', style: AppTypography.label),
                    const SizedBox(height: 24),
                    SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Text(
                          'loadstash',
                          style: AppTypography.label
                              .copyWith(color: AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '1. Select text in any app\n2. Tap loadstash in the menu\n3. Pick a prompt → it\'s inserted',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _seeding
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.accent))
                  : FilledButton(
                      onPressed: _finish,
                      child: const Text('Get started'),
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
