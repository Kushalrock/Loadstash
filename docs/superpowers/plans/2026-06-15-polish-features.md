# Polish Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task.

**Goal:** Add quick-add in overlay, default save location, custom model tags with colour picker, light theme wiring, and remove "New prompt" label.

**Architecture:** New `ModelTagService` holds a runtime-cached list of model tags (seeded from defaults, persisted in SharedPreferences); `AppColors.forModel()` delegates to it. Theme stored in a Riverpod `StateProvider<ThemeMode>` loaded at startup. Quick Add lives as an in-sheet sub-view on `OverlayScreen`.

**Tech Stack:** Flutter · Riverpod · SharedPreferences · existing PromptRepository/FolderPickerSheet

---

## File Structure

```
lib/services/model_tag_service.dart             CREATE — ModelTag model + CRUD + colorForKey()
lib/providers/theme_provider.dart               CREATE — StateProvider<ThemeMode>
lib/features/settings/widgets/
  model_tag_editor_sheet.dart                   CREATE — add/edit sheet with colour picker
lib/services/preferences_service.dart           MODIFY — add quick_add_path + theme_mode keys
lib/core/theme/app_colors.dart                  MODIFY — forModel() delegates to ModelTagService
lib/main.dart                                   MODIFY — init ModelTagService + load saved theme
lib/app.dart                                    MODIFY — LoadstashApp watches themeModeProvider
lib/features/settings/tags_screen.dart          MODIFY — edit/delete/add via ModelTagService
lib/features/settings/settings_screen.dart      MODIFY — theme wiring + quick add location row
lib/features/library/library_screen.dart        MODIFY — remove "New prompt" label
lib/features/overlay/overlay_screen.dart        MODIFY — + button + Quick Add sub-view
```

---

## Task 1: Trivial — Remove "New prompt" label

