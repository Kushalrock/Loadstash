import 'package:flutter/material.dart';
import '../../../core/theme/app_context_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';

class PinnedRow extends StatelessWidget {
  const PinnedRow({super.key, required this.prompts, required this.onTap});
  final List<Prompt> prompts;
  final ValueChanged<Prompt> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (_, i) => _PinnedCard(prompt: prompts[i], onTap: onTap),
      ),
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.prompt, required this.onTap});
  final Prompt prompt;
  final ValueChanged<Prompt> onTap;

  @override
  Widget build(BuildContext context) {
    final models = prompt.modelTags.split(',').where((s) => s.isNotEmpty).toList();
    return GestureDetector(
      onTap: () => onTap(prompt),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cSurface1,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: context.cBorder),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(prompt.title,
                      style: AppTypography.label.copyWith(fontSize: 13.5),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRect(
                    child: Text(
                      prompt.body.replaceAll(RegExp(r'\{\{(\w+)\}\}'), r'$1').replaceAll('\n', ' '),
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: context.cText2, height: 1.5),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: models.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(width: 7, height: 7,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? _modelColor(m) : _modelColor(m))),
                    );
                  }).toList(),
                ),
              ],
            ),
            Positioned(top: 0, right: 0,
              child: Icon(Icons.push_pin, size: 14, color: context.cAccent)),
          ],
        ),
      ),
    );
  }

  static Color _modelColor(String key) {
    return switch (key) {
      'claude'  => const Color(0xFFD97757),
      'chatgpt' => const Color(0xFF10A37F),
      'gemini'  => const Color(0xFF5B9CF6),
      _         => const Color(0xFF8A909C),
    };
  }
}
