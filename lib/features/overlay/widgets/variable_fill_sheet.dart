import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/variable_detector.dart';

class VariableFillSheet extends StatefulWidget {
  const VariableFillSheet({
    super.key,
    required this.promptBody,
    required this.variableNames,
    required this.onInsert,
  });

  final String promptBody;
  final List<String> variableNames;
  final ValueChanged<String> onInsert;

  @override
  State<VariableFillSheet> createState() => _VariableFillSheetState();
}

class _VariableFillSheetState extends State<VariableFillSheet> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {for (final v in widget.variableNames) v: TextEditingController()};
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  String get _previewText {
    final values = {for (final e in _controllers.entries) e.key: e.value.text};
    return VariableDetector.substitute(widget.promptBody, values);
  }

  void _onInsert() {
    final values = {for (final e in _controllers.entries) e.key: e.value.text};
    widget.onInsert(VariableDetector.substitute(widget.promptBody, values));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fill in variables', style: AppTypography.screenTitle),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: Listenable.merge(_controllers.values.toList()),
            builder: (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Text(
                _previewText,
                style: AppTypography.mono.copyWith(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.variableNames.map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[name],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: name,
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: '{{$name}}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _onInsert, child: const Text('Insert')),
        ],
      ),
    );
  }
}