**Files:**
- Modify: `lib/features/library/library_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Remove label from LibraryScreen._buildBottomNav()**

Read `lib/features/library/library_screen.dart`. Find `_buildBottomNav`. Remove the `Text('New prompt', ...)` widget and its preceding `SizedBox(height: 3)` or similar spacer. The Column inside the FAB section should shrink to just the FAB button.

The FAB Column currently looks like:
```dart
Column(mainAxisSize: MainAxisSize.min, children: [
  GestureDetector(
    onTap: () => context.push('/editor'),
    child: Container(width: 52, height: 52, ...),
  ),
  const Text('New prompt', style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
]),
```

Change to:
```dart
GestureDetector(
  onTap: () => context.push('/editor'),
  child: Container(width: 52, height: 52, margin: const EdgeInsets.only(bottom: 6), ...),
),
```

- [ ] **Step 2: Remove label from SettingsScreen._buildBottomNav()**

Read `lib/features/settings/settings_screen.dart`. Find `_buildBottomNav`. Apply the same change — remove the `Text('New prompt', ...)` widget.

- [ ] **Step 3: Build**

```bash
cd /Users/agrkushal/Documents/Promptezy/promptezy
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Commit**

```bash
git add lib/features/library/library_screen.dart lib/features/settings/settings_screen.dart
git commit -m "fix: remove 'New prompt' label from bottom nav FAB"
```

---

## Task 2: ModelTagService

**Files:**
- Create: `lib/services/model_tag_service.dart`
- Create: `test/services/model_tag_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/services/model_tag_service_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/model_tag_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('initializes with 4 default tags', () async {
    await ModelTagService.initialize();
    expect(ModelTagService.all.length, 4);
    expect(ModelTagService.all.map((t) => t.key),
        containsAll(['claude', 'chatgpt', 'gemini', 'local']));
  });

  test('colorForKey returns correct color for known key', () async {
    await ModelTagService.initialize();
    expect(ModelTagService.colorForKey('claude'), isA<Color>());
    expect(ModelTagService.colorForKey('claude').value,
        const Color(0xFFD97757).value);
  });

  test('colorForKey returns fallback grey for unknown key', () async {
    await ModelTagService.initialize();
    final color = ModelTagService.colorForKey('unknown');
    expect(color.value, const Color(0xFF8A909C).value);
  });

  test('save and reload persists tags', () async {
    await ModelTagService.initialize();
    final newTags = [
      ...ModelTagService.all,
      const ModelTag(key: 'myai', label: 'My AI', color: '#F43F5E'),
    ];
    await ModelTagService.save(newTags);
    await ModelTagService.initialize(); // reload from prefs
    expect(ModelTagService.all.length, 5);
    expect(ModelTagService.all.last.key, 'myai');
  });

  test('ModelTag.colorValue parses hex correctly', () {
    const tag = ModelTag(key: 'x', label: 'X', color: '#F43F5E');
    expect(tag.colorValue.value, const Color(0xFFF43F5E).value);
  });
}
```

Run: `flutter test test/services/model_tag_service_test.dart` — expected FAIL.

- [ ] **Step 2: Create model_tag_service.dart**

```dart
// lib/services/model_tag_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelTag {
  const ModelTag({
    required this.key,
    required this.label,
    required this.color,
    this.builtin = false,
  });

  final String key;
  final String label;
  final String color; // hex e.g. "#D97757"
  final bool builtin;

  Color get colorValue {
    try {
      final hex = color.startsWith('#') ? color.substring(1) : color;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF8A909C);
    }
  }

  Map<String, dynamic> toJson() =>
      {'key': key, 'label': label, 'color': color, 'builtin': builtin};

  factory ModelTag.fromJson(Map<String, dynamic> json) => ModelTag(
        key: json['key'] as String,
        label: json['label'] as String,
        color: json['color'] as String,
        builtin: json['builtin'] as bool? ?? false,
      );

  ModelTag copyWith({String? key, String? label, String? color, bool? builtin}) =>
      ModelTag(
        key: key ?? this.key,
        label: label ?? this.label,
        color: color ?? this.color,
        builtin: builtin ?? this.builtin,
      );
}

abstract final class ModelTagService {
  static const _key = 'model_tags';

  static List<ModelTag> _cache = [];

  static const _defaults = [
    ModelTag(key: 'claude',  label: 'Claude',  color: '#D97757', builtin: true),
    ModelTag(key: 'chatgpt', label: 'ChatGPT', color: '#10A37F', builtin: true),
    ModelTag(key: 'gemini',  label: 'Gemini',  color: '#5B9CF6', builtin: true),
    ModelTag(key: 'local',   label: 'Local',   color: '#8A909C', builtin: true),
  ];

  /// Must be called at app start before any widget builds.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _cache = List.of(_defaults);
      await _persist(prefs);
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _cache = list
            .map((e) => ModelTag.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cache = List.of(_defaults);
      }
    }
  }

  static List<ModelTag> get all => List.unmodifiable(_cache);

  /// Synchronous lookup — safe to call in widget build().
  static Color colorForKey(String key) {
    try {
      return _cache.firstWhere((t) => t.key == key).colorValue;
    } catch (_) {
      return const Color(0xFF8A909C);
    }
  }

  static Future<void> save(List<ModelTag> tags) async {
    _cache = List.of(tags);
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs);
  }

  static Future<void> _persist(SharedPreferences prefs) async {
    await prefs.setString(
        _key, jsonEncode(_cache.map((t) => t.toJson()).toList()));
  }
}
```

- [ ] **Step 3: Run tests**

```bash
flutter test test/services/model_tag_service_test.dart
```

Expected: 5 tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/services/model_tag_service.dart test/services/model_tag_service_test.dart
git commit -m "feat: ModelTagService — persistent model tags with runtime colorForKey()"
```

---

## Task 3: PreferencesService extensions + AppColors + main.dart + theme_provider

**Files:**
- Modify: `lib/services/preferences_service.dart`
- Modify: `lib/core/theme/app_colors.dart`
- Modify: `lib/main.dart`
- Create: `lib/providers/theme_provider.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Extend PreferencesService**

Read `lib/services/preferences_service.dart`. Add to the bottom:

```dart
  // Quick add save location
  static const _keyQuickAddPath = 'quick_add_path';

  static Future<List<String>> getQuickAddPath() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyQuickAddPath);
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  static Future<void> setQuickAddPath(List<String> path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuickAddPath, jsonEncode(path));
  }

  // Theme
  static const _keyThemeMode = 'theme_mode';

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'dark';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }
```

Add `import 'dart:convert';` at the top if not already present.

- [ ] **Step 2: Update AppColors.forModel() to delegate to ModelTagService**

Read `lib/core/theme/app_colors.dart`. Replace the `forModel()` method:

```dart
  // Model color by key — reads from ModelTagService at runtime
  static Color forModel(String key) => ModelTagService.colorForKey(key);
```

Add import at the top:
```dart
import '../services/model_tag_service.dart';
```

The hardcoded `modelClaude`, `modelChatGpt`, `modelGemini`, `modelLocal` constants can stay for backwards compatibility — they just won't be used by `forModel()` anymore.

- [ ] **Step 3: Create theme_provider.dart**

```dart
// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
```

- [ ] **Step 4: Update main.dart to initialize services and load saved theme**

Read `lib/main.dart`. Replace with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/theme_provider.dart';
import 'services/model_tag_service.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ModelTagService.initialize();
  final savedTheme = await PreferencesService.getThemeMode();
  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark,
        ),
      ],
      child: const LoadstashApp(),
    ),
  );
}
```

- [ ] **Step 5: Update app.dart — LoadstashApp watches themeModeProvider**

Read `lib/app.dart`. Update `LoadstashApp.build()` to watch the provider:

```dart
class LoadstashApp extends ConsumerWidget {
  const LoadstashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Loadstash',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

Add import: `import 'providers/theme_provider.dart';`

- [ ] **Step 6: Build and test**

```bash
flutter build apk --debug 2>&1 | tail -3
flutter test 2>&1 | tail -3
```

Expected: all tests pass, APK builds.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: PreferencesService quick_add_path/theme, ModelTagService in forModel(), theme_provider, load on startup"
```

---

## Task 4: ModelTagEditorSheet

**Files:**
- Create: `lib/features/settings/widgets/model_tag_editor_sheet.dart`

- [ ] **Step 1: Create model_tag_editor_sheet.dart**

```dart
// lib/features/settings/widgets/model_tag_editor_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
    if (_showHex) _hexCtrl.text = _selectedColor;
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
    // Uniqueness check for new tags
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
      if (raw.length == 6) {
        color = '#${raw.toUpperCase()}';
      }
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

