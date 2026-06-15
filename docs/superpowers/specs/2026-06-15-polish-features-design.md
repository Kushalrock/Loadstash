# Polish Features — Design Spec

## Features
1. Quick Add in overlay bottom sheet
2. Default save location (Settings)
3. Custom model tags — add/edit/delete all, preset + hex colour picker
4. Light theme wiring
5. Remove "New prompt" label under library FAB

---

## 1. Quick Add in Overlay

### Trigger
`+` button inline with the search bar inside the overlay bottom sheet (right side, same row height as search field, accent colour background, 44×44dp rounded square).

### Sheet layout
When tapped, the overlay bottom sheet switches from the prompt picker to a Quick Add sub-view (AnimatedSwitcher, no new route):

```
← Back     Quick add
Paste or type your prompt. Use {{variable}} for fill-ins.

[Mono textarea — min 112dp]

2 variables detected: name, company   ← auto-updated on input

Model tags (horizontal chip row, same as overlay filter chips)

[Pinned toggle row]

[Save prompt — filled primary button]
```

### Behaviour
- Variables auto-detected from `{{name}}` syntax via `VariableDetector.detect()`
- Saves to the "Quick add location" folder (from `SharedPreferences`, default `[]` = Library root)
- Model tags: multi-select, same chips as the picker's model filter row
- On save: `PromptRepository.create(title: firstLine, body: ..., path: quickAddPath, modelTags: ..., pinned: ...)`, then show "Saved to [folder]" snackbar, return to picker view
- Title auto-generated: first line of body, max 42 chars, variables stripped

---

## 2. Default Save Location (Settings)

### Location
"Your library" section in Settings, between "Manage tags" and the end of the section.

```
_SettingsRow(
  icon: Icons.folder_outlined,
  title: 'Quick add location',
  desc: current path or 'Library (root)',
  right: chevron,
  onTap: → FolderPickerSheet,
)
```

### Storage
- Key: `quick_add_path`
- Value: JSON-encoded `List<String>` e.g. `'["Work","Meetings"]'`
- Service: `PreferencesService.getQuickAddPath()` / `setQuickAddPath(List<String>)`
- Default: `[]` (Library root)

### Overlay reads this
`OverlayScreen` (bubble mode) and the Quick Add sheet read `PreferencesService.getQuickAddPath()` on save.

---

## 3. Custom Model Tags

### Storage
`SharedPreferences` key `model_tags` — JSON list of objects:
```json
[
  {"key": "claude",  "label": "Claude",  "color": "#D97757", "builtin": true},
  {"key": "chatgpt", "label": "ChatGPT", "color": "#10A37F", "builtin": true},
  {"key": "gemini",  "label": "Gemini",  "color": "#5B9CF6", "builtin": true},
  {"key": "local",   "label": "Local",   "color": "#8A909C", "builtin": true}
]
```
On first run, seed with the 4 defaults. All tags (builtin or custom) can be edited and deleted.

### Service: `ModelTagService`
```dart
class ModelTagService {
  static Future<List<ModelTag>> getTags();
  static Future<void> saveTags(List<ModelTag> tags);
  static Future<void> resetToDefaults(); // restore 4 built-ins
}

class ModelTag {
  final String key;    // unique, used in modelTags field
  final String label;  // display name
  final String color;  // hex string e.g. "#D97757"
  final bool builtin;
}
```

### Tags screen changes
- Remove "prefilled" / "custom" badge from all rows
- Every row: edit icon (pencil, t2 colour) + delete icon (trash, t2 colour) on right side
- Delete: immediate removal + "Label deleted" snackbar with Undo (3s)
- "Add model tag" button at bottom → `ModelTagEditorSheet`

### ModelTagEditorSheet (add + edit)
Bottom sheet with:
1. **Label** text field
2. **Key** text field (auto-slugified from label, user-editable, pattern `[a-z][a-z0-9_-]*`)
3. **Colour selector:**
   - 12 preset swatches in a 4×3 grid:
     `#D97757` `#10A37F` `#5B9CF6` `#8A909C` `#F43F5E` `#F59E0B` `#14B8A6` `#6366F1` `#0EA5E9` `#84CC16` `#8B5CF6` `#64748B`
   - Selected swatch has accent ring
   - "Other…" toggle below grid reveals a hex text input (`#RRGGBB`)
4. **Save** / **Cancel** buttons

Validation:
- Label: non-empty
- Key: unique, matches `[a-z][a-z0-9_-]*`, max 32 chars
- Color: valid 6-digit hex

### AppColors.forModel() update
`AppColors.forModel(key)` must read from `ModelTagService` at runtime (not hardcoded). Since it's called in widget builds, expose a synchronous lookup from a cached list loaded at app startup.

---

## 4. Light Theme Wiring

### Riverpod provider
```dart
// lib/providers/theme_provider.dart
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
```

### LoadstashApp
```dart
// reads themeModeProvider
themeMode: ref.watch(themeModeProvider),
```

### Settings theme toggle
Currently updates local `_theme` string. Change to:
```dart
ref.read(themeModeProvider.notifier).state =
    value == 'light' ? ThemeMode.light : ThemeMode.dark;
```

### Persistence
Save to `SharedPreferences` (key `theme_mode`, values `'light'` / `'dark'`). Load on app start into the provider's initial value.

---

## 5. Remove "New prompt" Label

In `LibraryScreen._buildBottomNav()` and `SettingsScreen._buildBottomNav()`, remove the `Text('New prompt', ...)` widget and its `SizedBox` spacer below the FAB.

---

## Files

```
lib/providers/theme_provider.dart                 CREATE
lib/services/model_tag_service.dart               CREATE
lib/features/settings/widgets/
  model_tag_editor_sheet.dart                     CREATE
lib/services/preferences_service.dart             MODIFY — add quick_add_path + theme_mode
lib/features/overlay/overlay_screen.dart          MODIFY — quick add sub-view + + button
lib/features/settings/settings_screen.dart        MODIFY — theme wiring, quick add location row
lib/features/settings/tags_screen.dart            MODIFY — remove prefilled badge, add edit/delete
lib/main.dart                                     MODIFY — load saved theme on startup
lib/app.dart                                      MODIFY — watch themeModeProvider
lib/features/library/library_screen.dart          MODIFY — remove "New prompt" label
lib/core/theme/app_colors.dart                    MODIFY — forModel() reads ModelTagService
```
