import 'package:flutter/material.dart';
import '../../../core/animations/animations.dart';
import '../../../core/theme/app_context_colors.dart';
import '../../../core/theme/app_typography.dart';

class NewFolderSheet extends StatefulWidget {
  const NewFolderSheet({super.key, required this.currentPath, required this.onCreate});
  final List<String> currentPath;
  final ValueChanged<String> onCreate;

  @override
  State<NewFolderSheet> createState() => _NewFolderSheetState();
}

class _NewFolderSheetState extends State<NewFolderSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final location = widget.currentPath.isEmpty ? 'Library' : widget.currentPath.join(' › ');
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 4,
          bottom: MediaQuery.of(context).viewInsets.bottom + 26),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('New folder', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        Text('Creating in $location', style: AppTypography.bodySmall.copyWith(fontSize: 12, color: context.cText2)),
        const SizedBox(height: 7),
        Container(
          height: 46, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.cBgBase, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cAccentDim),
          ),
          child: Row(children: [
            Icon(Icons.folder_outlined, size: 18, color: context.cAccentText),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: _ctrl, autofocus: true,
              style: AppTypography.label,
              decoration: InputDecoration(border: InputBorder.none,
                  hintText: 'Folder name', hintStyle: TextStyle(color: context.cText3)),
              onSubmitted: (v) { if (v.trim().isNotEmpty) widget.onCreate(v.trim()); },
            )),
            BlinkingCursor(color: context.cAccent),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () { final name = _ctrl.text.trim(); if (name.isNotEmpty) widget.onCreate(name); },
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Create folder'),
            style: FilledButton.styleFrom(backgroundColor: context.cAccent,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }
}