          // Label
          const Text('NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.06, color: AppColors.textTertiary)),
          const SizedBox(height: 6),
          TextField(
            controller: _labelCtrl,
            style: AppTypography.label,
            decoration: const InputDecoration(hintText: 'e.g. Grok'),
          ),
          const SizedBox(height: 14),

          // Key
          const Text('KEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.06, color: AppColors.textTertiary)),
          const SizedBox(height: 6),
          TextField(
            controller: _keyCtrl,
            style: AppTypography.mono,
            onChanged: (_) => setState(() => _keyError = null),
            decoration: InputDecoration(
              hintText: 'e.g. grok',
              errorText: _keyError,
            ),
          ),
          const SizedBox(height: 14),

          // Colour picker
          const Text('COLOUR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.06, color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._presets.map((hex) {
                final selected = !_showHex && _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedColor = hex;
                    _showHex = false;
                  }),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: _hexToColor(hex).withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => setState(() => _showHex = !_showHex),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _showHex ? AppColors.accentTint : AppColors.surface1,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _showHex ? AppColors.accentDim : AppColors.borderHairline),
                  ),
                  child: const Icon(Icons.more_horiz, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (_showHex) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _hexCtrl,
              style: AppTypography.mono,
              decoration: const InputDecoration(
                hintText: '#F43F5E',
                prefixText: '#',
                prefixStyle: TextStyle(fontFamily: 'JetBrainsMono',
                    color: AppColors.textTertiary),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
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
```

- [ ] **Step 2: Build to verify**

```bash
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/widgets/model_tag_editor_sheet.dart
git commit -m "feat: ModelTagEditorSheet — add/edit with colour swatches + hex input"
```

---

## Task 5: Tags Screen Redesign

**Files:**
- Modify: `lib/features/settings/tags_screen.dart`

- [ ] **Step 1: Rewrite tags_screen.dart**

Read the current file. Replace entirely:

```dart
// lib/features/settings/tags_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/model_tag_service.dart';
import 'widgets/model_tag_editor_sheet.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});
  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final List<String> _searchTags = [
    'work', 'sales', 'learning', 'dev', 'data', 'creative', 'social', 'writing',
  ];
  bool _addingTag = false;
  final _newTagCtrl = TextEditingController();
  List<ModelTag> _modelTags = [];

  @override
  void initState() {
    super.initState();
    _modelTags = List.of(ModelTagService.all);
  }

  @override
  void dispose() {
    _newTagCtrl.dispose();
    super.dispose();
  }

  Future<void> _addModelTag() async {
    final tag = await showModalBottomSheet<ModelTag>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const ModelTagEditorSheet(),
    );
    if (tag == null) return;
    final updated = [..._modelTags, tag];
    await ModelTagService.save(updated);
    if (mounted) setState(() => _modelTags = List.of(ModelTagService.all));
  }

  Future<void> _editModelTag(int index) async {
    final tag = await showModalBottomSheet<ModelTag>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ModelTagEditorSheet(existing: _modelTags[index]),
    );
    if (tag == null) return;
    final updated = List.of(_modelTags)..[index] = tag;
    await ModelTagService.save(updated);
    if (mounted) setState(() => _modelTags = List.of(ModelTagService.all));
  }

  Future<void> _deleteModelTag(int index) async {
    final tag = _modelTags[index];
    final updated = List.of(_modelTags)..removeAt(index);
    await ModelTagService.save(updated);
    if (mounted) {
      setState(() => _modelTags = List.of(ModelTagService.all));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tag.label} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final restored = [...ModelTagService.all];
              restored.insert(index, tag);
              await ModelTagService.save(restored);
              if (mounted) setState(() => _modelTags = List.of(ModelTagService.all));
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgBase, elevation: 0,
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, size: 20),
          label: const Text('Settings'),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary)),
        leadingWidth: 110),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 24), children: [
        const Text('Tags', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -0.46)),
        const SizedBox(height: 4),
        const Text('Two ways to organise — search tags you create, and model tags for where a prompt runs.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 22),

        // ── Search tags ─────────────────────────────────────
        const Row(children: [
          Icon(Icons.tag, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Text('Search tags', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        const Text('Freeform, made by you — for organising and finding prompts.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5)),
        const SizedBox(height: 13),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ..._searchTags.map((t) => GestureDetector(
            onTap: () => setState(() => _searchTags.remove(t)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x33FFFFFF)),
                borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('#', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                Text(t, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(width: 5),
                const Icon(Icons.close, size: 12, color: AppColors.textTertiary),
              ])))),
          _addingTag
            ? SizedBox(width: 120, height: 28,
                child: TextField(
                  controller: _newTagCtrl, autofocus: true,
                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.accentDim)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.accent))),
                  onSubmitted: (v) {
                    final tag = v.trim();
                    if (tag.isNotEmpty && !_searchTags.contains(tag)) {
                      setState(() { _searchTags.add(tag); });
                    }
                    setState(() { _addingTag = false; _newTagCtrl.clear(); });
                  }))
            : GestureDetector(
                onTap: () => setState(() => _addingTag = true),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 11, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.accentDim)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 13, color: AppColors.accentText),
                    SizedBox(width: 4),
                    Text('New tag', style: TextStyle(fontSize: 11.5, color: AppColors.accentText, fontWeight: FontWeight.w500)),
                  ]))),
        ]),
        const Divider(height: 32, color: AppColors.borderHairline),

        // ── Model tags ───────────────────────────────────────
        Row(children: [
          Row(children: _modelTags.take(4).map((t) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(width: 7, height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: t.colorValue)))).toList()),
          const SizedBox(width: 8),
          const Text('Model tags', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        const Text('Colour-coded by model. Edit or delete any tag, or add your own.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5)),
        const SizedBox(height: 13),
        Column(children: List.generate(_modelTags.length, (i) {
          final tag = _modelTags[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface1, borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.borderHairline)),
            child: Row(children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: tag.colorValue)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tag.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(tag.color.toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary,
                        fontFamily: 'JetBrainsMono')),
              ])),
              // Edit
              GestureDetector(
                onTap: () => _editModelTag(i),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface1, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderHairline)),
                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary))),
              const SizedBox(width: 6),
              // Delete
              GestureDetector(
                onTap: () => _deleteModelTag(i),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface1, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderHairline)),
                  child: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary))),
            ]));
        })),
        GestureDetector(
          onTap: _addModelTag,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 7),
              Text('Add model tag', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ]))),
      ]),
    );
  }
}
```

- [ ] **Step 2: Build and test**

```bash
flutter build apk --debug 2>&1 | tail -3
flutter test 2>&1 | tail -3
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/tags_screen.dart
git commit -m "feat: tags screen — edit/delete all model tags, add custom, no prefilled badge"
```

---

## Task 6: Settings Screen — Theme Wiring + Quick Add Location

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

Read the current `settings_screen.dart`. Make these changes:

- [ ] **Step 1: Add imports**

Add to imports:
```dart
import '../../providers/theme_provider.dart';
import '../library/widgets/folder_picker_sheet.dart';
```

- [ ] **Step 2: Add _quickAddPath state and load it**

In `_SettingsScreenState`, add:
```dart
List<String> _quickAddPath = [];
```

In `initState()`, add after `_refreshBubbleState()`:
```dart
_loadQuickAddPath();
```

Add method:
```dart
Future<void> _loadQuickAddPath() async {
  final path = await PreferencesService.getQuickAddPath();
  if (mounted) setState(() => _quickAddPath = path);
}
```

Add method for picking:
```dart
Future<void> _pickQuickAddLocation() async {
  final allPrompts = await ref.read(promptRepositoryProvider).getAll();
  if (!mounted) return;
  final picked = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface2,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetCtx) => FolderPickerSheet(
      allPrompts: allPrompts,
      currentPath: _quickAddPath,
      title: 'Quick add location',
      onPick: (p) => Navigator.of(sheetCtx).pop(p),
    ),
  );
  if (picked != null) {
    await PreferencesService.setQuickAddPath(picked);
    if (mounted) setState(() => _quickAddPath = picked);
  }
}
```

- [ ] **Step 3: Add "Quick add location" row to "Your library" section**

Find the `_SettingsCard` for "Your library". Add a row after "Manage tags":
```dart
_SettingsRow(
  icon: Icons.folder_outlined,
  title: 'Quick add location',
  desc: _quickAddPath.isEmpty ? 'Library (root)' : _quickAddPath.join(' › '),
  right: const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
  onTap: _pickQuickAddLocation,
),
```

- [ ] **Step 4: Wire theme toggle to provider + PreferencesService**

Find `_ThemeToggle(value: _theme, onChanged: (t) => setState(() => _theme = t))`.

Change to:
```dart
_ThemeToggle(
  value: _theme,
  onChanged: (t) {
    setState(() => _theme = t);
    ref.read(themeModeProvider.notifier).state =
        t == 'light' ? ThemeMode.light : ThemeMode.dark;
    PreferencesService.setThemeMode(t);
  },
),
```

Also in `initState()`, sync `_theme` from the provider on load:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _refreshBubbleState();
  _loadQuickAddPath();
  // Sync local _theme string with current provider value
  final currentMode = ref.read(themeModeProvider);
  _theme = currentMode == ThemeMode.light ? 'light' : 'dark';
}
```

