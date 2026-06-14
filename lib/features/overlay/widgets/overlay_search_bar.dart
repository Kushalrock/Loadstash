import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OverlaySearchBar extends StatefulWidget {
  const OverlaySearchBar({super.key, required this.onChanged, this.autofocus = true});
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<OverlaySearchBar> createState() => _OverlaySearchBarState();
}

class _OverlaySearchBarState extends State<OverlaySearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: (v) {
        setState(() {});
        widget.onChanged(v);
      },
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search prompts…',
        prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textTertiary, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
