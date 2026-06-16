import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_context_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/prompt_provider.dart';
import '../../../services/export_service.dart';

class ExportScopeSheet extends ConsumerWidget {
  const ExportScopeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(promptsStreamProvider);

    return allAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: context.cAccent)),
      ),
      error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text('$e')),
      data: (all) {
        final yourCount = all.where((p) => !p.isStarter).length;
        final starterCount = all.where((p) => p.isStarter).length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export prompts', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text('Choose what to include in the ZIP',
                  style: TextStyle(fontSize: 12, color: context.cText3)),
              const SizedBox(height: 16),
              _ScopeOption(label: 'All prompts', count: all.length,
                  onTap: all.isNotEmpty ? () => Navigator.of(context).pop(ExportScope.all) : null),
              const SizedBox(height: 8),
              _ScopeOption(label: 'Your prompts', count: yourCount,
                  onTap: yourCount > 0 ? () => Navigator.of(context).pop(ExportScope.yours) : null),
              const SizedBox(height: 8),
              _ScopeOption(label: 'Starter library', count: starterCount,
                  onTap: starterCount > 0 ? () => Navigator.of(context).pop(ExportScope.starters) : null),
            ],
          ),
        );
      },
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({required this.label, required this.count, this.onTap});
  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap != null ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cSurface1,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: context.cBorder),
          ),
          child: Row(children: [
            Expanded(child: Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            Text('$count prompt${count == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: context.cText3)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: context.cText3),
          ]),
        ),
      ),
    );
  }
}
