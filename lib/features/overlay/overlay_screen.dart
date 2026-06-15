import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../providers/overlay_provider.dart';
import '../../providers/repository_providers.dart';
import '../../services/bubble_channel.dart';
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
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

  List<Prompt> get _filtered {
    var result = _prompts;
    if (_modelFilter != null) {
      result = result.where((p) => p.modelTags.split(',').contains(_modelFilter!)).toList();
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
                      child: OverlaySearchBar(
                        onChanged: (q) => setState(() => _query = q),
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
                    if (_loading)
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
