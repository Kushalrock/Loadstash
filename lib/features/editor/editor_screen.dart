import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../providers/repository_providers.dart';
import '../../services/variable_detector.dart';
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
  bool _pinned = false;
  String _modelTags = '';
  List<String> _detectedVars = [];
  bool _loading = true;
  Prompt? _existing;

  static const _modelOptions = ['claude', 'chatgpt', 'gemini', 'local', 'image'];

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
          _existing = p;
          _titleCtrl.text = p.title;
          _bodyCtrl.text = p.body;
          _pinned = p.pinned;
          _modelTags = p.modelTags;
          _detectedVars = VariableDetector.detect(p.body);
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onBodyChanged() {
    setState(() {
      _detectedVars = VariableDetector.detect(_bodyCtrl.text);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final repo = ref.read(promptRepositoryProvider);
    if (_existing != null) {
      await repo.update(
        id: _existing!.id,
        title: title,
        body: body,
        pinned: _pinned,
        modelTags: _modelTags,
      );
    } else {
      await repo.create(title: title, body: body, pinned: _pinned, modelTags: _modelTags);
    }

    if (mounted) {
      if (_detectedVars.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Detected ${_detectedVars.length} variable(s): ${_detectedVars.join(', ')}',
            ),
          ),
        );
      }
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (_existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Delete prompt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(promptRepositoryProvider).delete(_existing!.id);
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _bodyCtrl.removeListener(_onBodyChanged);
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existing == null ? 'New prompt' : 'Edit prompt',
          style: AppTypography.label,
        ),
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        actions: [
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            style: AppTypography.label,
            decoration: const InputDecoration(hintText: 'Title', labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            style: AppTypography.mono,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Prompt body — use {{variable}} for fill-in fields',
              labelText: 'Body',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          if (_bodyCtrl.text.isNotEmpty) ...[
            Text(
              'Preview',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 6),
            VariablePreview(body: _bodyCtrl.text, variableNames: _detectedVars),
            const SizedBox(height: 16),
          ],
          Text(
            'Model tags',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _modelOptions.map((m) {
              final selected = _modelTags.split(',').contains(m);
              return FilterChip(
                label: Text(m),
                selected: selected,
                onSelected: (v) {
                  final tags = _modelTags.split(',').where((t) => t.isNotEmpty).toList();
                  if (v) {
                    tags.add(m);
                  } else {
                    tags.remove(m);
                  }
                  setState(() => _modelTags = tags.join(','));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text('Pinned', style: AppTypography.label),
            subtitle: Text('Always shows first in overlay', style: AppTypography.bodySmall),
            value: _pinned,
            onChanged: (v) => setState(() => _pinned = v),
            activeColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
