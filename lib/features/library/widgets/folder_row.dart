import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/prompt_repository.dart';

class FolderRow extends StatelessWidget {
  const FolderRow({super.key, required this.folder, required this.onTap});
  final FolderEntry folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.accentTint, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.folder_outlined, size: 19, color: AppColors.accentText),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(folder.name, style: AppTypography.label.copyWith(fontSize: 14.5)),
                  Text('${folder.count} prompt${folder.count == 1 ? '' : 's'}',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
