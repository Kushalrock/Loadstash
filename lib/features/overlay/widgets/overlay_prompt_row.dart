import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';

class OverlayPromptRow extends StatelessWidget {
  const OverlayPromptRow({super.key, required this.prompt, required this.onTap});
  final Prompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          children: [
            if (prompt.pinned) ...[
              const Icon(Icons.push_pin, size: 14, color: AppColors.accent),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt.title,
                    style: AppTypography.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (prompt.body.isNotEmpty)
                    Text(
                      prompt.body,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            _ModelDots(modelTags: prompt.modelTags),
          ],
        ),
      ),
    );
  }
}

class _ModelDots extends StatelessWidget {
  const _ModelDots({required this.modelTags});
  final String modelTags;

  @override
  Widget build(BuildContext context) {
    if (modelTags.isEmpty) return const SizedBox.shrink();
    final tags = modelTags.split(',').where((t) => t.isNotEmpty);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tags.map((tag) => _dot(tag.trim())).toList(),
    );
  }

  Widget _dot(String tag) {
    final color = switch (tag) {
      'claude' => AppColors.modelClaude,
      'chatgpt' => AppColors.modelChatGpt,
      'gemini' => AppColors.modelGemini,
      _ => AppColors.modelLocal,
    };
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
