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
          searchTags: List<String>.from(p['searchTags'] as List? ?? const []),
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
      body: SafeArea(child: Column(children: [
        _ObDots(step: _step),
        _ObHeader(step: _step, onSkip: _step < 5 ? () => context.go('/') : null),
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(key: ValueKey(_step), child: switch (_step) {
            1 => const _Step1(),
            2 => _Step2(launcherOn: _launcherOn, onToggle: (v) => setState(() => _launcherOn = v)),
            3 => _Step3(
              permAccessibility: _permAccessibility,
              permOverlay: _permOverlay,
              onGrantAccessibility: () => setState(() => _permAccessibility = true),
              onGrantOverlay: () => setState(() => _permOverlay = true)),
            4 => const _Step4(),
            _ => const _Step5(),
          }),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: _buildFooter()),
      ])),
    );
  }

  Widget _buildFooter() {
    if (_step == 2 && !_launcherOn) {
      return Opacity(opacity: 0.5, child: _PrimaryBtn(label: 'Turn it on to continue', icon: Icons.chevron_right, onTap: null));
    }
    if (_step == 3 && (!_permAccessibility || !_permOverlay)) {
      return Opacity(opacity: 0.5, child: _PrimaryBtn(label: 'Grant both to continue', icon: Icons.chevron_right, onTap: null));
    }
    if (_step == 5) {
      return _seeding
        ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
        : _PrimaryBtn(label: 'Open Loadstash', icon: Icons.auto_awesome, onTap: _finish);
    }
    return _PrimaryBtn(
      label: _step == 1 ? 'Get started' : 'Continue',
      icon: Icons.chevron_right,
      onTap: () => setState(() => _step++));
  }
}

// ── Dot progress ─────────────────────────────────────────────
class _ObDots extends StatelessWidget {
  const _ObDots({required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedDot(active: i + 1 == step, past: i + 1 < step)))));
}

// ── Header ────────────────────────────────────────────────────
class _ObHeader extends StatelessWidget {
  const _ObHeader({required this.step, this.onSkip});
  final int step;
  final VoidCallback? onSkip;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
    child: Row(children: [
      Container(width: 30, height: 30,
        decoration: BoxDecoration(color: AppColors.accentTint, borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.accentDim)),
        child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.accentText)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Loadstash', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Text('Setup · about 20 seconds', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ]),
      const Spacer(),
      if (onSkip != null)
        TextButton(onPressed: onSkip, child: const Text('Skip', style: TextStyle(fontSize: 13, color: AppColors.textTertiary))),
    ]));
}

// ── Step 1: Welcome ───────────────────────────────────────────
class _Step1 extends StatelessWidget {
  const _Step1();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
      FadeUpWidget(delay: Duration.zero, child: _ObBubble("Hi — I'm Loadstash.")),
      const SizedBox(height: 11),
      FadeUpWidget(delay: const Duration(milliseconds: 500),
        child: _ObBubble('I keep your best prompts one tap away, inside any app on your phone.')),
      const SizedBox(height: 11),
      FadeUpWidget(delay: const Duration(milliseconds: 1100),
        child: _ObBubble("Two quick settings and you're set. Ready?")),
    ]));
}

// ── Step 2: Launcher toggle ───────────────────────────────────
class _Step2 extends StatelessWidget {
  const _Step2({required this.launcherOn, required this.onToggle});
  final bool launcherOn;
  final ValueChanged<bool> onToggle;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FadeUpWidget(child: _ObBubble('First, turn on the launcher.')),
      const SizedBox(height: 14),
      FadeUpWidget(delay: const Duration(milliseconds: 300),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), curve: kSpring,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface1, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: launcherOn ? AppColors.accentDim : AppColors.borderHairline)),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.accentTint, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.auto_awesome, size: 21, color: AppColors.accentText)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Loadstash launcher', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              Text(launcherOn ? 'On — the bubble is active' : 'Off',
                style: TextStyle(fontSize: 12, color: launcherOn ? AppColors.confirm : AppColors.textSecondary, height: 1.3)),
            ])),
            _ToggleSwitch(value: launcherOn, onChanged: onToggle),
          ]))),
      const SizedBox(height: 14),
      FadeUpWidget(delay: const Duration(milliseconds: 500),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.shield_outlined, size: 16, color: AppColors.confirm),
          const SizedBox(width: 9),
          const Expanded(child: Text(
            'Works entirely on your device. Loadstash reads nothing you type and sends nothing anywhere.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5))),
        ])),
    ]));
}

