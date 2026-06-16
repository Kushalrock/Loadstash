import 'package:flutter/material.dart';
import '../../../core/theme/app_context_colors.dart';
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
          color: context.cSurface1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: context.cAccentTint, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.folder_outlined, size: 19, color: context.cAccentText),
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
            Icon(Icons.chevron_right, size: 18, color: context.cText3),
          ],
        ),
      ),
    );
  }
}
