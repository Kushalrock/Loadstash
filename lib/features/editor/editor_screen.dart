import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_context_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/prompt_repository.dart';
import '../../providers/prompt_provider.dart';
import '../../providers/repository_providers.dart';
import '../../services/variable_detector.dart';
import '../library/widgets/folder_picker_sheet.dart';
import 'widgets/variable_preview.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.promptId});
  final int? promptId;
  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _newTagCtrl = TextEditingController();
  bool _pinned = false;
  List<String> _path = [];
  List<String> _searchTags = [];
  List<String> _models = [];
  List<String> _detectedVars = [];
  bool _loading = true;
  int? _existingId;
  bool _showFolderPicker = false;

  static const _modelOptions = [
    ('claude', 'Claude'),
    ('chatgpt', 'ChatGPT'),
    ('gemini', 'Gemini'),
    ('local', 'Local'),
  ];

  @override
  void initState() {
    super.initState();
    _bodyCtrl.addListener(_onBodyChanged);
    _load();
  }

  Future<void> _load() async {
    if (widget.promptId != null) {
      final p = await ref.read(promptRepositoryProvider).getById(widget.promptId!);
      if (p != null && mounted) {
        setState(() {
          _existingId = p.id;
          _titleCtrl.text = p.title;
          _bodyCtrl.text = p.body;
          _pinned = p.pinned;
          _path = PromptRepository.decodePath(p.path);
          _searchTags = PromptRepository.decodePath(p.searchTags);
          _models = p.modelTags.split(',').where((s) => s.isNotEmpty).toList();
          _detectedVars = VariableDetector.detect(p.body);
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onBodyChanged() {
    setState(() => _detectedVars = VariableDetector.detect(_bodyCtrl.text));
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    final repo = ref.read(promptRepositoryProvider);
    final modelTags = _models.join(',');
    if (_existingId != null) {
      await repo.update(id: _existingId!, title: title, body: body,
          path: _path, searchTags: _searchTags, modelTags: modelTags, pinned: _pinned);
    } else {
      await repo.create(title: title, body: body,
          path: _path, searchTags: _searchTags, modelTags: modelTags, pinned: _pinned);
    }
    if (mounted) {
      if (_detectedVars.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            'Detected ${_detectedVars.length} variable(s): ${_detectedVars.join(', ')}')));
      }
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (_existingId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cSurface2,
        title: const Text('Delete prompt?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('Cancel', style: TextStyle(color: context.cText2))),
          TextButton(onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(promptRepositoryProvider).delete(_existingId!);
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _bodyCtrl.removeListener(_onBodyChanged);
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _newTagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(body: Center(child: CircularProgressIndicator(color: context.cAccent)));
    final allAsync = ref.watch(promptsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cBgBase, elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text('Cancel', style: TextStyle(color: context.cText2, fontSize: 14))),
        leadingWidth: 80,
        title: Text(_existingId == null ? 'New prompt' : 'Edit prompt', style: AppTypography.label),
        actions: [
          if (_existingId != null)
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
          TextButton(
            onPressed: _save,
            child: Text('Save', style: TextStyle(color: context.cAccentText, fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.all(16), children: [
          _Field('Title', TextField(
            controller: _titleCtrl, style: AppTypography.label,
            decoration: const InputDecoration(hintText: 'Name your prompt', labelText: 'Title'))),
          _Field('Prompt', TextField(
            controller: _bodyCtrl,
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, color: context.cText1, height: 1.65),
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Write your prompt. Wrap variables in {{braces}}.',
              labelText: 'Body', alignLabelWithHint: true))),
          if (_bodyCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionLabel('Preview'),
            const SizedBox(height: 6),
            VariablePreview(body: _bodyCtrl.text, variableNames: _detectedVars),
            const SizedBox(height: 16),
          ] else const SizedBox(height: 16),

          // Folder picker
          _SectionLabel('Folder'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showFolderPicker = true),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cSurface1, borderRadius: BorderRadius.circular(13),
                border: Border.all(color: context.cBorder)),
              child: Row(children: [
                Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: context.cAccentTint, borderRadius: BorderRadius.circular(9)),
                  child: Icon(Icons.folder_outlined, size: 17, color: context.cAccentText)),
                const SizedBox(width: 11),
                Expanded(child: _path.isEmpty
                  ? Text('Library (root)', style: TextStyle(fontSize: 13.5, color: context.cText2))
                  : Text(['Library', ..._path].join(' › '),
                      style: TextStyle(fontSize: 12.5, color: context.cText2, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
                Icon(Icons.chevron_right, size: 18, color: context.cText3),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Models
          _SectionLabel('Models'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _modelOptions.map((entry) {
            final (key, label) = entry;
            final selected = _models.contains(key);
            final color = AppColors.forModel(key);
            return GestureDetector(
              onTap: () => setState(() { if (selected) _models.remove(key); else _models.add(key); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.13) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: selected ? color.withOpacity(0.47) : context.cBorder)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontSize: 12.5,
                      color: selected ? context.cText1 : context.cText2, fontWeight: FontWeight.w500)),
                  if (selected) ...[const SizedBox(width: 5), Icon(Icons.check, size: 13, color: context.cText1)],
                ])));
          }).toList()),
          const SizedBox(height: 20),

          // Search tags
          _SectionLabel('Search tags'),
          const SizedBox(height: 8),
          if (_searchTags.isNotEmpty) ...[
            Wrap(spacing: 7, runSpacing: 6, children: _searchTags.map((t) =>
              GestureDetector(
                onTap: () => setState(() => _searchTags.remove(t)),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 3, 8, 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.cTagBorder),
                    borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('#', style: TextStyle(fontSize: 11, color: context.cText3)),
                    Text(t, style: TextStyle(fontSize: 11, color: context.cText2, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 5),
                    Icon(Icons.close, size: 12, color: context.cText3),
                  ]),
                ))).toList()),
            const SizedBox(height: 10),
          ],
          Row(children: [
            Expanded(child: TextField(
              controller: _newTagCtrl,
              style: TextStyle(fontSize: 13.5, color: context.cText1),
              decoration: const InputDecoration(hintText: 'add a search tag'))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final tag = _newTagCtrl.text.trim();
                if (tag.isNotEmpty && !_searchTags.contains(tag)) {
                  setState(() { _searchTags.add(tag); _newTagCtrl.clear(); });
                }
              },
              child: Container(
                height: 42, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.cSurface1, borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: context.cBorder)),
                child: Row(children: [
                  Icon(Icons.add, size: 15, color: context.cText2),
                  const SizedBox(width: 4),
                  Text('Add', style: TextStyle(fontSize: 13, color: context.cText1, fontWeight: FontWeight.w500)),
                ]))),
          ]),
          const SizedBox(height: 20),

          // Pin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: context.cSurface1, borderRadius: BorderRadius.circular(13),
                border: Border.all(color: context.cBorder)),
            child: SwitchListTile(
              title: Text('Pinned', style: AppTypography.label),
              subtitle: Text('Always shows first in overlay', style: AppTypography.bodySmall),
              value: _pinned, onChanged: (v) => setState(() => _pinned = v),
              activeColor: context.cAccent, contentPadding: EdgeInsets.zero)),
          const SizedBox(height: 80),
        ]),

        // Bottom save button
        Positioned(left: 0, right: 0, bottom: 0, child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          color: context.cBgBase,
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: context.cAccent,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check, size: 17),
              const SizedBox(width: 8),
              Text(_existingId == null ? 'Create prompt' : 'Save changes',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
            ])))),

        // Folder picker overlay
        if (_showFolderPicker)
          allAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (all) => GestureDetector(
              onTap: () => setState(() => _showFolderPicker = false),
              child: Container(color: Colors.black54,
                child: Align(alignment: Alignment.bottomCenter,
                  child: GestureDetector(onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.cSurface2,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border(top: BorderSide(color: context.cBorder))),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Padding(padding: const EdgeInsets.only(top: 10), child: Center(child: SizedBox(width: 38, height: 4.5,
                          child: DecoratedBox(decoration: BoxDecoration(color: context.cSheetHandle,
                              borderRadius: const BorderRadius.all(Radius.circular(999))))))),
                        FolderPickerSheet(
                          allPrompts: all, currentPath: _path,
                          onPick: (p) => setState(() { _path = p; _showFolderPicker = false; })),
                      ]),
                    ),
                  ),
                ),
              ),
            )),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.06, color: context.cText3));
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.child);
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _SectionLabel(label), const SizedBox(height: 6), child, const SizedBox(height: 16)]);
}