- [ ] **Step 5: Build and test**

```bash
flutter build apk --debug 2>&1 | tail -3
flutter test 2>&1 | tail -3
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat: settings — quick add location folder picker, light theme wired to provider"
```

---

## Task 7: Overlay Quick Add Sub-View

**Files:**
- Modify: `lib/features/overlay/overlay_screen.dart`

- [ ] **Step 1: Read current overlay_screen.dart**

Read the full file before editing.

- [ ] **Step 2: Add quick add state fields**

In `_OverlayScreenState`, add:
```dart
bool _showQuickAdd = false;
final _quickAddCtrl = TextEditingController();
List<String> _quickAddModels = [];
bool _quickAddPinned = false;
List<String> _quickAddVars = [];
```

Update `dispose()` to add: `_quickAddCtrl.dispose();`

- [ ] **Step 3: Add _saveQuickAdd() method**

```dart
Future<void> _saveQuickAdd() async {
  final body = _quickAddCtrl.text.trim();
  if (body.isEmpty) return;

  // Auto-title: first line, strip variables, max 42 chars
  var title = body
      .split('\n').first
      .replaceAll(RegExp(r'\{\{(\w+)\}\}'), r'$1')
      .trim();
  if (title.length > 42) title = '${title.substring(0, 42)}…';
  if (title.isEmpty) title = 'Quick prompt';

  final quickAddPath = await PreferencesService.getQuickAddPath();

  await ref.read(usageRepositoryProvider);  // ensure DB init
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
      _quickAddVars = [];
    });
  }
}
```

