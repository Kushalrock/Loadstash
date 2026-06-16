import 'package:flutter/material.dart';
import '../../../core/theme/app_context_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/prompt_repository.dart';

class FolderPickerSheet extends StatelessWidget {
  const FolderPickerSheet({
    super.key,
    required this.allPrompts,
    required this.currentPath,
    required this.onPick,
    this.title = 'Choose folder',
  });

  final List<Prompt> allPrompts;
  final List<String> currentPath;
  final ValueChanged<List<String>> onPick;
  final String title;

  @override
  Widget build(BuildContext context) {
    final paths = PromptRepository.allFolderPaths(allPrompts);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTypography.screenTitle.copyWith(fontSize: 17)),
            const SizedBox(height: 2),
            Text('Pick where this prompt lives',
                style: TextStyle(fontSize: 12, color: context.cText3)),
          ]),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.46),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            itemCount: paths.length,
            itemBuilder: (_, i) {
              final pa = paths[i];
              final selected = PromptRepository.pathEquals(pa, currentPath);
              return GestureDetector(
                onTap: () => onPick(pa),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? context.cAccentTint : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? context.cAccentDim : Colors.transparent),
                  ),
                  child: Row(children: [
                    Icon(pa.isEmpty ? Icons.book_outlined : Icons.folder_outlined,
                        size: 18, color: selected ? context.cAccentText : context.cText2),
                    const SizedBox(width: 11),
                    Expanded(child: pa.isEmpty
                      ? Text('Library (root)', style: AppTypography.label.copyWith(fontSize: 13.5))
                      : Wrap(children: [
                          for (var j = 0; j < pa.length; j++) ...[
                            if (j > 0) Text(' › ', style: TextStyle(fontSize: 13,
                                color: selected ? context.cAccentText : context.cText3)),
                            Text(pa[j], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                                color: selected ? context.cAccentText : context.cText1)),
                          ],
                        ])),
                    if (selected) Icon(Icons.check, size: 17, color: context.cAccentText),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
