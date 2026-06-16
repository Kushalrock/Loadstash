import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_context_colors.dart';
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
      backgroundColor: context.cSurface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const ModelTagEditorSheet(),
    );
    if (tag == null) return;
    await ModelTagService.save([..._modelTags, tag]);
    if (mounted) setState(() => _modelTags = List.of(ModelTagService.all));
  }

  Future<void> _editModelTag(int index) async {
    final tag = await showModalBottomSheet<ModelTag>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cSurface2,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cBgBase, elevation: 0,
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, size: 20),
          label: const Text('Settings'),
          style: TextButton.styleFrom(foregroundColor: context.cText2)),
        leadingWidth: 110),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 24), children: [
        const Text('Tags', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -0.46)),
        const SizedBox(height: 4),
        Text('Two ways to organise — search tags you create, and model tags for where a prompt runs.',
            style: TextStyle(fontSize: 13, color: context.cText2, height: 1.5)),
        const SizedBox(height: 22),

        // ── Search tags ─────────────────────────────────────
        Row(children: [
          Icon(Icons.tag, size: 16, color: context.cText2),
          const SizedBox(width: 8),
          const Text('Search tags', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text('Freeform, made by you — for organising and finding prompts.',
            style: TextStyle(fontSize: 12, color: context.cText3, height: 1.5)),
        const SizedBox(height: 13),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ..._searchTags.map((t) => GestureDetector(
            onTap: () => setState(() => _searchTags.remove(t)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border.all(color: context.cTagBorder),
                borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('#', style: TextStyle(fontSize: 11, color: context.cText3)),
                Text(t, style: TextStyle(fontSize: 11, color: context.cText2, fontWeight: FontWeight.w500)),
                const SizedBox(width: 5),
                Icon(Icons.close, size: 12, color: context.cText3),
              ])))),
          _addingTag
            ? SizedBox(width: 120, height: 28,
                child: TextField(
                  controller: _newTagCtrl, autofocus: true,
                  style: TextStyle(fontSize: 11, color: context.cText1),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(color: context.cAccentDim)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(color: context.cAccent))),
                  onSubmitted: (v) {
                    final tag = v.trim();
                    if (tag.isNotEmpty && !_searchTags.contains(tag)) setState(() => _searchTags.add(tag));
                    setState(() { _addingTag = false; _newTagCtrl.clear(); });
                  }))
            : GestureDetector(
                onTap: () => setState(() => _addingTag = true),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 11, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: context.cAccentDim)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 13, color: context.cAccentText),
                    const SizedBox(width: 4),
                    Text('New tag', style: TextStyle(fontSize: 11.5, color: context.cAccentText, fontWeight: FontWeight.w500)),
                  ]))),
        ]),
        Divider(height: 32, color: context.cBorder),

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
        Text('Colour-coded by model. Edit or delete any tag, or add your own.',
            style: TextStyle(fontSize: 12, color: context.cText3, height: 1.5)),
        const SizedBox(height: 13),
        ...List.generate(_modelTags.length, (i) {
          final tag = _modelTags[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: context.cSurface1, borderRadius: BorderRadius.circular(13),
              border: Border.all(color: context.cBorder)),
            child: Row(children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: tag.colorValue)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tag.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(tag.color.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: context.cText3, fontFamily: 'JetBrainsMono')),
              ])),
              GestureDetector(
                onTap: () => _editModelTag(i),
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: context.cSurface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.cBorder)),
                  child: Icon(Icons.edit_outlined, size: 16, color: context.cText2))),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _deleteModelTag(i),
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: context.cSurface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.cBorder)),
                  child: Icon(Icons.delete_outline, size: 16, color: context.cText2))),
            ]));
        }),
        GestureDetector(
          onTap: _addModelTag,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cBorder)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add, size: 16, color: context.cText2),
              const SizedBox(width: 7),
              Text('Add model tag', style: TextStyle(fontSize: 13, color: context.cText2, fontWeight: FontWeight.w500)),
            ]))),
      ]),
    );
  }
}
