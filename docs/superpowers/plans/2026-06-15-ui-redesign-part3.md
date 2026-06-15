# UI Redesign Part 3 — Onboarding, Settings, Tags, Overlay
## Tasks 8–11

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Run AFTER Part 2 is complete.

**Goal:** Redesign the onboarding screen (5-step chat flow with animated demo card), rebuild settings (launcher card + import/export + coming soon community section), add tags management screen, update overlay picker with model filter chips.

**Architecture:** Onboarding uses staggered FadeUpWidget animations; demo card cycles phases via a Timer. Settings and Tags are complete rewrites matching the design mockup. Overlay picker adds horizontal model filter chips and a quick-add sub-sheet.

**Tech Stack:** Flutter · Riverpod · animation primitives from Part 1 (`FadeUpWidget`, `BobWidget`, `RingWidget`, `AnimatedDot`, `BlinkingCursor`, `kSpring`)

---

## Task 8: Onboarding Redesign

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`

- [ ] **Step 1: Rewrite onboarding_screen.dart**

Read the current file first, then replace entirely:

```dart
// lib/features/onboarding/onboarding_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/animations.dart';
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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 1;
  bool _launcherOn = false;
  bool _permAccessibility = false;
  bool _permOverlay = false;
  bool _seeding = false;

  Future<void> _finish() async {
    setState(() => _seeding = true);
    final alreadySeeded = await PreferencesService.isStarterSeeded();
    if (!alreadySeeded) {
      final repo = ref.read(promptRepositoryProvider);
      for (final p in kStarterPrompts) {
        await repo.create(
          title: p['title'] as String,
          body: p['body'] as String,
          modelTags: p['modelTags'] as String? ?? '',
          path: List<String>.from(p['path'] as List? ?? const []),
          searchTags:
              List<String>.from(p['searchTags'] as List? ?? const []),
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
        child: Column(
          children: [
            // Dot progress + header
            _ObDots(step: _step),
            _ObHeader(
              step: _step,
              onSkip: _step < 5 ? () => context.go('/') : null,
            ),

            // Step body
            Expanded(child: _buildStepBody()),

            // Footer button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: _buildFooter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: switch (_step) {
          1 => _Step1(),
          2 => _Step2(
              launcherOn: _launcherOn,
              onToggle: (v) => setState(() => _launcherOn = v),
            ),
          3 => _Step3(
              permAccessibility: _permAccessibility,
              permOverlay: _permOverlay,
              onGrantAccessibility: () =>
                  setState(() => _permAccessibility = true),
              onGrantOverlay: () => setState(() => _permOverlay = true),
            ),
          4 => const _Step4(),
          _ => const _Step5(),
        },
      ),
    );
  }

  Widget _buildFooter() {
    if (_step == 2 && !_launcherOn) {
      return Opacity(
        opacity: 0.5,
        child: _PrimaryBtn(
          label: 'Turn it on to continue',
          icon: Icons.chevron_right,
          onTap: null,
        ),
      );
    }
    if (_step == 3 && (!_permAccessibility || !_permOverlay)) {
      return Opacity(
        opacity: 0.5,
        child: _PrimaryBtn(
          label: 'Grant both to continue',
          icon: Icons.chevron_right,
          onTap: null,
        ),
      );
    }
    if (_step == 5) {
      return _seeding
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _PrimaryBtn(
              label: 'Open Loadstash',
              icon: Icons.auto_awesome,
              onTap: _finish,
            );
    }
    return _PrimaryBtn(
      label: _step == 1 ? 'Get started' : 'Continue',
      icon: Icons.chevron_right,
      onTap: () => setState(() => _step++),
    );
  }
}

// ── Dot progress indicator ────────────────────────────────────
class _ObDots extends StatelessWidget {
  const _ObDots({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedDot(active: i + 1 == step, past: i + 1 < step),
          ),
        ),
      ),
    );
  }
}

// ── Header row ────────────────────────────────────────────────
class _ObHeader extends StatelessWidget {
  const _ObHeader({required this.step, this.onSkip});
  final int step;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accentTint,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.accentDim),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 16, color: AppColors.accentText),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Loadstash',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Text('Setup · about 20 seconds',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const Spacer(),
          if (onSkip != null)
            TextButton(
              onPressed: onSkip,
              child: const Text('Skip',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textTertiary)),
            ),
        ],
      ),
    );
  }
}

