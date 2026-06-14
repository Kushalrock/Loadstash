import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (state == AppLifecycleState.resumed) _refreshBubbleState();
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
        body: 'Loadstash needs the "Draw over other apps" permission to show the floating bubble.',
        action: 'Grant',
      );
      if (grant == true) await SettingsChannel.openOverlaySettings();
      return;
    }

    final hasA11y = await SettingsChannel.isAccessibilityEnabled();
    if (!hasA11y) {
      if (!mounted) return;
      final open = await _showPermissionDialog(
        title: 'Accessibility Permission',
        body: 'Loadstash uses accessibility to detect when the keyboard opens and to paste your prompt. It only reads which windows are open — nothing else.',
        action: 'Open Settings',
      );
      if (open == true) await SettingsChannel.openAccessibilitySettings();
      return;
    }

    await SettingsChannel.startBubble();
    if (mounted) setState(() => _bubbleRunning = true);
  }

  Future<bool?> _showPermissionDialog({
    required String title,
    required String body,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text(title, style: AppTypography.label),
        content: Text(body, style: AppTypography.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action,
                style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.screenTitle),
        backgroundColor: AppColors.bgBase,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Floating Bubble'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: SwitchListTile(
              title: Text('Enable bubble', style: AppTypography.label),
              subtitle: Text(
                _bubbleRunning
                    ? 'Bubble is active — opens on keyboard'
                    : 'Appears when keyboard opens in any app',
                style: AppTypography.bodySmall,
              ),
              value: _bubbleRunning,
              onChanged: _togglingBubble ? null : _onBubbleToggle,
              activeColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Privacy'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Text(
              'All your prompts and usage data are stored locally on your device. '
              'Nothing is sent to any server. Your browsing habits and prompt '
              'choices never leave your phone.',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('About'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loadstash', style: AppTypography.label),
                const SizedBox(height: 4),
                Text('v1.0.0 · Local-first prompt library',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