Add import: `import '../../services/preferences_service.dart';`

- [ ] **Step 4: Add + button in the search row**

Find the `Padding` that wraps `OverlaySearchBar`. Change it to a Row with the search bar + the + button:

```dart
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
```

- [ ] **Step 5: Wrap main content with AnimatedSwitcher for quick add toggle**

Wrap the section that shows the prompt list (everything after the model filter chips) in a conditional:

Replace the `if (_loading)` block and the `else Flexible(...)` block with:

```dart
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
```

- [ ] **Step 6: Add _buildQuickAddView() method**

```dart
Widget _buildQuickAddView() {
  final vars = VariableDetector.detect(_quickAddCtrl.text);

  return Flexible(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _showQuickAdd = false),
              child: const Icon(Icons.chevron_left, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quick add', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text('Paste a prompt to save it instantly',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ])),
            TextButton(
              onPressed: _saveQuickAdd,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _quickAddCtrl.text.trim().isNotEmpty
                      ? AppColors.accentText
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Body textarea
          TextField(
            controller: _quickAddCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
                fontFamily: 'JetBrainsMono', fontSize: 13,
                color: AppColors.textPrimary, height: 1.6),
            maxLines: 6,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Paste or type your prompt. Use {{variable}} for fill-ins.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),

          // Variable detection
          if (vars.isNotEmpty)
            Row(children: [
              Icon(Icons.tune, size: 14, color: AppColors.accentText),
              const SizedBox(width: 6),
              Text(
                '${vars.length} variable${vars.length == 1 ? '' : 's'} detected: ${vars.join(', ')}',
                style: const TextStyle(fontSize: 12, color: AppColors.accentText),
              ),
            ]),
          const SizedBox(height: 16),

          // Model selection
          const Text('MODEL TAGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.06, color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ModelTagService.all.map((tag) {
              final selected = _quickAddModels.contains(tag.key);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _quickAddModels.remove(tag.key);
                  } else {
                    _quickAddModels.add(tag.key);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? tag.colorValue.withOpacity(0.13) : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? tag.colorValue.withOpacity(0.47)
                          : AppColors.borderHairline,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: tag.colorValue)),
                    const SizedBox(width: 6),
                    Text(tag.label,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                    if (selected) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.check, size: 13, color: AppColors.textPrimary),
                    ],
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Pinned toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface1, borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.borderHairline)),
            child: SwitchListTile(
              title: const Text('Pinned',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              value: _quickAddPinned,
              onChanged: (v) => setState(() => _quickAddPinned = v),
              activeColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _quickAddCtrl.text.trim().isNotEmpty ? _saveQuickAdd : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.accentTint,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save prompt',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 7: Build and full test**

```bash
flutter build apk --debug 2>&1 | tail -3
flutter test 2>&1 | tail -3
```

Expected: all 61+ tests pass, APK builds.

- [ ] **Step 8: Commit**

```bash
git add lib/features/overlay/overlay_screen.dart
git commit -m "feat: overlay quick add — + button, body textarea, var detection, model chips, pinned toggle"
```

---

## Task 8: Final verification

- [ ] **Step 1: Run full test suite**

```bash
flutter test 2>&1 | tail -3
```

Expected: all tests pass.

- [ ] **Step 2: Check analyze errors**

```bash
flutter analyze 2>&1 | grep "^  error" | head -10
```

Expected: no errors.

- [ ] **Step 3: Final build**

```bash
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: polish features complete — quick add, default location, custom model tags, light theme"
```

---

## Self-Review: Spec Coverage

| Spec requirement | Task |
|---|---|
| Remove "New prompt" label | Task 1 |
| ModelTagService with 4 defaults, persist, colorForKey() | Task 2 |
| PreferencesService quick_add_path + theme_mode | Task 3 |
| AppColors.forModel() delegates to ModelTagService | Task 3 |
| Initialize ModelTagService + load theme at startup | Task 3 |
| themeModeProvider StateProvider | Task 3 |
| LoadstashApp watches themeModeProvider | Task 3 |
| ModelTagEditorSheet — colour swatches + hex input | Task 4 |
| TagsScreen — edit/delete all tags, no prefilled badge | Task 5 |
| TagsScreen — Add model tag via ModelTagEditorSheet | Task 5 |
| Settings — quick add location row → FolderPickerSheet | Task 6 |
| Settings — theme toggle wired to provider + persisted | Task 6 |
| Overlay — + button inline with search bar | Task 7 |
| Overlay — quick add sub-view (body, vars, models, pinned) | Task 7 |
| Quick add reads PreferencesService.getQuickAddPath() | Task 7 |
