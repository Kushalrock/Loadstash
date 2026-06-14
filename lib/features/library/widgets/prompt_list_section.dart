import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import 'prompt_card.dart';

class PromptListSection extends StatelessWidget {
  const PromptListSection({
    super.key,
    required this.title,
    required this.prompts,
    required this.onPromptTap,
    this.onPromptEdit,
  });

  final String title;
  final List<Prompt> prompts;
  final ValueChanged<Prompt> onPromptTap;
  final ValueChanged<Prompt>? onPromptEdit;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...prompts.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PromptCard(
                prompt: p,
                onTap: () => onPromptTap(p),
                onEdit: onPromptEdit != null ? () => onPromptEdit!(p) : null,
              ),
            )),
      ],
    );
  }
}
