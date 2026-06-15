import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/prompt_repository.dart';
import '../../providers/prompt_provider.dart';
import '../../providers/repository_providers.dart';
import '../library/widgets/folder_picker_sheet.dart';

class PromptDetailScreen extends ConsumerStatefulWidget {
  const PromptDetailScreen({super.key, required this.promptId});
  final int promptId;

  @override
  ConsumerState<PromptDetailScreen> createState() => _PromptDetailScreenState();
}

class _PromptDetailScreenState extends ConsumerState<PromptDetailScreen> {
  bool _showMovePicker = false;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(promptsStreamProvider);
    return allAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent))),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (all) {
        final prompt = all.where((p) => p.id == widget.promptId).firstOrNull;
        if (prompt == null) return const Scaffold(body: Center(child: Text('Not found')));
        return _buildScreen(context, prompt, all);
      },
    );
  }

  Widget _buildScreen(BuildContext context, Prompt prompt, List<Prompt> all) {
    final pinned = prompt.pinned;
    final path = PromptRepository.decodePath(prompt.path);
    final models = prompt.modelTags.split(',').where((s) => s.isNotEmpty).toList();
    final tags = PromptRepository.decodePath(prompt.searchTags);
    final varCount = RegExp(r'\{\{(\w+)\}\}').allMatches(prompt.body).map((m) => m.group(1)!).toSet().length;

    return Scaffold(
      body: Stack(children: [
        Column(children: [
          SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Row(children: [
                  Icon(Icons.chevron_left, size: 20, color: AppColors.textSecondary),
                  Text('Library', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ]),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(promptRepositoryProvider).togglePin(prompt.id, !pinned),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: pinned ? AppColors.accentTint : AppColors.surface1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: pinned ? AppColors.accentDim : AppColors.borderHairline)),
                  child: Icon(Icons.push_pin, size: 18, color: pinned ? AppColors.accentText : AppColors.textSecondary)),
              ),
            ]),
          )),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 20), children: [
            Text(prompt.title, style: AppTypography.screenTitle.copyWith(fontSize: 23, letterSpacing: -0.46, height: 1.2)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _CrumbLine(path: ['Library', ...path], size: 12)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showMovePicker = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderHairline),
                    borderRadius: BorderRadius.circular(999)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.folder_outlined, size: 13, color: AppColors.textSecondary),
                    SizedBox(width: 5),
                    Text('Move', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            _Section('Models'),
            const SizedBox(height: 8),
            models.isNotEmpty
              ? Wrap(spacing: 7, children: models.map((m) => _ModelChip(m)).toList())
              : const Text('No model tags', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
            const SizedBox(height: 18),
            _Section('Search tags'),
            const SizedBox(height: 8),
            tags.isNotEmpty
              ? Wrap(spacing: 7, children: tags.map((t) => _TagPill(t)).toList())
              : const Text('No tags', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
            const SizedBox(height: 18),
            _Section('Prompt'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.borderHairline)),
              child: Text(prompt.body, style: const TextStyle(
                  fontFamily: 'JetBrainsMono', fontSize: 13, color: AppColors.textSecondary, height: 1.65))),
            if (varCount > 0) ...[
              const SizedBox(height: 11),
              Row(children: [
                const Icon(Icons.tune, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Text('$varCount variable${varCount == 1 ? '' : 's'} filled in when used',
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ]),
            ],
            const SizedBox(height: 80),
          ])),
        ]),

        // Bottom action bar
        Positioned(left: 0, right: 0, bottom: 0, child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          decoration: const BoxDecoration(
            color: AppColors.bgBase,
            border: Border(top: BorderSide(color: AppColors.borderHairline))),
          child: Row(children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/editor', extra: prompt.id),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderHairline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: prompt.body));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')));
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy to clipboard'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13)))),
          ]),
        )),

        // Move folder sheet
        if (_showMovePicker)
          GestureDetector(
            onTap: () => setState(() => _showMovePicker = false),
            child: Container(color: Colors.black54,
              child: Align(alignment: Alignment.bottomCenter,
                child: GestureDetector(onTap: () {},
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(top: BorderSide(color: AppColors.borderHairline))),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Padding(padding: EdgeInsets.only(top: 10), child: Center(child: SizedBox(width: 38, height: 4.5,
                        child: DecoratedBox(decoration: BoxDecoration(color: Color(0x2EFFFFFF),
                            borderRadius: BorderRadius.all(Radius.circular(999))))))),
                      FolderPickerSheet(
                        allPrompts: all, currentPath: path, title: 'Move to folder',
                        onPick: (newPath) async {
                          await ref.read(promptRepositoryProvider).moveTo(prompt.id, newPath);
                          if (mounted) setState(() => _showMovePicker = false);
                        }),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label.toUpperCase(),
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.06, color: AppColors.textTertiary));
}

class _CrumbLine extends StatelessWidget {
  const _CrumbLine({required this.path, this.size = 11.0});
  final List<String> path;
  final double size;
  @override
  Widget build(BuildContext context) => Wrap(children: [
    for (var i = 0; i < path.length; i++) ...[
      if (i > 0) Text(' › ', style: TextStyle(fontSize: size, color: AppColors.textTertiary)),
      Text(path[i], style: TextStyle(fontSize: size, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    ],
  ]);
}

class _ModelChip extends StatelessWidget {
  const _ModelChip(this.key_);
  final String key_;
  @override
  Widget build(BuildContext context) {
    final color = AppColors.forModel(key_);
    final label = switch (key_) {
      'claude' => 'Claude', 'chatgpt' => 'ChatGPT', 'gemini' => 'Gemini', _ => 'Local',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 9, 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      ]));
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill(this.tag);
  final String tag;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0x33FFFFFF)),
      borderRadius: BorderRadius.circular(999)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('#', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    ]));
}