// ── Step 3: Permissions ───────────────────────────────────────
class _Step3 extends StatelessWidget {
  const _Step3({required this.permAccessibility, required this.permOverlay,
    required this.onGrantAccessibility, required this.onGrantOverlay});
  final bool permAccessibility, permOverlay;
  final VoidCallback onGrantAccessibility, onGrantOverlay;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FadeUpWidget(child: _ObBubble('Now grant two permissions so the bubble can appear and insert text.')),
      const SizedBox(height: 14),
      FadeUpWidget(delay: const Duration(milliseconds: 300),
        child: _PermRow(icon: Icons.accessibility_new, title: 'Accessibility',
          desc: 'Lets the bubble place your prompt into the field. Nothing is read or stored.',
          granted: permAccessibility, onGrant: onGrantAccessibility)),
      const SizedBox(height: 13),
      FadeUpWidget(delay: const Duration(milliseconds: 500),
        child: _PermRow(icon: Icons.layers_outlined, title: 'Display over other apps',
          desc: 'Lets the bubble float above whatever app you are using.',
          granted: permOverlay, onGrant: onGrantOverlay)),
    ]));
}

class _PermRow extends StatelessWidget {
  const _PermRow({required this.icon, required this.title, required this.desc,
    required this.granted, required this.onGrant});
  final IconData icon;
  final String title, desc;
  final bool granted;
  final VoidCallback onGrant;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300), curve: kSpring,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface1, borderRadius: BorderRadius.circular(15),
      border: Border.all(color: granted ? const Color(0x4D5BC58F) : AppColors.borderHairline)),
    child: Row(children: [
      Container(width: 38, height: 38,
        decoration: BoxDecoration(
          color: granted ? AppColors.confirmTint : const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 19, color: granted ? AppColors.confirm : AppColors.textSecondary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.45)),
      ])),
      const SizedBox(width: 10),
      granted
        ? const Row(children: [
            Icon(Icons.check, size: 16, color: AppColors.confirm),
            SizedBox(width: 4),
            Text('Granted', style: TextStyle(fontSize: 12.5, color: AppColors.confirm, fontWeight: FontWeight.w500)),
          ])
        : GestureDetector(
            onTap: onGrant,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentTint, borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.accentDim)),
              child: const Text('Grant', style: TextStyle(fontSize: 12.5, color: AppColors.accentText, fontWeight: FontWeight.w600)))),
    ]));
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
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) setState(() => _phase = (_phase + 1) % 6);
    });
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FadeUpWidget(child: _ObBubble("Here's how it works — watch:")),
      const SizedBox(height: 16),
      Expanded(child: _DemoCard(phase: _phase, captions: _captions)),
    ]));
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
        border: Border.all(color: AppColors.borderHairline)),
      child: Column(children: [
        // Fake app header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF13161B),
            border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
          child: Row(children: [
            const CircleAvatar(radius: 11, backgroundColor: Color(0xFF2E343F)),
            const SizedBox(width: 8),
            const Text('Any app', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(999)),
              child: Text(kbVisible ? 'keyboard up' : 'prompts',
                style: const TextStyle(fontSize: 9.5, color: AppColors.textTertiary))),
          ])),
        Expanded(child: Stack(children: [
          // Compose field
          Positioned(top: 12, left: 12, right: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF22252B), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: inserted ? AppColors.accentDim : AppColors.borderHairline)),
              child: inserted
                ? const Text("Explain vector databases like I'm 5, using one simple everyday analogy.",
                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10.5, color: AppColors.textPrimary, height: 1.45),
                    maxLines: 2, overflow: TextOverflow.ellipsis)
                : const Row(children: [
                    Text('Ask anything', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                    BlinkingCursor(height: 15),
                  ]))),
          // Keyboard
          AnimatedPositioned(
            duration: const Duration(milliseconds: 420), curve: kSpring,
            bottom: kbVisible ? 0 : -120, left: 0, right: 0,
            child: _MiniKeyboard()),
          // Bubble
          if (showBubble) Positioned(right: 14, bottom: 118,
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white))),
          // Picker/fill sheet
          AnimatedPositioned(
            duration: const Duration(milliseconds: 450), curve: kSpring,
            bottom: sheetUp ? 0 : -200, left: 0, right: 0,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(top: BorderSide(color: AppColors.borderHairline))),
              padding: const EdgeInsets.all(13),
              child: showFill ? _FillPanel() : _PickerPanel())),
        ])),
        // Caption
        Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
          decoration: const BoxDecoration(
            color: Color(0xFF13161B),
            border: Border(top: BorderSide(color: AppColors.borderHairline)),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18))),
          child: Row(children: [
            Container(width: 18, height: 18,
              decoration: BoxDecoration(color: AppColors.accentTint, borderRadius: BorderRadius.circular(5)),
              child: Center(child: Text('${phase + 1}',
                style: const TextStyle(fontSize: 10, color: AppColors.accentText, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 8),
            Expanded(child: Text(captions[phase],
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
          ])),
      ]));
  }
}

