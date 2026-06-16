import 'package:flutter/material.dart';
import '../../../core/theme/app_context_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/model_tag_service.dart';

class ModelTagEditorSheet extends StatefulWidget {
  const ModelTagEditorSheet({super.key, this.existing});
  final ModelTag? existing;

  @override
  State<ModelTagEditorSheet> createState() => _ModelTagEditorSheetState();
}

class _ModelTagEditorSheetState extends State<ModelTagEditorSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _keyCtrl;
  final TextEditingController _hexCtrl = TextEditingController();
  late String _selectedColor;
  bool _showHex = false;
  String? _keyError;

  static const _presets = [
    '#D97757', '#10A37F', '#5B9CF6', '#8A909C',
    '#F43F5E', '#F59E0B', '#14B8A6', '#6366F1',
    '#0EA5E9', '#84CC16', '#8B5CF6', '#64748B',
  ];

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.existing?.label ?? '');
    _keyCtrl = TextEditingController(text: widget.existing?.key ?? '');
    _selectedColor = widget.existing?.color ?? _presets.first;
    _showHex = !_presets.contains(_selectedColor);
    if (_showHex) _hexCtrl.text = _selectedColor.replaceAll('#', '');
    if (widget.existing == null) _labelCtrl.addListener(_autoSlugKey);
  }

  void _autoSlugKey() {
    final slug = _labelCtrl.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    _keyCtrl.text = slug.length > 32 ? slug.substring(0, 32) : slug;
  }

  void _save() {
    final label = _labelCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (label.isEmpty || key.isEmpty) return;

    if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(key)) {
      setState(() => _keyError = 'Lowercase letters, digits, _ and - only');
      return;
    }
    if (widget.existing == null) {
      final taken = ModelTagService.all.any((t) => t.key == key);
      if (taken) {
        setState(() => _keyError = 'Key already in use');
        return;
      }
    }

    String color = _selectedColor;
    if (_showHex) {
      final raw = _hexCtrl.text.trim().replaceAll('#', '');
      if (raw.length == 6) color = '#${raw.toUpperCase()}';
    }

    Navigator.of(context).pop(ModelTag(
      key: key,
      label: label,
      color: color,
      builtin: widget.existing?.builtin ?? false,
    ));
  }

  @override
  void dispose() {
    if (widget.existing == null) _labelCtrl.removeListener(_autoSlugKey);
    _labelCtrl.dispose();
    _keyCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.existing == null ? 'Add model tag' : 'Edit model tag',
              style: AppTypography.screenTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 16),

          Text('NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.06, color: context.cText3)),
          const SizedBox(height: 6),
          TextField(controller: _labelCtrl, style: AppTypography.label,
              decoration: const InputDecoration(hintText: 'e.g. Grok')),
          const SizedBox(height: 14),

          Text('KEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.06, color: context.cText3)),
          const SizedBox(height: 6),
          TextField(
            controller: _keyCtrl,
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, color: context.cText1),
            onChanged: (_) => setState(() => _keyError = null),
            decoration: InputDecoration(hintText: 'e.g. grok', errorText: _keyError),
          ),
          const SizedBox(height: 14),

          Text('COLOUR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.06, color: context.cText3)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              ..._presets.map((hex) {
                final selected = !_showHex && _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() { _selectedColor = hex; _showHex = false; }),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5),
                      boxShadow: selected
                          ? [BoxShadow(color: _hexToColor(hex).withOpacity(0.5), blurRadius: 8)]
                          : null),
                  ));
              }),
              GestureDetector(
                onTap: () => setState(() => _showHex = !_showHex),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _showHex ? context.cAccentTint : context.cSurface1,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _showHex ? context.cAccentDim : context.cBorder)),
                  child: Icon(Icons.more_horiz, size: 16, color: context.cText2)),
              ),
            ],
          ),
          if (_showHex) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _hexCtrl,
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, color: context.cText1),
              decoration: InputDecoration(
                hintText: 'F43F5E',
                prefixText: '#',
                prefixStyle: TextStyle(fontFamily: 'JetBrainsMono', color: context.cText3)),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: context.cAccent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(widget.existing == null ? 'Add tag' : 'Save changes',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.startsWith('#') ? hex.substring(1) : hex;
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF8A909C);
    }
  }
}