// ── Step 1: Welcome ───────────────────────────────────────────
class _Step1 extends StatelessWidget {
  const _Step1();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FadeUpWidget(
            delay: Duration.zero,
            child: _ObBubble("Hi — I'm Loadstash."),
          ),
          const SizedBox(height: 11),
          FadeUpWidget(
            delay: const Duration(milliseconds: 500),
            child: _ObBubble(
                'I keep your best prompts one tap away, inside any app on your phone.'),
          ),
          const SizedBox(height: 11),
          FadeUpWidget(
            delay: const Duration(milliseconds: 1100),
            child:
                _ObBubble("Two quick settings and you're set. Ready?"),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Launcher toggle ───────────────────────────────────
class _Step2 extends StatelessWidget {
  const _Step2({required this.launcherOn, required this.onToggle});
  final bool launcherOn;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeUpWidget(
            child: _ObBubble('First, turn on the launcher.'),
          ),
          const SizedBox(height: 14),
          FadeUpWidget(
            delay: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: kSpring,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: launcherOn
                      ? AppColors.accentDim
                      : AppColors.borderHairline,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentTint,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 21, color: AppColors.accentText),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Loadstash launcher',
                            style: TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w600)),
                        Text(
                          launcherOn ? 'On — the bubble is active' : 'Off',
                          style: TextStyle(
                            fontSize: 12,
                            color: launcherOn
                                ? AppColors.confirm
                                : AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ToggleSwitch(
                      value: launcherOn, onChanged: onToggle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeUpWidget(
            delay: const Duration(milliseconds: 500),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 16, color: AppColors.confirm),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Works entirely on your device. Loadstash reads nothing you type and sends nothing anywhere.',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Permissions ───────────────────────────────────────
class _Step3 extends StatelessWidget {
  const _Step3({
    required this.permAccessibility,
    required this.permOverlay,
    required this.onGrantAccessibility,
    required this.onGrantOverlay,
  });

  final bool permAccessibility;
  final bool permOverlay;
  final VoidCallback onGrantAccessibility;
  final VoidCallback onGrantOverlay;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeUpWidget(
            child: _ObBubble(
                'Now grant two permissions so the bubble can appear and insert text.'),
          ),
          const SizedBox(height: 14),
          FadeUpWidget(
            delay: const Duration(milliseconds: 300),
            child: _PermRow(
              icon: Icons.accessibility_new,
              title: 'Accessibility',
              desc:
                  'Lets the bubble place your prompt into the field. Nothing is read or stored.',
              granted: permAccessibility,
              onGrant: onGrantAccessibility,
            ),
          ),
          const SizedBox(height: 13),
          FadeUpWidget(
            delay: const Duration(milliseconds: 500),
            child: _PermRow(
              icon: Icons.layers_outlined,
              title: 'Display over other apps',
              desc:
                  'Lets the bubble float above whatever app you are using.',
              granted: permOverlay,
              onGrant: onGrantOverlay,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.icon,
    required this.title,
    required this.desc,
    required this.granted,
    required this.onGrant,
  });

  final IconData icon;
  final String title;
  final String desc;
  final bool granted;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: kSpring,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: granted
              ? const Color(0x4D5BC58F) // success 30%
              : AppColors.borderHairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: granted
                  ? AppColors.confirmTint
                  : const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 19,
                color:
                    granted ? AppColors.confirm : AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.45)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          granted
              ? Row(
                  children: const [
                    Icon(Icons.check, size: 16, color: AppColors.confirm),
                    SizedBox(width: 4),
                    Text('Granted',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.confirm,
                            fontWeight: FontWeight.w500)),
                  ],
                )
              : GestureDetector(
                  onTap: onGrant,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentTint,
                      borderRadius: BorderRadius.circular(9),
                      border:
                          Border.all(color: AppColors.accentDim),
                    ),
                    child: const Text('Grant',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.accentText,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Step 4: Animated demo ─────────────────────────────────────
class _Step4 extends StatefulWidget {
  const _Step4();

  @override
  State<_Step4> createState() => _Step4State();
}

class _Step4State extends State<_Step4> {
  int _phase = 0;
  Timer? _timer;

  static const _captions = [
    'Tap a text field — the keyboard opens',
    'The Loadstash bubble appears at the edge',
    'Tap it to open your prompts',
    'Pinned and most-used sit right on top',
    'Fill in any variables, then tap OK',
    'Your prompt drops into the field',
  ];

  @override
  void initState() {
    super.initState();
    _timer =
        Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) setState(() => _phase = (_phase + 1) % 6);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeUpWidget(
            child: _ObBubble("Here's how it works — watch:"),
          ),
          const SizedBox(height: 16),
          Expanded(child: _DemoCard(phase: _phase, captions: _captions)),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.phase, required this.captions});
  final int phase;
  final List<String> captions;

  @override
  Widget build(BuildContext context) {
    final kbVisible = phase == 0 || phase >= 5;
    final showBubble = phase == 1;
    final sheetUp = phase >= 2 && phase <= 4;
    final showFill = phase == 4;
    final inserted = phase >= 5;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101216),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        children: [
          // Fake app header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF13161B),
              border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 11, backgroundColor: Color(0xFF2E343F)),
                const SizedBox(width: 8),
                const Text('Any app',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    kbVisible ? 'keyboard up' : 'prompts',
                    style: const TextStyle(
                        fontSize: 9.5, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: Stack(
              children: [
                // Compose field
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22252B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: inserted
                            ? AppColors.accentDim
                            : AppColors.borderHairline,
                      ),
                    ),
                    child: inserted
                        ? const Text(
                            "Explain vector databases like I'm 5, using one simple everyday analogy.",
                            style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10.5,
                                color: AppColors.textPrimary,
                                height: 1.45),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Row(
                            children: const [
                              Text('Ask anything',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textTertiary)),
                              BlinkingCursor(height: 15),
                            ],
                          ),
                  ),
                ),

                // Keyboard
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 420),
                  curve: kSpring,
                  bottom: kbVisible ? 0 : -120,
                  left: 0,
                  right: 0,
                  child: _MiniKeyboard(),
                ),

                // Bubble
                if (showBubble)
                  Positioned(
                    right: 14,
                    bottom: 118,
                    child: RingWidget(
                      color: AppColors.accent,
                      size: 42,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),

                // Picker / fill sheet
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 450),
                  curve: kSpring,
                  bottom: sheetUp ? 0 : -200,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(18)),
                      border: Border(
                          top: BorderSide(color: AppColors.borderHairline)),
                    ),
                    padding: const EdgeInsets.all(13),
                    child: showFill ? _FillPanel() : _PickerPanel(),
                  ),
                ),
              ],
            ),
          ),

          // Caption
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF13161B),
              border: Border(top: BorderSide(color: AppColors.borderHairline)),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text('${phase + 1}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.accentText,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    captions[phase],
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKeyboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF191B20),
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
      child: Column(
        children: [
          for (final n in [10, 9, 7])
            Padding(
              padding: EdgeInsets.only(
                  bottom: 5,
                  left: n == 9 ? 9 : (n == 7 ? 24 : 0),
                  right: n == 9 ? 9 : (n == 7 ? 24 : 0)),
              child: Row(
                children: List.generate(
                  n,
                  (_) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 21,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2D34),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                  flex: 16,
                  child: Container(
                    height: 21,
                    decoration: BoxDecoration(
                        color: const Color(0xFF23262C),
                        borderRadius: BorderRadius.circular(4)),
                  )),
              const SizedBox(width: 4),
              Expanded(
                  flex: 50,
                  child: Container(
                    height: 21,
                    decoration: BoxDecoration(
                        color: const Color(0xFF2A2D34),
                        borderRadius: BorderRadius.circular(4)),
                  )),
              const SizedBox(width: 4),
              Expanded(
                  flex: 16,
                  child: Container(
                    height: 21,
                    decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(4)),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 34,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgBase,
                  borderRadius: BorderRadius.circular(9),
                  border:
                      Border.all(color: AppColors.borderHairline),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search,
                        size: 13, color: AppColors.textTertiary),
                    SizedBox(width: 7),
                    Text('Search your library',
                        style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 7),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 11),
        const Text('PINNED',
            style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.05,
                color: AppColors.textTertiary)),
        const SizedBox(height: 7),
        _MiniRow(title: "Explain like I'm 5", highlighted: true),
        const SizedBox(height: 6),
        _MiniRow(title: 'Summarize a thread', highlighted: false),
      ],
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.title, required this.highlighted});
  final String title;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.accentTint : AppColors.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? AppColors.accentDim
              : AppColors.borderHairline,
        ),
      ),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.modelClaude)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: highlighted
                        ? FontWeight.w600
                        : FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
          if (highlighted)
            const Icon(Icons.chevron_right,
                size: 14, color: AppColors.accentText),
        ],
      ),
    );
  }
}

