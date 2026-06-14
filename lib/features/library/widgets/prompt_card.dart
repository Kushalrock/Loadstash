import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/repository_providers.dart';

class PromptCard extends ConsumerWidget {
  const PromptCard({
    super.key,
    required this.prompt,
    required this.onTap,
    this.onEdit,
  });

  final Prompt prompt;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (prompt.pinned) ...[
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.push_pin, size: 14, color: AppColors.accent),
                  ),
                ],
                Expanded(
                  child: Text(
                    prompt.title,
                    style: AppTypography.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    prompt.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 18,
                    color: prompt.pinned ? AppColors.accent : AppColors.textTertiary,
                  ),
                  onPressed: () {
                    ref.read(promptRepositoryProvider).togglePin(prompt.id, !prompt.pinned);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textTertiary),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              prompt.body,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
