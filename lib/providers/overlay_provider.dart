import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';

class OverlayIntentData {
  const OverlayIntentData({
    required this.selectedText,
    required this.isReadOnly,
    required this.callingPackage,
  });

  final String selectedText;
  final bool isReadOnly;
  final String callingPackage;
}

final overlayIntentProvider = StateProvider<OverlayIntentData?>((ref) => null);
final selectedPromptProvider = StateProvider<Prompt?>((ref) => null);
final variableValuesProvider = StateProvider<Map<String, String>>((ref) => {});
final modelFilterProvider = StateProvider<String?>((ref) => null);