class _FillPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.modelClaude)),
            const SizedBox(width: 7),
            const Text("Explain like I'm 5",
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        const Text('topic',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.accentText,
                fontFamily: 'JetBrainsMono')),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: AppColors.bgBase,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.accentDim),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('vector databases',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          fontFamily: 'JetBrainsMono')),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Step 5: All set ───────────────────────────────────────────
class _Step5 extends StatelessWidget {
  const _Step5();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PopWidget(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.confirmTint,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: const Color(0x4D5BC58F)),
                ),
                child: const Icon(Icons.check,
                    size: 38, color: AppColors.confirm),
              ),
            ),
            const SizedBox(height: 18),
            const Text("You're all set",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.02 * 22)),
            const SizedBox(height: 10),
            const Text(
              'The bubble shows up whenever your keyboard is open. Tap it, pick a prompt, and it drops into the field.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────
class _ObBubble extends StatelessWidget {
  const _ObBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
        ),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 14, height: 1.5)),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label,
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: kSpring,
        width: 46,
        height: 27,
        decoration: BoxDecoration(
          color: value ? AppColors.accent : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? AppColors.accentDim : AppColors.borderHairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: kSpring,
            alignment:
                value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 21,
              height: 21,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x40000000), blurRadius: 3)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Build to verify**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/onboarding_screen.dart
