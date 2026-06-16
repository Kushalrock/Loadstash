import 'package:flutter/material.dart';
import '../../../core/theme/app_context_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import '../../library/widgets/folder_picker_sheet.dart';

class FolderAssignmentSheet extends StatelessWidget {
  const FolderAssignmentSheet({super.key, required this.count, required this.allPrompts});
  final int count;
  final List<Prompt> allPrompts;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assign a folder', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              '$count prompt${count == 1 ? '' : 's'} in this pack '
              '${count == 1 ? 'has' : 'have'} no folder assigned. '
              'Where should ${count == 1 ? 'it' : 'they'} go?',
              style: TextStyle(fontSize: 12, color: context.cText3, height: 1.5),
            ),
            const SizedBox(height: 12),
          ]),
        ),
        FolderPickerSheet(
          allPrompts: allPrompts,
          currentPath: const [],
          title: '',
          onPick: (path) => Navigator.of(context).pop(path),
        ),
      ],
    );
  }
}