class _MiniKeyboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF191B20),
    padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
    child: Column(children: [
      for (final data in [(10, 0.0), (9, 9.0), (7, 24.0)])
        Padding(padding: EdgeInsets.only(bottom: 5, left: data.$2, right: data.$2),
          child: Row(children: List.generate(data.$1, (_) =>
            Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 21, decoration: BoxDecoration(color: const Color(0xFF2A2D34), borderRadius: BorderRadius.circular(4))))))),
      Row(children: [
        Expanded(flex: 16, child: Container(height: 21, decoration: BoxDecoration(color: const Color(0xFF23262C), borderRadius: BorderRadius.circular(4)))),
        const SizedBox(width: 4),
        Expanded(flex: 50, child: Container(height: 21, decoration: BoxDecoration(color: const Color(0xFF2A2D34), borderRadius: BorderRadius.circular(4)))),
        const SizedBox(width: 4),
        Expanded(flex: 16, child: Container(height: 21, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4)))),
      ]),
    ]));
}

class _PickerPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Container(height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: AppColors.bgBase, borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.borderHairline)),
        child: const Row(children: [
          Icon(Icons.search, size: 13, color: AppColors.textTertiary),
          SizedBox(width: 7),
          Text('Search your library', style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary)),
        ]))),
      const SizedBox(width: 7),
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(9)),
        child: const Icon(Icons.add, size: 16, color: Colors.white)),
    ]),
    const SizedBox(height: 11),
    const Text('PINNED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.05, color: AppColors.textTertiary)),
    const SizedBox(height: 7),
    _MiniRow(title: "Explain like I'm 5", highlighted: true),
    const SizedBox(height: 6),
    _MiniRow(title: 'Summarize a thread', highlighted: false),
  ]);
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.title, required this.highlighted});
  final String title;
  final bool highlighted;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: highlighted ? AppColors.accentTint : AppColors.surface1,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: highlighted ? AppColors.accentDim : AppColors.borderHairline)),
    child: Row(children: [
      Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.modelClaude)),
      const SizedBox(width: 8),
      Expanded(child: Text(title, style: TextStyle(fontSize: 12, color: AppColors.textPrimary,
          fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500), overflow: TextOverflow.ellipsis)),
      if (highlighted) const Icon(Icons.chevron_right, size: 14, color: AppColors.accentText),
    ]));
}

class _FillPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.modelClaude)),
      const SizedBox(width: 7),
      const Text("Explain like I'm 5", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
    const SizedBox(height: 12),
    const Text('topic', style: TextStyle(fontSize: 10, color: AppColors.accentText, fontFamily: 'JetBrainsMono')),
    const SizedBox(height: 6),
    Row(children: [
      Expanded(child: Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(color: AppColors.bgBase, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.accentDim)),
        child: const Align(alignment: Alignment.centerLeft, child: Text('vector databases',
            style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontFamily: 'JetBrainsMono'))))),
      const SizedBox(width: 7),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(9)),
        child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600))),
    ]),
  ]);
}

// ── Step 5: All set ───────────────────────────────────────────
class _Step5 extends StatelessWidget {
  const _Step5();
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(30),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      PopWidget(child: Container(width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppColors.confirmTint, borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x4D5BC58F))),
        child: const Icon(Icons.check, size: 38, color: AppColors.confirm))),
      const SizedBox(height: 18),
      const Text("You're all set", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.44)),
      const SizedBox(height: 10),
      const Text(
        'The bubble shows up whenever your keyboard is open. Tap it, pick a prompt, and it drops into the field.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.55)),
    ])));
}

// ── Shared ────────────────────────────────────────────────────
class _ObBubble extends StatelessWidget {
  const _ObBubble(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface1,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18), topRight: Radius.circular(18),
        bottomRight: Radius.circular(18), bottomLeft: Radius.circular(6)),
      border: Border.all(color: AppColors.borderHairline)),
    child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)));
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity,
    child: FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))));
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220), curve: kSpring,
      width: 46, height: 27,
      decoration: BoxDecoration(
        color: value ? AppColors.accent : const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: value ? AppColors.accentDim : AppColors.borderHairline)),
      child: Padding(padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220), curve: kSpring,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 21, height: 21,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 3)]))))));
}
