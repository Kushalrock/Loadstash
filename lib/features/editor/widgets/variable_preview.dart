import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class VariablePreview extends StatelessWidget {
  const VariablePreview({super.key, required this.body, required this.variableNames});
  final String body;
  final List<String> variableNames;

  @override
  Widget build(BuildContext context) {
    if (body.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Text('Preview appears here…',
            style: AppTypography.monoSmall.copyWith(color: AppColors.textTertiary)),
      );
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    final pattern = RegExp(r'\{\{([a-zA-Z][a-zA-Z0-9_]*)\}\}');
    for (final m in pattern.allMatches(body)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: body.substring(lastEnd, m.start)));
      }
      spans.add(WidgetSpan(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.accentTint,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(m.group(0)!,
              style: AppTypography.monoSmall.copyWith(color: AppColors.accent)),
        ),
      ));
      lastEnd = m.end;
    }
    if (lastEnd < body.length) {
      spans.add(TextSpan(text: body.substring(lastEnd)));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: RichText(
        text: TextSpan(style: AppTypography.monoSmall, children: spans),
      ),
    );
  }
}
