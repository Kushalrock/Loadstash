import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../providers/overlay_provider.dart';
import '../../providers/repository_providers.dart';
import '../../services/bubble_channel.dart';
import '../../services/model_tag_service.dart';
import '../../services/preferences_service.dart';
import '../../services/process_text_channel.dart';
import '../../services/variable_detector.dart';
import 'widgets/overlay_search_bar.dart';
import 'widgets/overlay_prompt_row.dart';
import 'widgets/variable_fill_sheet.dart';

enum OverlayMode { processText, bubble }

class OverlayScreen extends ConsumerStatefulWidget {
  const OverlayScreen({super.key, this.mode = OverlayMode.processText});
  final OverlayMode mode;

  @override
  ConsumerState<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends ConsumerState<OverlayScreen> {
  String _query = '';
  String? _modelFilter;
  List<Prompt> _prompts = [];
  bool _loading = true;

  bool _showQuickAdd = false;
  final _quickAddCtrl = TextEditingController();
  List<String> _quickAddModels = [];
  bool _quickAddPinned = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _quickAddCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Reset filter state on each launch
    _query = '';
    _modelFilter = null;
    _showQuickAdd = false;
    _quickAddCtrl.clear();
    _quickAddModels = [];
    _quickAddPinned = false;
    String callingPkg = '';
    if (widget.mode == OverlayMode.processText) {
      final intentData = await ProcessTextChannel.getIntentData();
      if (intentData != null && mounted) {
        ref.read(overlayIntentProvider.notifier).state = intentData;
        callingPkg = intentData.callingPackage;
      }
    }
    final ranked = await ref.read(usageRepositoryProvider).getRankedPrompts(callingPkg);
    if (mounted) setState(() { _prompts = ranked; _loading = false; });
  }

