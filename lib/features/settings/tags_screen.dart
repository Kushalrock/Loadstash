import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/model_tag_service.dart';
import 'widgets/model_tag_editor_sheet.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});
  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final List<String> _searchTags = [
    'work', 'sales', 'learning', 'dev', 'data', 'creative', 'social', 'writing',
  ];
  bool _addingTag = false;
  final _newTagCtrl = TextEditingController();
  List<ModelTag> _modelTags = [];

  @override
  void initState() {
    super.initState();
    _modelTags = List.of(ModelTagService.all);
  }

  @override
  void dispose() {
    _newTagCtrl.dispose();
    super.dispose();
  }

  Future<void> _addModelTag() async {
    final tag = await showModalBottomSheet<ModelTag>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const ModelTagEditorSheet(),
    );
    if (tag == null) return;
    final updated = [..._modelTags, tag];
    await ModelTagService.save(updated);
    if (mounted) setState(() => _modelTags = List.of(ModelTagService.all));
  }

  Future<void> _editModelTag(int index) async {
    final tag = await showModalBottomSheet<ModelTag>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ModelTagEditorSheet(existing: _modelTags[index]),
    );
    if (tag == null) return;
    final updated = List.of(_modelTags)..[index] = tag;
    await ModelTagService.save(updated);
    if (mounted) setState(() => _modelTags = List.of(ModelTagService.all));
  }

  Future<void> _deleteModelTag(int index) async {
    final tag = _modelTags[index];
    final updated = List.of(_modelTags)..removeAt(index);
    await ModelTagService.save(updated);
    if (!mounted) return;
    setState(() => _modelTags = List.of(ModelTagService.all));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tag.label} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final restored = List.of(ModelTagService.all)..insert(index, tag);
            await ModelTagService.save(restored);
            if (mounted) setState(() => _modelTags = List.of(ModelTagService.all));
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgBase, elevation: 0,
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, size: 20),
          label: const Text('Settings'),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary)),
        leadingWidth: 110),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 24), children: [
        const Text('Tags', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -0.46)),
        const SizedBox(height: 4),
        const Text('Two ways to organise — search tags you create, and model tags for where a prompt runs.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 22),

        // ── Search tags ─────────────────────────────────────
        const Row(children: [
          Icon(Icons.tag, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Text('Search tags', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        const Text('Freeform, made by you — for organising and finding prompts.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5)),
        const SizedBox(height: 13),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ..._searchTags.map((t) => GestureDetector(
            onTap: () => setState(() => _searchTags.remove(t)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x33FFFFFF)),
                borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('#', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                Text(t, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(width: 5),
                const Icon(Icons.close, size: 12, color: AppColors.textTertiary),
              ])))),
          _addingTag
            ? SizedBox(width: 120, height: 28,
                child: TextField(
                  controller: _newTagCtrl, autofocus: true,
                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.accentDim)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.accent))),
                  onSubmitted: (v) {
                    final tag = v.trim();
                    if (tag.isNotEmpty && !_searchTags.contains(tag)) {
                      setState(() { _searchTags.add(tag); });
                    }
                    setState(() { _addingTag = false; _newTagCtrl.clear(); });
                  }))
            : GestureDetector(
                onTap: () => setState(() => _addingTag = true),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 11, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.accentDim)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 13, color: AppColors.accentText),
                    SizedBox(width: 4),
                    Text('New tag', style: TextStyle(fontSize: 11.5, color: AppColors.accentText, fontWeight: FontWeight.w500)),
                  ]))),
        ]),
        const Divider(height: 32, color: AppColors.borderHairline),

        // ── Model tags ───────────────────────────────────────
        Row(children: [
          ..._modelTags.take(4).map((t) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(width: 7, height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: t.colorValue)))),
          const SizedBox(width: 8),
          const Text('Model tags', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        const Text('Colour-coded by model. Edit or delete any tag, or add your own.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5)),
        const SizedBox(height: 13),
        ...List.generate(_modelTags.length, (i) {
          final tag = _modelTags[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface1, borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.borderHairline)),
            child: Row(children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: tag.colorValue)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tag.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(tag.color.toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'JetBrainsMono')),
              ])),
              GestureDetector(
                onTap: () => _editModelTag(i),
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderHairline)),
                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary))),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _deleteModelTag(i),
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderHairline)),
                  child: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary))),
            ]));
        }),
        GestureDetector(
          onTap: _addModelTag,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 7),
              Text('Add model tag', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ]))),
      ]),
    );
  }
}
