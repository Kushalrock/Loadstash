import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class VariablePill extends StatelessWidget {
  const VariablePill({super.key, required this.name, this.value});
  final String name;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Text(
        value != null && value!.isNotEmpty ? value! : '{{$name}}',
        style: AppTypography.monoSmall.copyWith(color: AppColors.accent),
      ),
    );
  }
}