  Future<void> _onPromptTapped(Prompt prompt) async {
    final vars = VariableDetector.detect(prompt.body);
    if (vars.isEmpty) {
      await _insertAndClose(prompt.body, prompt.id);
    } else {
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (sheetCtx) => VariableFillSheet(
          promptBody: prompt.body,
          variableNames: vars,
          onInsert: (assembled) async {
            Navigator.of(sheetCtx).pop();
            await _insertAndClose(assembled, prompt.id);
          },
        ),
      );
    }
  }

  Future<void> _insertAndClose(String text, int promptId) async {
    if (widget.mode == OverlayMode.processText) {
      final intentData = ref.read(overlayIntentProvider);
      if (intentData != null) {
        await ref
            .read(usageRepositoryProvider)
            .recordUsage(promptId, intentData.callingPackage);
      }
      await ProcessTextChannel.setResult(text);
    } else {
      await BubbleChannel.insertText(text);
    }
  }

  Future<void> _saveQuickAdd() async {
    final body = _quickAddCtrl.text.trim();
    if (body.isEmpty) return;

    var title = body
        .split('\n').first
        .replaceAll(RegExp(r'\{\{(\w+)\}\}'), r'$1')
        .trim();
    if (title.length > 42) title = '${title.substring(0, 42)}…';
    if (title.isEmpty) title = 'Quick prompt';

    final quickAddPath = await PreferencesService.getQuickAddPath();

    await ref.read(promptRepositoryProvider).create(
      title: title,
      body: body,
      path: quickAddPath,
      modelTags: _quickAddModels.join(','),
      pinned: _quickAddPinned,
    );

    if (mounted) {
      final location = quickAddPath.isEmpty ? 'Library' : quickAddPath.join(' › ');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $location')));
      setState(() {
        _showQuickAdd = false;
        _quickAddCtrl.clear();
        _quickAddModels = [];
        _quickAddPinned = false;
      });
    }
  }

  List<Prompt> get _filtered {
    var result = _prompts;
    if (_modelFilter != null) {
      result = result.where((p) =>
          p.modelTags.split(',').map((s) => s.trim()).contains(_modelFilter!)).toList();
    }
    if (_query.isEmpty) return result;
    final q = _query.toLowerCase();
    return result.where((p) =>
        p.title.toLowerCase().contains(q) || p.body.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.mode == OverlayMode.processText) {
                  ProcessTextChannel.cancel();
                } else {
                  BubbleChannel.cancel();
                }
              },
              child: Container(color: Colors.black54),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OverlaySearchBar(
                              onChanged: (q) => setState(() => _query = q),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _showQuickAdd = true),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Model filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(children: [
                        _ModelChip(label: 'All', color: null, active: _modelFilter == null,
                            onTap: () => setState(() => _modelFilter = null)),
                        const SizedBox(width: 7),
                        ...[
                          ('claude', 'Claude', AppColors.modelClaude),
                          ('chatgpt', 'ChatGPT', AppColors.modelChatGpt),
                          ('gemini', 'Gemini', AppColors.modelGemini),
                          ('local', 'Local', AppColors.modelLocal),
                        ].map((e) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: _ModelChip(
                            label: e.$2, color: e.$3,
                            active: _modelFilter == e.$1,
                            onTap: () => setState(() => _modelFilter = _modelFilter == e.$1 ? null : e.$1)))),
                      ]),
                    ),
                    if (_showQuickAdd)
                      _buildQuickAddView()
                    else if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.accent),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => OverlayPromptRow(
                            prompt: _filtered[i],
                            onTap: () => _onPromptTapped(_filtered[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddView() {
    final vars = VariableDetector.detect(_quickAddCtrl.text);
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              GestureDetector(
                onTap: () => setState(() => _showQuickAdd = false),
                child: const Icon(Icons.chevron_left, size: 20, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quick add', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text('Paste a prompt to save it instantly',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ])),
              TextButton(
                onPressed: _quickAddCtrl.text.trim().isNotEmpty ? _saveQuickAdd : null,
                child: Text('Save', style: TextStyle(
                  color: _quickAddCtrl.text.trim().isNotEmpty
                      ? AppColors.accentText : AppColors.textTertiary,
                  fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _quickAddCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                  color: AppColors.textPrimary, height: 1.6),
              maxLines: 6,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Paste or type your prompt. Use {{variable}} for fill-ins.',
                alignLabelWithHint: true),
            ),
            if (vars.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.tune, size: 14, color: AppColors.accentText),
                const SizedBox(width: 6),
                Text(
                  '${vars.length} variable${vars.length == 1 ? '' : 's'} detected: ${vars.join(', ')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.accentText)),
              ]),
            ],
            const SizedBox(height: 16),
            const Text('MODEL TAGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.06, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ModelTagService.all.map((tag) {
                final selected = _quickAddModels.contains(tag.key);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) _quickAddModels.remove(tag.key);
                    else _quickAddModels.add(tag.key);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? tag.colorValue.withOpacity(0.13) : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: selected ? tag.colorValue.withOpacity(0.47) : AppColors.borderHairline)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: tag.colorValue)),
                      const SizedBox(width: 6),
                      Text(tag.label, style: TextStyle(
                          fontSize: 12.5,
                          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                      if (selected) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.check, size: 13, color: AppColors.textPrimary),
                      ],
                    ])),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.surface1, borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.borderHairline)),
              child: SwitchListTile(
                title: const Text('Pinned', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                value: _quickAddPinned,
                onChanged: (v) => setState(() => _quickAddPinned = v),
                activeColor: AppColors.accent,
                contentPadding: EdgeInsets.zero)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _quickAddCtrl.text.trim().isNotEmpty ? _saveQuickAdd : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: AppColors.accentTint,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Save prompt',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)))),
          ],
        ),
      ),
    );
  }
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({required this.label, required this.color, required this.active, required this.onTap});
  final String label;
  final Color? color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accentTint : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.accentDim : AppColors.borderHairline)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (color != null) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(fontSize: 12.5,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w500)),
        ])));
  }
}
