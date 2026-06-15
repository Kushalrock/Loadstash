import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/prompt_repository.dart';

class PromptCard extends StatelessWidget {
  const PromptCard({super.key, required this.prompt, required this.onTap});
  final Prompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final models = prompt.modelTags.split(',').where((s) => s.isNotEmpty).toList();
    final path = PromptRepository.decodePath(prompt.path);
    final searchTags = PromptRepository.decodePath(prompt.searchTags);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(prompt.title,
                    style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  ...models.map((m) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(width: 7, height: 7,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.forModel(m))),
                  )),
                  if (prompt.pinned) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.push_pin, size: 13, color: AppColors.accent),
                  ],
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.borderHairline2),
              ),
              child: Text(
                prompt.body.replaceAll(RegExp(r'\{\{(\w+)\}\}'), r'$1').replaceAll('\n', ' '),
                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11.5,
                    color: AppColors.textSecondary, height: 1.4),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _PathCrumb(path: path)),
                const SizedBox(width: 8),
                Wrap(spacing: 5, children: searchTags.take(2).map((t) => _TagChip(tag: t)).toList()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PathCrumb extends StatelessWidget {
  const _PathCrumb({required this.path});
  final List<String> path;

  @override
  Widget build(BuildContext context) {
    final segments = ['Library', ...path];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const Padding(padding: EdgeInsets.symmetric(horizontal: 5),
              child: Text('›', style: TextStyle(fontSize: 11, color: AppColors.textTertiary))),
          Text(segments[i], style: const TextStyle(fontSize: 11,
              color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x33FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('#', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w400)),
        Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