git commit -m "feat: onboarding redesign — 5-step chat flow, animated demo card, permission rows"
```

---

## Task 9: Settings Redesign + Tags Screen

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/settings/tags_screen.dart` (replace placeholder)

- [ ] **Step 1: Rewrite settings_screen.dart**

```dart
// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/settings_channel.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _bubbleRunning = false;
  bool _togglingBubble = false;
  bool _pendingEnable = false;
  String _theme = 'dark';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshBubbleState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBubbleState();
      if (_pendingEnable) _enableBubble();
    }
  }

  Future<void> _refreshBubbleState() async {
    final running = await SettingsChannel.isBubbleRunning();
    if (mounted) setState(() => _bubbleRunning = running);
  }

  Future<void> _onBubbleToggle(bool value) async {
    if (_togglingBubble) return;
    setState(() => _togglingBubble = true);
    try {
      if (value) {
        await _enableBubble();
      } else {
        await SettingsChannel.stopBubble();
        if (mounted) setState(() => _bubbleRunning = false);
      }
    } finally {
      if (mounted) setState(() => _togglingBubble = false);
    }
  }

  Future<void> _enableBubble() async {
    final hasOverlay = await SettingsChannel.hasOverlayPermission();
    if (!hasOverlay) {
      if (!mounted) return;
      final grant = await _showPermissionDialog(
        title: 'Draw Over Other Apps',
        body: 'Loadstash needs this permission to show the floating bubble.',
        action: 'Grant',
      );
      if (grant == true) {
        setState(() => _pendingEnable = true);
        await SettingsChannel.openOverlaySettings();
      }
      return;
    }
    final hasA11y = await SettingsChannel.isAccessibilityEnabled();
    if (!hasA11y) {
      if (!mounted) return;
      final open = await _showPermissionDialog(
        title: 'Accessibility Permission',
        body: 'Loadstash uses accessibility to detect the keyboard and paste your prompt. It only reads which windows are open.',
        action: 'Open Settings',
      );
      if (open == true) {
        setState(() => _pendingEnable = true);
        await SettingsChannel.openAccessibilitySettings();
      }
      return;
    }
    setState(() => _pendingEnable = false);
    await SettingsChannel.startBubble();
    if (mounted) setState(() => _bubbleRunning = true);
  }

  Future<bool?> _showPermissionDialog(
      {required String title,
      required String body,
      required String action}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text(title, style: AppTypography.label),
        content: Text(body, style: AppTypography.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(action,
                style:
                    const TextStyle(color: AppColors.accentText)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                // Title
                const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text('Settings',
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.02 * 25)),
                ),

                // Launcher card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _bubbleRunning
                          ? AppColors.accentDim
                          : AppColors.borderHairline,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _bubbleRunning
                                  ? AppColors.accentTint
                                  : const Color(0x0DFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 22,
                              color: _bubbleRunning
                                  ? AppColors.accentText
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Loadstash launcher',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  _bubbleRunning
                                      ? 'On · bubble active when typing'
                                      : 'Off',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _bubbleRunning
                                          ? AppColors.confirm
                                          : AppColors.textTertiary,
                                      height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          _ToggleSwitch(
                            value: _bubbleRunning,
                            onChanged: _togglingBubble ? null : _onBubbleToggle,
                          ),
                        ],
                      ),
                      const Divider(height: 28, color: AppColors.borderHairline),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _bubbleRunning
                                  ? 'Accessibility and Display-over-apps granted'
                                  : 'Needs Accessibility + Display over apps',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 15, color: AppColors.confirm),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'Local-first. Everything stays on this device — Loadstash reads nothing and sends nothing.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary, height: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Appearance
                _SectionLabel('Appearance'),
                _SettingsCard(children: [
                  _SettingsRow(
                    icon: Icons.brightness_6_outlined,
                    title: 'Theme',
                    desc: 'Choose how Loadstash looks',
                    right: _ThemeToggle(
                      value: _theme,
                      onChanged: (t) => setState(() => _theme = t),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Your library
                _SectionLabel('Your library'),
                _SettingsCard(children: [
                  _SettingsRow(
                    icon: Icons.download_outlined,
                    title: 'Import from YAML',
                    desc: 'Add prompts from a .yaml file',
                    right: _Badge(label: 'Import', accent: true),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Import coming soon'))),
                  ),
                  _SettingsRow(
                    icon: Icons.upload_outlined,
                    title: 'Export to YAML',
                    desc: 'Download all prompts as .yaml',
                    right: _Badge(label: 'Export'),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export coming soon'))),
                  ),
                  _SettingsRow(
                    icon: Icons.tag,
                    title: 'Manage tags',
                    desc: 'Search tags and model tags',
                    right: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textTertiary),
                    onTap: () => context.push('/tags'),
                  ),
                ]),
                const SizedBox(height: 20),

                // Community
                _SectionLabel('Community'),
                _SettingsCard(children: [
                  _SettingsRow(
                    icon: Icons.inventory_2_outlined,
                    title: 'Browse community packs',
                    desc: 'Curated prompt collections',
                    right: _Badge(label: 'Coming soon', dim: true),
                    dim: true,
                  ),
                  _SettingsRow(
                    icon: Icons.upload_outlined,
                    title: 'Submit a pack',
                    desc: 'Share your prompts with others',
                    right: _Badge(label: 'Coming soon', dim: true),
                    dim: true,
                  ),
                ]),
                const SizedBox(height: 24),

                const Center(
                  child: Text('Loadstash v1.0 · made for Android',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textTertiary)),
                ),
              ],
            ),
          ),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 6),
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        border: Border(top: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.book_outlined,
            label: 'Library',
            active: false,
            onTap: () => context.go('/'),
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => context.push('/editor'),
                child: Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withOpacity(0.6),
                          blurRadius: 22,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 26),
                ),
              ),
              const Text('New prompt',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          _NavItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              active: true,
              onTap: () {}),
        ],
      ),
    );
  }
}

// ── Settings widgets ──────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: AppColors.textTertiary)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: AppColors.borderHairline),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.desc,
    this.right,
    this.onTap,
    this.dim = false,
  });

  final IconData icon;
  final String title;
  final String? desc;
  final Widget? right;
  final VoidCallback? onTap;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon,
                    size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    if (desc != null)
                      Text(desc!,
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                              height: 1.4)),
                  ],
                ),
              ),
              if (right != null) ...[
                const SizedBox(width: 8),
                right!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.accent = false, this.dim = false});
  final String label;
  final bool accent;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: accent ? AppColors.accentTint : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent ? AppColors.accentDim : AppColors.borderHairline,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accent ? AppColors.accentText : AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in [('light', Icons.light_mode_outlined), ('dark', Icons.dark_mode_outlined)])
            GestureDetector(
              onTap: () => onChanged(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: value == t.$1 ? AppColors.accentTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$2,
                        size: 14,
                        color: value == t.$1
                            ? AppColors.accentText
                            : AppColors.textTertiary),
                    const SizedBox(width: 5),
                    Text(t.$1[0].toUpperCase() + t.$1.substring(1),
                        style: TextStyle(
                            fontSize: 11.5,
                            color: value == t.$1
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 27,
        decoration: BoxDecoration(
          color: value ? AppColors.accent : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: value
                  ? AppColors.accentDim
                  : AppColors.borderHairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            alignment:
                value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 21,
              height: 21,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 3)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 22,
              color: active ? AppColors.accentText : AppColors.textTertiary),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? AppColors.accentText : AppColors.textTertiary)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Implement tags_screen.dart**

```dart
// lib/features/settings/tags_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final List<String> _searchTags = [
    'work', 'sales', 'learning', 'dev', 'data', 'creative', 'social', 'writing',
  ];
  final _newTagCtrl = TextEditingController();

  static const _modelTags = [
    ('claude', 'Claude', AppColors.modelClaude, 'prefilled'),
    ('chatgpt', 'ChatGPT', AppColors.modelChatGpt, 'prefilled'),
    ('gemini', 'Gemini', AppColors.modelGemini, 'prefilled'),
    ('local', 'Local', AppColors.modelLocal, 'custom'),
  ];

  @override
  void dispose() {
    _newTagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, size: 20),
          label: const Text('Settings'),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        ),
        leadingWidth: 110,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          const Text('Tags',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -0.02 * 23)),
          const SizedBox(height: 4),
          const Text(
            'Two ways to organise — search tags you create, and model tags for where a prompt runs.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 22),

          // Search tags
          Row(
            children: [
              const Icon(Icons.tag, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text('Search tags',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Freeform, made by you — for organising and finding prompts.',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5)),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._searchTags.map((t) => _SearchTagChip(
                tag: t,
                onRemove: () => setState(() => _searchTags.remove(t)),
              )),
              _AddTagChip(onAdd: (name) {
                if (name.isNotEmpty && !_searchTags.contains(name)) {
                  setState(() => _searchTags.add(name));
                }
              }),
            ],
          ),
          const Divider(height: 32, color: AppColors.borderHairline),

          // Model tags
          Row(
            children: [
              ...AppColors.modelClaude == AppColors.modelClaude
                  ? [
                      for (final t in _modelTags)
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration:
                                BoxDecoration(shape: BoxShape.circle, color: t.$3),
                          ),
                        )
                    ]
                  : [],
              const SizedBox(width: 8),
              const Text('Model tags',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Prefilled and colour-coded by model. You can add your own too.',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5)),
          const SizedBox(height: 13),
          Column(
            children: _modelTags.map((entry) {
              final (key, label, color, badge) = entry;
              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Row(
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: color)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          Text(color.value.toRadixString(16).toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  fontFamily: 'JetBrainsMono')),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.borderHairline),
                      ),
                      child: Text(badge,
                          style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textTertiary)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add model tag — coming soon'))),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 7),
                  Text('Add model tag',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchTagChip extends StatelessWidget {
  const _SearchTagChip({required this.tag, required this.onRemove});
  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('#',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            Text(tag,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 5),
            const Icon(Icons.close, size: 12, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _AddTagChip extends StatefulWidget {
  const _AddTagChip({required this.onAdd});
  final ValueChanged<String> onAdd;

  @override
  State<_AddTagChip> createState() => _AddTagChipState();
}

class _AddTagChipState extends State<_AddTagChip> {
  bool _editing = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return SizedBox(
        width: 120,
        height: 28,
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: AppColors.accentDim),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
          onSubmitted: (v) {
            widget.onAdd(v.trim());
            setState(() { _editing = false; _ctrl.clear(); });
          },
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 11, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.accentDim),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 13, color: AppColors.accentText),
            SizedBox(width: 4),
            Text('New tag',
                style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.accentText,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add `/tags` route to app.dart**

Read `lib/app.dart`. Inside the ShellRoute routes list, add:
```dart
GoRoute(path: '/tags', builder: (_, __) => const TagsScreen()),
```

This should already be there if added as a placeholder in Task 5. If it references the old placeholder, it already points to the real file — no change needed.

- [ ] **Step 4: Build and test**

```bash
flutter test && flutter build apk --debug 2>&1 | tail -3
```

Expected: all tests pass, APK builds.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: settings redesign, tags screen with search + model tags management"
```

---

## Task 10: Overlay Picker Updates

**Files:**
- Modify: `lib/features/overlay/overlay_screen.dart`
- Modify: `lib/features/overlay/widgets/overlay_prompt_row.dart`

- [ ] **Step 1: Add model filter chips to overlay search area**

Read `lib/features/overlay/overlay_screen.dart`. Add state for model filter:

```dart
String? _modelFilter; // null = All
```

Add filter chips after the search bar in `build()`:

```dart
// Model filter chips — horizontal scroll
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
  child: Row(
    children: [
      _ModelChip(label: 'All', color: null, active: _modelFilter == null,
          onTap: () => setState(() => _modelFilter = null)),
      const SizedBox(width: 7),
      ...[
        ('claude', 'Claude', AppColors.modelClaude),
        ('chatgpt', 'ChatGPT', AppColors.modelChatGpt),
        ('gemini', 'Gemini', AppColors.modelGemini),
        ('local', 'Local', AppColors.modelLocal),
      ].map((e) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: _ModelChip(
          label: e.$2,
          color: e.$3,
          active: _modelFilter == e.$1,
          onTap: () => setState(() =>
              _modelFilter = _modelFilter == e.$1 ? null : e.$1),
        ),
      )),
    ],
  ),
),
```

Update `_filtered` getter to also apply model filter:

```dart
List<Prompt> get _filtered {
  var result = _prompts;
  if (_modelFilter != null) {
    result = result
        .where((p) => p.modelTags.contains(_modelFilter!))
        .toList();
  }
  if (_query.isEmpty) return result;
  final q = _query.toLowerCase();
  return result
      .where((p) =>
          p.title.toLowerCase().contains(q) ||
          p.body.toLowerCase().contains(q))
      .toList();
}
```

Add the `_ModelChip` widget at the bottom of the file:

```dart
class _ModelChip extends StatelessWidget {
  const _ModelChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color? color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accentTint : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.accentDim : AppColors.borderHairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: color)),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update overlay_prompt_row.dart**

Read the file. Update the model dots to use `AppColors.forModel(tag)` instead of the switch statement it had:

```dart
Widget _dot(String tag) {
  return Container(
    width: 7,
    height: 7,
    margin: const EdgeInsets.only(left: 4),
    decoration: BoxDecoration(
        color: AppColors.forModel(tag), shape: BoxShape.circle),
  );
}
```

- [ ] **Step 3: Build and run full test suite**

```bash
flutter test && flutter build apk --debug 2>&1 | tail -3
```

Expected: all tests pass, APK builds.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: overlay model filter chips, updated model dot colors"
```

---

## Task 11: Final Build Verification

**Files:** No new files. Verify everything from Parts 1-3 integrates.

- [ ] **Step 1: Run full test suite**

```bash
flutter test
```

Expected: all 34+ tests pass.

- [ ] **Step 2: Check for any flutter analyze errors**

```bash
flutter analyze 2>&1 | grep -E "^  error" | head -20
```

Expected: no errors (warnings are fine).

- [ ] **Step 3: Final build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: UI redesign v2 complete — library folders, prompt detail, editor, onboarding, settings, tags, overlay"
```

---

## Self-Review: Spec Coverage

| Spec requirement | Task |
|---|---|
| Pinned horizontal scrollable row on library root | Task 5 (PinnedRow) |
| Folder browser with chevron, count, icon | Task 5 (FolderRow) |
| Breadcrumb nav (back button + path label) | Task 5 (LibraryScreen) |
| New folder bottom sheet with cursor animation | Task 5 (NewFolderSheet + BlinkingCursor) |
| Prompt card: path crumb + tag chips + mono preview + model dots | Task 5 (PromptCard) |
| /prompt route → PromptDetailScreen | Task 5 (app.dart) + Task 6 |
| Prompt detail: Models, Tags, full body, Copy, Edit, Move | Task 6 |
| Editor: folder picker sheet, search tags, model chips | Task 7 |
| Onboarding 5-step chat flow with staggered FadeUpWidget | Task 8 |
| Onboarding animated demo card (6 phases, 1.5s cycle) | Task 8 |
| PopWidget on all-set check icon | Task 8 (_Step5) |
| ToggleSwitch with spring animation | Task 8, 9 (_ToggleSwitch) |
| Settings launcher card with animated border | Task 9 |
| Settings Import/Export YAML stubs | Task 9 |
| Settings Community "Coming soon" | Task 9 |
| Tags screen: search tags + model tags | Task 9 (TagsScreen) |
| Tags: New tag inline editor chip | Task 9 (_AddTagChip) |
| Overlay model filter chips | Task 10 |
| Updated model dot colors (brand-accurate) | Task 10 |
| confirmTint used in onboarding all-set + perm rows | Task 8 |
| accentDim used on active borders everywhere | Tasks 5–10 |
| accentText used on icons/text in accent contexts | Tasks 5–10 |
