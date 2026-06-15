import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/settings_channel.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
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
        action: 'Grant');
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
        action: 'Open Settings');
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

  Future<bool?> _showPermissionDialog({required String title, required String body, required String action}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text(title, style: AppTypography.label),
        content: Text(body, style: AppTypography.bodySmall),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(action, style: const TextStyle(color: AppColors.accentText))),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 24), children: [
          const Padding(padding: EdgeInsets.only(bottom: 18),
            child: Text('Settings', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, letterSpacing: -0.5))),

          // Launcher card
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _bubbleRunning ? AppColors.accentDim : AppColors.borderHairline)),
            child: Column(children: [
              Row(children: [
                Container(width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _bubbleRunning ? AppColors.accentTint : const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.auto_awesome, size: 22,
                      color: _bubbleRunning ? AppColors.accentText : AppColors.textSecondary)),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Loadstash launcher', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(_bubbleRunning ? 'On · bubble active when typing' : 'Off',
                    style: TextStyle(fontSize: 12,
                        color: _bubbleRunning ? AppColors.confirm : AppColors.textTertiary, height: 1.3)),
                ])),
                _ToggleSwitch(value: _bubbleRunning,
                    onChanged: _togglingBubble ? null : _onBubbleToggle),
              ]),
              const Divider(height: 28, color: AppColors.borderHairline),
              Row(children: [
                Expanded(child: Text(
                  _bubbleRunning
                    ? 'Accessibility and Display-over-apps granted'
                    : 'Needs Accessibility + Display over apps',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              ]),
            ])),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.shield_outlined, size: 15, color: AppColors.confirm),
            const SizedBox(width: 7),
            const Expanded(child: Text(
              'Local-first. Everything stays on this device — Loadstash reads nothing and sends nothing.',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5))),
          ]),
          const SizedBox(height: 20),

          // Appearance
          _SectionLabel('Appearance'),
          _SettingsCard(children: [
            _SettingsRow(icon: Icons.brightness_6_outlined, title: 'Theme', desc: 'Choose how Loadstash looks',
              right: _ThemeToggle(value: _theme, onChanged: (t) => setState(() => _theme = t))),
          ]),
          const SizedBox(height: 20),

          // Your library
          _SectionLabel('Your library'),
          _SettingsCard(children: [
            _SettingsRow(icon: Icons.download_outlined, title: 'Import from YAML', desc: 'Add prompts from a .yaml file',
              right: _Badge(label: 'Import', accent: true),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import coming soon')))),
            _SettingsRow(icon: Icons.upload_outlined, title: 'Export to YAML', desc: 'Download all prompts as .yaml',
              right: const _Badge(label: 'Export'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export coming soon')))),
            _SettingsRow(icon: Icons.tag, title: 'Manage tags', desc: 'Search tags and model tags',
              right: const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
              onTap: () => context.push('/tags')),
          ]),
          const SizedBox(height: 20),

          // Community
          _SectionLabel('Community'),
          _SettingsCard(children: [
            _SettingsRow(icon: Icons.inventory_2_outlined, title: 'Browse community packs',
              desc: 'Curated prompt collections',
              right: const _Badge(label: 'Coming soon', dim: true), dim: true),
            _SettingsRow(icon: Icons.upload_outlined, title: 'Submit a pack',
              desc: 'Share your prompts with others',
              right: const _Badge(label: 'Coming soon', dim: true), dim: true),
          ]),
          const SizedBox(height: 24),

          const Center(child: Text('Loadstash v1.0 · made for Android',
              style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary))),
        ])),
        _buildBottomNav(context),
      ]),
    );
  }

  Widget _buildBottomNav(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(26, 8, 26, 6),
    decoration: const BoxDecoration(
      color: AppColors.bgBase,
      border: Border(top: BorderSide(color: AppColors.borderHairline))),
    child: Row(children: [
      _NavItem(icon: Icons.book_outlined, label: 'Library', active: false, onTap: () => context.go('/')),
      const Spacer(),
      Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () => context.push('/editor'),
          child: Container(width: 52, height: 52, margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: AppColors.accent, borderRadius: BorderRadius.circular(17),
              boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.6), blurRadius: 22, offset: const Offset(0, 8))]),
            child: const Icon(Icons.add, color: Colors.white, size: 26))),
        const Text('New prompt', style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
      ]),
      const Spacer(),
      _NavItem(icon: Icons.settings_outlined, label: 'Settings', active: true, onTap: () {}),
    ]));
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(), style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.06, color: AppColors.textTertiary)));
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderHairline)),
    child: Column(children: [
      for (var i = 0; i < children.length; i++) ...[
        children[i],
        if (i < children.length - 1) const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.borderHairline),
      ]]));
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.title, this.desc, this.right, this.onTap, this.dim = false});
  final IconData icon;
  final String title;
  final String? desc;
  final Widget? right;
  final VoidCallback? onTap;
  final bool dim;
  @override
  Widget build(BuildContext context) => Opacity(opacity: dim ? 0.55 : 1.0,
    child: GestureDetector(onTap: onTap,
      child: Container(color: Colors.transparent, padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: AppColors.textSecondary)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            if (desc != null) Text(desc!, style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary, height: 1.4)),
          ])),
          if (right != null) ...[const SizedBox(width: 8), right!],
        ]))));
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.accent = false, this.dim = false});
  final String label;
  final bool accent, dim;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: accent ? AppColors.accentTint : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: accent ? AppColors.accentDim : AppColors.borderHairline)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
        color: accent ? AppColors.accentText : AppColors.textTertiary)));
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(color: AppColors.bgBase, borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.borderHairline)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      for (final t in [('light', Icons.light_mode_outlined), ('dark', Icons.dark_mode_outlined)])
        GestureDetector(onTap: () => onChanged(t.$1),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: value == t.$1 ? AppColors.accentTint : Colors.transparent,
              borderRadius: BorderRadius.circular(7)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t.$2, size: 14, color: value == t.$1 ? AppColors.accentText : AppColors.textTertiary),
              const SizedBox(width: 5),
              Text(t.$1[0].toUpperCase() + t.$1.substring(1),
                style: TextStyle(fontSize: 11.5,
                  color: value == t.$1 ? AppColors.textPrimary : AppColors.textTertiary,
                  fontWeight: FontWeight.w500)),
            ]))),
    ]));
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onChanged != null ? () => onChanged!(!value) : null,
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

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 22, color: active ? AppColors.accentText : AppColors.textTertiary),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10.5,
        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        color: active ? AppColors.accentText : AppColors.textTertiary)),
    ]));
}
