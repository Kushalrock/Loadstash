# Loadstash v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local-first Android app that inserts saved AI prompts into any text field via Android's ACTION_PROCESS_TEXT selection menu.

**Architecture:** Flutter handles all UI (overlay bottom sheet + main app). A thin Kotlin `ProcessTextActivity` registers the PROCESS_TEXT intent and communicates with Flutter via MethodChannel. Data lives in a local Drift/SQLite database with no network calls.

**Tech Stack:** Flutter 3.x · Dart 3.x · Drift (SQLite ORM) · flutter_riverpod · go_router · google_fonts · Kotlin (Android native bridge)

---

## File Structure

```
lib/
  main.dart                          # Entry; detects overlay vs main app route
  app.dart                           # MaterialApp + go_router + theme
  core/theme/
    app_colors.dart                  # All color token constants
    app_theme.dart                   # ThemeData (dark + light)
    app_typography.dart              # TextStyle definitions
  data/
    database/
      app_database.dart              # @DriftDatabase definition
      tables/prompts_table.dart      # Prompts table
      tables/variables_table.dart    # Variables table
      tables/usage_stats_table.dart  # UsageStat table
      tables/folders_table.dart      # Folders table
      tables/tags_table.dart         # Tags + prompt_tags junction
      daos/prompt_dao.dart           # Prompt CRUD queries
      daos/usage_dao.dart            # Usage tracking queries
      daos/folder_dao.dart           # Folder CRUD
    repositories/
      prompt_repository.dart         # Business-level prompt operations
      usage_repository.dart          # Usage tracking + ranking
    seeds/starter_prompts.dart       # Curated starter prompts (inline const)
  services/
    process_text_channel.dart        # MethodChannel wrapper (Flutter side)
    ranking_service.dart             # App-aware ranking algorithm
    variable_detector.dart           # {{var}} regex detection + dedupe
    preferences_service.dart         # SharedPreferences (first-run flag)
  providers/
    database_provider.dart           # AppDatabase Riverpod provider
    repository_providers.dart        # PromptRepository, UsageRepository
    prompt_provider.dart             # Prompt list providers
    overlay_provider.dart            # Overlay state (selected text, package)
  features/
    overlay/
      overlay_screen.dart            # Translucent bottom sheet
      widgets/overlay_search_bar.dart
      widgets/overlay_prompt_list.dart
      widgets/overlay_prompt_row.dart
      widgets/variable_fill_sheet.dart
      widgets/variable_pill.dart
    library/
      library_screen.dart
      widgets/prompt_card.dart
      widgets/prompt_list_section.dart
    editor/
      editor_screen.dart
      widgets/variable_preview.dart
    settings/settings_screen.dart
    onboarding/onboarding_screen.dart

android/app/src/main/
  kotlin/com/example/promptezy/
    LoadstashApplication.kt          # Pre-warms FlutterEngine
    ProcessTextActivity.kt           # Registers PROCESS_TEXT intent
  res/values/styles.xml              # Add TransparentTheme
  AndroidManifest.xml                # Wire ProcessTextActivity + application

assets/
  fonts/                             # JetBrains Mono (downloaded in Task 1)
```

---

## Task 1: Dependencies, Project Structure & App Name

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml` (app label)
- Create: all `lib/` directories (empty, scaffold with placeholder `// TODO` files)

- [ ] **Step 1: Update pubspec.yaml**

Replace the entire `pubspec.yaml` with:

```yaml
name: loadstash
description: "Your prompts, curated and your own, usable in any app."
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.12.2

dependencies:
  flutter:
    sdk: flutter
  # Database
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0
  # State
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  # Navigation
  go_router: ^14.2.7
  # UI
  google_fonts: ^6.2.1
  # Preferences
  shared_preferences: ^2.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  drift_dev: ^2.22.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
  riverpod_lint: ^2.3.13
  custom_lint: ^0.6.7

flutter:
  uses-material-design: true
  assets:
    - assets/seeds/

  fonts:
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
```

- [ ] **Step 2: Download JetBrains Mono font files**

```bash
mkdir -p assets/fonts assets/seeds
# Download from https://www.jetbrains.com/lp/mono/ or use google_fonts package instead
# If using google_fonts (easier): remove the fonts section from pubspec and use
# GoogleFonts.jetBrainsMono() in code — this avoids the manual download
# For v1, use google_fonts for both Inter and JetBrains Mono (simpler)
```

Remove the `fonts:` block from pubspec.yaml and use `google_fonts` package in code instead. Keep `assets/seeds/` directory.

- [ ] **Step 3: Create empty seed file**

Create `assets/seeds/starter_prompts.json`:
```json
[]
```

- [ ] **Step 4: Install dependencies**

```bash
cd /Users/agrkushal/Documents/Promptezy/promptezy
flutter pub get
```

Expected: resolves packages, no errors.

- [ ] **Step 5: Create directory scaffold**

```bash
mkdir -p lib/core/theme lib/data/database/tables lib/data/database/daos \
  lib/data/repositories lib/data/seeds lib/services lib/providers \
  lib/features/overlay/widgets lib/features/library/widgets \
  lib/features/editor/widgets lib/features/settings lib/features/onboarding
```

- [ ] **Step 6: Update app label in AndroidManifest.xml**

In `android/app/src/main/AndroidManifest.xml`, change `android:label="promptezy"` to `android:label="loadstash"`.

- [ ] **Step 7: Verify Flutter runs**

```bash
flutter run --debug
```

Expected: "Hello World!" still shows. Compile succeeds.

- [ ] **Step 8: Commit**

```bash
git init  # (if not already a git repo)
git add -A
git commit -m "chore: project setup, dependencies, folder structure"
```

---

## Task 2: Design Tokens & Theme

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_typography.dart`
- Create: `lib/core/theme/app_theme.dart`
- Modify: `lib/main.dart` and `lib/app.dart`

- [ ] **Step 1: Create app_colors.dart**

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Dark palette
  static const bgBase = Color(0xFF0E0F12);
  static const surface1 = Color(0xFF16181D);
  static const surface2 = Color(0xFF1B1E24);
  static const borderHairline = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const textPrimary = Color(0xFFECEEF2);
  static const textSecondary = Color(0xFF9BA0AA);
  static const textTertiary = Color(0xFF686D78);
  static const accent = Color(0xFF8B7DF6);
  static const accentTint = Color(0x238B7DF6); // rgba(139,125,246,0.14)
  static const confirm = Color(0xFF5BC58F);

  // Light palette
  static const bgBaseLight = Color(0xFFFAFAF8);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF1A1B1E);
  static const borderLight = Color(0x14000000); // rgba(0,0,0,0.08)
  static const accentLight = Color(0xFF6F5EE0);

  // Model tag colors
  static const modelClaude = Color(0xFFC98A5E);
  static const modelChatGpt = Color(0xFF4FB58B);
  static const modelGemini = Color(0xFF5B8DEF);
  static const modelLocal = Color(0xFFB98BD4);
}
```

- [ ] **Step 2: Create app_typography.dart**

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get screenTitle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );
}
```

- [ ] **Step 3: Create app_theme.dart**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgBase,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.bgBase,
          primary: AppColors.accent,
          onPrimary: Colors.white,
          secondary: AppColors.accentTint,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardThemeData(
          color: AppColors.surface1,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: AppColors.borderHairline),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface1,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderHairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderHairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface1,
          selectedColor: AppColors.accentTint,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          side: const BorderSide(color: AppColors.borderHairline),
          shape: const StadiumBorder(),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderHairline,
          thickness: 1,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgBaseLight,
        colorScheme: const ColorScheme.light(
          surface: AppColors.bgBaseLight,
          primary: AppColors.accentLight,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimaryLight,
        ),
      );
}
```

- [ ] **Step 4: Create app.dart**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

class LoadstashApp extends ConsumerWidget {
  const LoadstashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'loadstash',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const Scaffold(
        body: Center(child: Text('loadstash')),
      ),
    );
  }
}
```

- [ ] **Step 5: Update main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: LoadstashApp()));
}
```

- [ ] **Step 6: Run and verify theme renders**

```bash
flutter run --debug
```

Expected: dark background `#0E0F12`, text "loadstash" in white. No red error screen.

- [ ] **Step 7: Write theme widget test**

Create `test/core/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/core/theme/app_colors.dart';
import 'package:loadstash/core/theme/app_theme.dart';

void main() {
  test('dark theme scaffold background is bgBase', () {
    expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.bgBase);
  });

  test('dark theme primary color is accent', () {
    expect(AppTheme.dark.colorScheme.primary, AppColors.accent);
  });

  test('bgBase is not pure black', () {
    expect(AppColors.bgBase, isNot(const Color(0xFF000000)));
  });

  test('accent is periwinkle, not generic blue', () {
    // accent has significant red and blue, low green — periwinkle test
    const c = AppColors.accent;
    expect(c.red, greaterThan(100));
    expect(c.blue, greaterThan(200));
    expect(c.green, lessThan(150));
  });
}
```

- [ ] **Step 8: Run tests**

```bash
flutter test test/core/theme/app_theme_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: design tokens, dark/light theme, typography"
```

---

## Task 3: Database Schema (Drift)

**Files:**
- Create: `lib/data/database/tables/prompts_table.dart`
- Create: `lib/data/database/tables/variables_table.dart`
- Create: `lib/data/database/tables/usage_stats_table.dart`
- Create: `lib/data/database/tables/folders_table.dart`
- Create: `lib/data/database/tables/tags_table.dart`
- Create: `lib/data/database/app_database.dart`
- Create: `lib/data/database/daos/prompt_dao.dart`
- Create: `lib/data/database/daos/usage_dao.dart`
- Create: `lib/data/database/daos/folder_dao.dart`

- [ ] **Step 1: Create folders_table.dart**

```dart
// lib/data/database/tables/folders_table.dart
import 'package:drift/drift.dart';

class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

- [ ] **Step 2: Create tags_table.dart**

```dart
// lib/data/database/tables/tags_table.dart
import 'package:drift/drift.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
}

// Junction table: many-to-many between prompts and tags
class PromptTags extends Table {
  IntColumn get promptId => integer()();
  IntColumn get tagId => integer()();

  @override
  Set<Column> get primaryKey => {promptId, tagId};
}
```

- [ ] **Step 3: Create prompts_table.dart**

```dart
// lib/data/database/tables/prompts_table.dart
import 'package:drift/drift.dart';
import 'folders_table.dart';

class Prompts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get body => text()();
  // Nullable folder reference
  IntColumn get folderId => integer().nullable().references(Folders, #id)();
  // Comma-separated model tags: "claude,chatgpt"
  TextColumn get modelTags => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isStarter => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

- [ ] **Step 4: Create variables_table.dart**

```dart
// lib/data/database/tables/variables_table.dart
import 'package:drift/drift.dart';
import 'prompts_table.dart';

class Variables extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get promptId => integer().references(Prompts, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  // "text" or "select" — v1 only uses text
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get defaultValue => text().withDefault(const Constant(''))();

  @override
  List<String> get customConstraints => ['UNIQUE (prompt_id, name)'];
}
```

- [ ] **Step 5: Create usage_stats_table.dart**

```dart
// lib/data/database/tables/usage_stats_table.dart
import 'package:drift/drift.dart';
import 'prompts_table.dart';

class UsageStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get promptId => integer().references(Prompts, #id, onDelete: KeyAction.cascade)();
  TextColumn get packageName => text()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE (prompt_id, package_name)'];
}
```

- [ ] **Step 6: Create app_database.dart**

```dart
// lib/data/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/prompts_table.dart';
import 'tables/variables_table.dart';
import 'tables/usage_stats_table.dart';
import 'tables/folders_table.dart';
import 'tables/tags_table.dart';
import 'daos/prompt_dao.dart';
import 'daos/usage_dao.dart';
import 'daos/folder_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Prompts, Variables, UsageStats, Folders, Tags, PromptTags],
  daos: [PromptDao, UsageDao, FolderDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'loadstash.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 7: Create prompt_dao.dart**

```dart
// lib/data/database/daos/prompt_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/prompts_table.dart';
import '../tables/variables_table.dart';

part 'prompt_dao.g.dart';

@DriftAccessor(tables: [Prompts, Variables])
class PromptDao extends DatabaseAccessor<AppDatabase> with _$PromptDaoMixin {
  PromptDao(super.db);

  // Get all prompts ordered by pinned first, then updated_at
  Future<List<Prompt>> getAllPrompts() =>
      (select(prompts)..orderBy([(t) => OrderingTerm.desc(t.pinned), (t) => OrderingTerm.desc(t.updatedAt)])).get();

  Stream<List<Prompt>> watchAllPrompts() =>
      (select(prompts)..orderBy([(t) => OrderingTerm.desc(t.pinned), (t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<Prompt?> getPromptById(int id) =>
      (select(prompts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertPrompt(PromptsCompanion entry) => into(prompts).insert(entry);

  Future<bool> updatePrompt(PromptsCompanion entry) => update(prompts).replace(entry);

  Future<int> deletePrompt(int id) =>
      (delete(prompts)..where((t) => t.id.equals(id))).go();

  Future<List<Variable>> getVariablesForPrompt(int promptId) =>
      (select(variables)..where((t) => t.promptId.equals(promptId))).get();

  Future<void> replaceVariables(int promptId, List<VariablesCompanion> vars) async {
    await (delete(variables)..where((t) => t.promptId.equals(promptId))).go();
    for (final v in vars) {
      await into(variables).insert(v);
    }
  }

  Future<List<Prompt>> searchPrompts(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(prompts)
          ..where((t) => t.title.lower().like(q) | t.body.lower().like(q))
          ..orderBy([(t) => OrderingTerm.desc(t.pinned)]))
        .get();
  }
}
```

- [ ] **Step 8: Create usage_dao.dart**

```dart
// lib/data/database/daos/usage_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/usage_stats_table.dart';

part 'usage_dao.g.dart';

@DriftAccessor(tables: [UsageStats])
class UsageDao extends DatabaseAccessor<AppDatabase> with _$UsageDaoMixin {
  UsageDao(super.db);

  Future<UsageStat?> getUsageStat(int promptId, String packageName) =>
      (select(usageStats)
            ..where((t) => t.promptId.equals(promptId) & t.packageName.equals(packageName)))
          .getSingleOrNull();

  Future<List<UsageStat>> getStatsForPackage(String packageName) =>
      (select(usageStats)..where((t) => t.packageName.equals(packageName))).get();

  Future<List<UsageStat>> getAllStats() => select(usageStats).get();

  Future<void> recordUsage(int promptId, String packageName) async {
    final existing = await getUsageStat(promptId, packageName);
    if (existing == null) {
      await into(usageStats).insert(UsageStatsCompanion.insert(
        promptId: promptId,
        packageName: packageName,
        count: const Value(1),
        lastUsedAt: Value(DateTime.now()),
      ));
    } else {
      await (update(usageStats)
            ..where((t) => t.promptId.equals(promptId) & t.packageName.equals(packageName)))
          .write(UsageStatsCompanion(
        count: Value(existing.count + 1),
        lastUsedAt: Value(DateTime.now()),
      ));
    }
  }
}
```

- [ ] **Step 9: Create folder_dao.dart**

```dart
// lib/data/database/daos/folder_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/folders_table.dart';

part 'folder_dao.g.dart';

@DriftAccessor(tables: [Folders])
class FolderDao extends DatabaseAccessor<AppDatabase> with _$FolderDaoMixin {
  FolderDao(super.db);

  Future<List<Folder>> getAllFolders() => select(folders).get();
  Stream<List<Folder>> watchAllFolders() => select(folders).watch();

  Future<int> insertFolder(FoldersCompanion entry) => into(folders).insert(entry);

  Future<int> deleteFolder(int id) =>
      (delete(folders)..where((t) => t.id.equals(id))).go();
}
```

- [ ] **Step 10: Run code generation**

```bash
cd /Users/agrkushal/Documents/Promptezy/promptezy
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `app_database.g.dart`, `prompt_dao.g.dart`, `usage_dao.g.dart`, `folder_dao.g.dart`. No errors.

- [ ] **Step 11: Write database tests**

Create `test/data/database/app_database_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/database/tables/prompts_table.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and retrieve a prompt', () async {
    final id = await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'Test', body: 'Hello {{name}}'),
    );
    expect(id, greaterThan(0));

    final prompt = await db.promptDao.getPromptById(id);
    expect(prompt, isNotNull);
    expect(prompt!.title, 'Test');
    expect(prompt.body, 'Hello {{name}}');
    expect(prompt.pinned, false);
  });

  test('search prompts by title substring', () async {
    await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'Rewrite for professional tone', body: 'Rewrite this...'),
    );
    await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'Summarize', body: 'Summarize this text...'),
    );

    final results = await db.promptDao.searchPrompts('rewrite');
    expect(results.length, 1);
    expect(results.first.title, contains('Rewrite'));
  });

  test('record usage increments count', () async {
    final promptId = await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'T', body: 'B'),
    );

    await db.usageDao.recordUsage(promptId, 'com.anthropic.claude');
    await db.usageDao.recordUsage(promptId, 'com.anthropic.claude');

    final stat = await db.usageDao.getUsageStat(promptId, 'com.anthropic.claude');
    expect(stat!.count, 2);
  });

  test('delete prompt cascades usage stats', () async {
    final promptId = await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'T', body: 'B'),
    );
    await db.usageDao.recordUsage(promptId, 'com.openai.chatgpt');
    await db.promptDao.deletePrompt(promptId);

    final stat = await db.usageDao.getUsageStat(promptId, 'com.openai.chatgpt');
    expect(stat, isNull);
  });
}
```

- [ ] **Step 12: Run tests**

```bash
flutter test test/data/database/app_database_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 13: Commit**

```bash
git add -A
git commit -m "feat: drift database schema, DAOs, and tests"
```

---

## Task 4: Variable Detection & Repositories

**Files:**
- Create: `lib/services/variable_detector.dart`
- Create: `lib/data/repositories/prompt_repository.dart`
- Create: `lib/data/repositories/usage_repository.dart`

- [ ] **Step 1: Create variable_detector.dart**

```dart
// lib/services/variable_detector.dart

// Detects {{variable}} patterns in prompt body text.
// Rules: dedupe by name, malformed input is literal, no whitespace-only names.
abstract final class VariableDetector {
  static final _pattern = RegExp(r'\{\{([a-zA-Z][a-zA-Z0-9_]*)\}\}');

  // Returns deduplicated list of variable names in order of first appearance.
  static List<String> detect(String body) {
    final seen = <String>{};
    final result = <String>[];
    for (final match in _pattern.allMatches(body)) {
      final name = match.group(1)!;
      if (seen.add(name)) result.add(name);
    }
    return result;
  }

  // Returns the body with all {{name}} replaced by [values].
  // Variables not present in values are left as-is.
  static String substitute(String body, Map<String, String> values) {
    return body.replaceAllMapped(_pattern, (m) {
      final name = m.group(1)!;
      return values[name] ?? m.group(0)!;
    });
  }
}
```

- [ ] **Step 2: Write variable detector tests**

Create `test/services/variable_detector_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/variable_detector.dart';

void main() {
  group('VariableDetector.detect', () {
    test('detects single variable', () {
      expect(VariableDetector.detect('Hello {{name}}'), ['name']);
    });

    test('deduplicates repeated variables', () {
      expect(
        VariableDetector.detect('Rewrite in {{tone}} for {{audience}}, keep it {{tone}}'),
        ['tone', 'audience'],
      );
    });

    test('ignores malformed patterns', () {
      expect(VariableDetector.detect('{tone} {{}} {{1invalid}}'), []);
    });

    test('returns empty for no variables', () {
      expect(VariableDetector.detect('Just plain text.'), []);
    });

    test('preserves order of first appearance', () {
      expect(
        VariableDetector.detect('{{b}} {{a}} {{c}} {{b}}'),
        ['b', 'a', 'c'],
      );
    });
  });

  group('VariableDetector.substitute', () {
    test('replaces known variables', () {
      final result = VariableDetector.substitute(
        'Rewrite in {{tone}} for {{audience}}',
        {'tone': 'formal', 'audience': 'clients'},
      );
      expect(result, 'Rewrite in formal for clients');
    });

    test('leaves unknown variables unchanged', () {
      final result = VariableDetector.substitute(
        'Hello {{name}} from {{city}}',
        {'name': 'Alice'},
      );
      expect(result, 'Hello Alice from {{city}}');
    });

    test('replaces all occurrences of same variable', () {
      final result = VariableDetector.substitute(
        '{{tone}} and {{tone}}',
        {'tone': 'formal'},
      );
      expect(result, 'formal and formal');
    });
  });
}
```

- [ ] **Step 3: Run variable detector tests**

```bash
flutter test test/services/variable_detector_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Create prompt_repository.dart**

```dart
// lib/data/repositories/prompt_repository.dart
import '../database/app_database.dart';
import '../database/tables/prompts_table.dart';
import '../database/tables/variables_table.dart';
import '../../services/variable_detector.dart';
import 'package:drift/drift.dart';

class PromptRepository {
  PromptRepository(this._db);

  final AppDatabase _db;

  Future<List<Prompt>> getAll() => _db.promptDao.getAllPrompts();
  Stream<List<Prompt>> watchAll() => _db.promptDao.watchAllPrompts();
  Future<List<Prompt>> search(String query) => _db.promptDao.searchPrompts(query);
  Future<Prompt?> getById(int id) => _db.promptDao.getPromptById(id);

  Future<List<Variable>> getVariablesFor(int promptId) =>
      _db.promptDao.getVariablesForPrompt(promptId);

  // Inserts prompt and auto-detects + saves variables from body.
  Future<int> create({
    required String title,
    required String body,
    int? folderId,
    String modelTags = '',
    bool pinned = false,
    bool isStarter = false,
  }) async {
    final id = await _db.promptDao.insertPrompt(PromptsCompanion.insert(
      title: title,
      body: body,
      folderId: Value(folderId),
      modelTags: Value(modelTags),
      pinned: Value(pinned),
      isStarter: Value(isStarter),
    ));
    await _syncVariables(id, body);
    return id;
  }

  Future<void> update({
    required int id,
    required String title,
    required String body,
    int? folderId,
    String modelTags = '',
    bool pinned = false,
  }) async {
    await _db.promptDao.updatePrompt(PromptsCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      folderId: Value(folderId),
      modelTags: Value(modelTags),
      pinned: Value(pinned),
      updatedAt: Value(DateTime.now()),
    ));
    await _syncVariables(id, body);
  }

  Future<void> delete(int id) => _db.promptDao.deletePrompt(id);

  Future<void> togglePin(int id, bool pinned) async {
    await _db.promptDao.updatePrompt(PromptsCompanion(
      id: Value(id),
      pinned: Value(pinned),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _syncVariables(int promptId, String body) async {
    final names = VariableDetector.detect(body);
    final companions = names
        .map((n) => VariablesCompanion.insert(promptId: promptId, name: n))
        .toList();
    await _db.promptDao.replaceVariables(promptId, companions);
  }
}
```

- [ ] **Step 5: Create usage_repository.dart**

```dart
// lib/data/repositories/usage_repository.dart
import '../database/app_database.dart';
import '../database/tables/prompts_table.dart';

class UsageRepository {
  UsageRepository(this._db);

  final AppDatabase _db;

  Future<void> recordUsage(int promptId, String packageName) =>
      _db.usageDao.recordUsage(promptId, packageName);

  // Returns prompts sorted by app-aware score for the given calling package.
  // Score = (app-specific count * 3) + (global count * 1) + recency bonus (0-2).
  // Pinned prompts always lead the list.
  Future<List<Prompt>> getRankedPrompts(String callingPackage) async {
    final allPrompts = await _db.promptDao.getAllPrompts();
    final appStats = await _db.usageDao.getStatsForPackage(callingPackage);
    final allStats = await _db.usageDao.getAllStats();

    final appCountByPrompt = {for (final s in appStats) s.promptId: s.count};
    final globalCountByPrompt = <int, int>{};
    for (final s in allStats) {
      globalCountByPrompt[s.promptId] =
          (globalCountByPrompt[s.promptId] ?? 0) + s.count;
    }
    final lastUsedByPrompt = <int, DateTime>{};
    for (final s in allStats) {
      final existing = lastUsedByPrompt[s.promptId];
      if (existing == null || s.lastUsedAt.isAfter(existing)) {
        lastUsedByPrompt[s.promptId] = s.lastUsedAt;
      }
    }

    final now = DateTime.now();

    double score(Prompt p) {
      final appCount = appCountByPrompt[p.id] ?? 0;
      final globalCount = globalCountByPrompt[p.id] ?? 0;
      final lastUsed = lastUsedByPrompt[p.id];
      double recency = 0;
      if (lastUsed != null) {
        final hoursSince = now.difference(lastUsed).inHours;
        recency = hoursSince < 24
            ? 2.0
            : hoursSince < 168
                ? 1.0
                : 0.0;
      }
      return (appCount * 3.0) + (globalCount * 1.0) + recency;
    }

    final pinned = allPrompts.where((p) => p.pinned).toList();
    final unpinned = allPrompts.where((p) => !p.pinned).toList()
      ..sort((a, b) => score(b).compareTo(score(a)));

    return [...pinned, ...unpinned];
  }
}
```

- [ ] **Step 6: Write ranking tests**

Create `test/data/repositories/usage_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/database/tables/prompts_table.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';
import 'package:loadstash/data/repositories/usage_repository.dart';

void main() {
  late AppDatabase db;
  late PromptRepository promptRepo;
  late UsageRepository usageRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    promptRepo = PromptRepository(db);
    usageRepo = UsageRepository(db);
  });

  tearDown(() async => db.close());

  test('app-specific usage ranks prompt higher', () async {
    final claudeId = await promptRepo.create(title: 'Claude prompt', body: 'XML structured...');
    final gptId = await promptRepo.create(title: 'GPT prompt', body: 'Direct and casual...');

    await usageRepo.recordUsage(claudeId, 'com.anthropic.claude');
    await usageRepo.recordUsage(claudeId, 'com.anthropic.claude');
    await usageRepo.recordUsage(gptId, 'com.openai.chatgpt');
    await usageRepo.recordUsage(gptId, 'com.openai.chatgpt');

    final ranked = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(ranked.first.id, claudeId);
  });

  test('pinned prompts always lead', () async {
    final normalId = await promptRepo.create(title: 'Normal', body: 'Text');
    final pinnedId = await promptRepo.create(title: 'Pinned', body: 'Text', pinned: true);

    // Give the unpinned prompt lots of usage
    for (var i = 0; i < 10; i++) {
      await usageRepo.recordUsage(normalId, 'com.anthropic.claude');
    }

    final ranked = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(ranked.first.id, pinnedId);
  });

  test('no usage returns all prompts (pinned first)', () async {
    final a = await promptRepo.create(title: 'A', body: 'Text');
    final b = await promptRepo.create(title: 'B', body: 'Text', pinned: true);

    final ranked = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(ranked.length, 2);
    expect(ranked.first.id, b); // pinned first
  });
}
```

- [ ] **Step 7: Run tests**

```bash
flutter test test/data/repositories/usage_repository_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: variable detector service, prompt and usage repositories"
```

---

## Task 5: Riverpod Providers

**Files:**
- Create: `lib/providers/database_provider.dart`
- Create: `lib/providers/repository_providers.dart`
- Create: `lib/providers/prompt_provider.dart`
- Create: `lib/providers/overlay_provider.dart`

- [ ] **Step 1: Create database_provider.dart**

```dart
// lib/providers/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

- [ ] **Step 2: Create repository_providers.dart**

```dart
// lib/providers/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/prompt_repository.dart';
import '../data/repositories/usage_repository.dart';
import 'database_provider.dart';

final promptRepositoryProvider = Provider<PromptRepository>((ref) {
  return PromptRepository(ref.watch(databaseProvider));
});

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return UsageRepository(ref.watch(databaseProvider));
});
```

- [ ] **Step 3: Create prompt_provider.dart**

```dart
// lib/providers/prompt_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/tables/prompts_table.dart';
import 'repository_providers.dart';

// All prompts as a stream (reactive to DB changes)
final promptsStreamProvider = StreamProvider<List<Prompt>>((ref) {
  return ref.watch(promptRepositoryProvider).watchAll();
});

// Search query string
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered prompts based on search query
final filteredPromptsProvider = FutureProvider<List<Prompt>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(promptRepositoryProvider);
  if (query.isEmpty) return repo.getAll();
  return repo.search(query);
});
```

- [ ] **Step 4: Create overlay_provider.dart**

```dart
// lib/providers/overlay_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/tables/prompts_table.dart';

// Data passed in from the Android PROCESS_TEXT intent
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

// The prompt chosen by the user in the overlay (before variables are filled)
final selectedPromptProvider = StateProvider<Prompt?>((ref) => null);

// Variable values being filled in (key: variable name, value: user input)
final variableValuesProvider = StateProvider<Map<String, String>>((ref) => {});

// Selected model filter chip (null = All)
final modelFilterProvider = StateProvider<String?>((ref) => null);
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: riverpod providers for database, prompts, overlay state"
```

---

## Task 6: Android Native Integration

**Files:**
- Create: `android/app/src/main/kotlin/com/example/promptezy/LoadstashApplication.kt`
- Create: `android/app/src/main/kotlin/com/example/promptezy/ProcessTextActivity.kt`
- Modify: `android/app/src/main/res/values/styles.xml`
- Modify: `android/app/src/main/res/values-night/styles.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Create LoadstashApplication.kt**

```kotlin
// android/app/src/main/kotlin/com/example/promptezy/LoadstashApplication.kt
package com.example.promptezy

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.app.FlutterApplication

// Pre-warms a Flutter engine for the overlay so cold-start is faster.
class LoadstashApplication : FlutterApplication() {
    companion object {
        const val OVERLAY_ENGINE_ID = "overlay_engine"
    }

    override fun onCreate() {
        super.onCreate()

        val engine = FlutterEngine(this)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        engine.navigationChannel.setInitialRoute("/overlay")
        FlutterEngineCache.getInstance().put(OVERLAY_ENGINE_ID, engine)
    }
}
```

- [ ] **Step 2: Create ProcessTextActivity.kt**

```kotlin
// android/app/src/main/kotlin/com/example/promptezy/ProcessTextActivity.kt
package com.example.promptezy

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class ProcessTextActivity : FlutterActivity() {
    private val channelName = "com.loadstash/overlay"

    override fun getCachedEngineId(): String = LoadstashApplication.OVERLAY_ENGINE_ID

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getIntentData" -> {
                        val text = intent
                            .getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
                            ?.toString() ?: ""
                        val readOnly = intent
                            .getBooleanExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, false)
                        val pkg = callingPackage ?: ""
                        result.success(
                            mapOf(
                                "selectedText" to text,
                                "isReadOnly" to readOnly,
                                "callingPackage" to pkg,
                            )
                        )
                    }
                    "setResult" -> {
                        val text = call.argument<String>("text") ?: ""
                        val resultIntent = Intent().apply {
                            putExtra(Intent.EXTRA_PROCESS_TEXT, text)
                        }
                        setResult(RESULT_OK, resultIntent)
                        finish()
                        result.success(null)
                    }
                    "cancel" -> {
                        setResult(RESULT_CANCELED)
                        finish()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

- [ ] **Step 3: Update styles.xml (light)**

Replace `android/app/src/main/res/values/styles.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
    <!-- Transparent theme for the overlay activity -->
    <style name="TransparentTheme" parent="@android:style/Theme.Translucent.NoTitleBar">
        <item name="android:windowBackground">@android:color/transparent</item>
        <item name="android:colorBackgroundCacheHint">@null</item>
        <item name="android:windowIsTranslucent">true</item>
        <item name="android:windowAnimationStyle">@null</item>
    </style>
</resources>
```

- [ ] **Step 4: Update styles.xml (night)**

Read the existing night styles first, then update `android/app/src/main/res/values-night/styles.xml` to also add `TransparentTheme` (same content as above — it's transparent in both modes).

- [ ] **Step 5: Update AndroidManifest.xml**

Replace `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:name=".LoadstashApplication"
        android:label="loadstash"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity
            android:name=".ProcessTextActivity"
            android:exported="true"
            android:theme="@style/TransparentTheme"
            android:label="loadstash"
            android:taskAffinity=""
            android:excludeFromRecents="true">
            <intent-filter>
                <action android:name="android.intent.action.PROCESS_TEXT" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="text/plain" />
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>
</manifest>
```

- [ ] **Step 6: Build Android to verify no compile errors**

```bash
flutter build apk --debug
```

Expected: builds successfully. No Kotlin compile errors.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: Android ProcessTextActivity with cached FlutterEngine"
```

---

## Task 7: Process Text Channel (Flutter Side)

**Files:**
- Create: `lib/services/process_text_channel.dart`
- Create: `test/services/process_text_channel_test.dart`

- [ ] **Step 1: Create process_text_channel.dart**

```dart
// lib/services/process_text_channel.dart
import 'package:flutter/services.dart';
import '../providers/overlay_provider.dart';

class ProcessTextChannel {
  static const _channel = MethodChannel('com.loadstash/overlay');

  // Fetches the selected text + calling package from the Android intent.
  // Returns null if the channel call fails (e.g. not launched via PROCESS_TEXT).
  static Future<OverlayIntentData?> getIntentData() async {
    try {
      final data = await _channel.invokeMapMethod<String, dynamic>('getIntentData');
      if (data == null) return null;
      return OverlayIntentData(
        selectedText: data['selectedText'] as String? ?? '',
        isReadOnly: data['isReadOnly'] as bool? ?? false,
        callingPackage: data['callingPackage'] as String? ?? '',
      );
    } on PlatformException {
      return null;
    }
  }

  // Sends the assembled prompt text back to Android to insert into the text field.
  static Future<void> setResult(String text) async {
    await _channel.invokeMethod('setResult', {'text': text});
  }

  // Cancels the overlay without inserting text.
  static Future<void> cancel() async {
    await _channel.invokeMethod('cancel');
  }
}
```

- [ ] **Step 2: Write channel tests**

Create `test/services/process_text_channel_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/process_text_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.loadstash/overlay');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getIntentData':
          return {
            'selectedText': 'selected text here',
            'isReadOnly': false,
            'callingPackage': 'com.anthropic.claude',
          };
        case 'setResult':
        case 'cancel':
          return null;
        default:
          throw PlatformException(code: 'NOT_IMPL');
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getIntentData returns OverlayIntentData', () async {
    final data = await ProcessTextChannel.getIntentData();
    expect(data, isNotNull);
    expect(data!.selectedText, 'selected text here');
    expect(data.isReadOnly, false);
    expect(data.callingPackage, 'com.anthropic.claude');
  });

  test('getIntentData returns null on PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'ERROR');
    });
    final data = await ProcessTextChannel.getIntentData();
    expect(data, isNull);
  });

  test('setResult sends text over channel', () async {
    expect(() => ProcessTextChannel.setResult('Final prompt text'), completes);
  });
}
```

- [ ] **Step 3: Run tests**

```bash
flutter test test/services/process_text_channel_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 4: Update main.dart to handle overlay route**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/overlay/overlay_screen.dart';

void main() {
  runApp(const ProviderScope(child: LoadstashApp()));
}

// Overlay entry point — called when route is "/overlay"
@pragma('vm:entry-point')
void overlayMain() {
  runApp(const ProviderScope(child: MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayScreen(),
  )));
}
```

Actually, the cleaner v1 approach is to use go_router with the `/overlay` route in the same app rather than a separate entry point. Update main.dart to stay as a single entry:

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: LoadstashApp()));
}
```

The `/overlay` route will be handled in go_router in app.dart (Task 8).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: ProcessTextChannel Flutter wrapper with mock tests"
```

---

## Task 8: App Shell, Routing & Overlay Screen

**Files:**
- Modify: `lib/app.dart`
- Create: `lib/features/overlay/overlay_screen.dart`
- Create: `lib/features/overlay/widgets/overlay_search_bar.dart`
- Create: `lib/features/overlay/widgets/overlay_prompt_list.dart`
- Create: `lib/features/overlay/widgets/overlay_prompt_row.dart`
- Create: `lib/features/overlay/widgets/variable_fill_sheet.dart`
- Create: `lib/features/overlay/widgets/variable_pill.dart`

- [ ] **Step 1: Update app.dart with go_router**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/library/library_screen.dart';
import 'features/overlay/overlay_screen.dart';
import 'features/editor/editor_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/overlay', builder: (_, __) => const OverlayScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const LibraryScreen()),
        GoRoute(
          path: '/editor',
          builder: (_, state) => EditorScreen(promptId: state.extra as int?),
        ),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);

class LoadstashApp extends ConsumerWidget {
  const LoadstashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'loadstash',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final _tabs = const [
    (path: '/', icon: Icons.grid_view_rounded, label: 'Library'),
    (path: '/settings', icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          context.go(_tabs[i].path);
        },
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
```

- [ ] **Step 2: Create placeholder screens to unblock compilation**

Create `lib/features/library/library_screen.dart`:
```dart
import 'package:flutter/material.dart';
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Library')));
}
```

Create `lib/features/editor/editor_screen.dart`:
```dart
import 'package:flutter/material.dart';
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key, this.promptId});
  final int? promptId;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Editor')));
}
```

Create `lib/features/settings/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Settings')));
}
```

Create `lib/features/onboarding/onboarding_screen.dart`:
```dart
import 'package:flutter/material.dart';
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Onboarding')));
}
```

- [ ] **Step 3: Create variable_pill.dart**

```dart
// lib/features/overlay/widgets/variable_pill.dart
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
        style: AppTypography.monoSmall.copyWith(
          color: AppColors.accent,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create overlay_search_bar.dart**

```dart
// lib/features/overlay/widgets/overlay_search_bar.dart
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
      onChanged: widget.onChanged,
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
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
```

- [ ] **Step 5: Create overlay_prompt_row.dart**

```dart
// lib/features/overlay/widgets/overlay_prompt_row.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/tables/prompts_table.dart';

class OverlayPromptRow extends StatelessWidget {
  const OverlayPromptRow({super.key, required this.prompt, required this.onTap});
  final Prompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          children: [
            if (prompt.pinned) ...[
              const Icon(Icons.push_pin, size: 14, color: AppColors.accent),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prompt.title, style: AppTypography.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (prompt.body.isNotEmpty)
                    Text(
                      prompt.body,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            _ModelDots(modelTags: prompt.modelTags),
          ],
        ),
      ),
    );
  }
}

class _ModelDots extends StatelessWidget {
  const _ModelDots({required this.modelTags});
  final String modelTags;

  @override
  Widget build(BuildContext context) {
    if (modelTags.isEmpty) return const SizedBox.shrink();
    final tags = modelTags.split(',').where((t) => t.isNotEmpty);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tags.map((tag) => _dot(tag.trim())).toList(),
    );
  }

  Widget _dot(String tag) {
    final color = switch (tag) {
      'claude' => AppColors.modelClaude,
      'chatgpt' => AppColors.modelChatGpt,
      'gemini' => AppColors.modelGemini,
      _ => AppColors.modelLocal,
    };
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
```

- [ ] **Step 6: Create variable_fill_sheet.dart**

```dart
// lib/features/overlay/widgets/variable_fill_sheet.dart
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
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fill in variables', style: AppTypography.screenTitle),
          const SizedBox(height: 16),
          // Preview line
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
          // One field per variable
          ...widget.variableNames.map((name) => Padding(
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
              )),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _onInsert,
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Create overlay_screen.dart**

```dart
// lib/features/overlay/overlay_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/tables/prompts_table.dart';
import '../../providers/overlay_provider.dart';
import '../../providers/repository_providers.dart';
import '../../services/process_text_channel.dart';
import '../../services/variable_detector.dart';
import 'widgets/overlay_search_bar.dart';
import 'widgets/overlay_prompt_row.dart';
import 'widgets/variable_fill_sheet.dart';

class OverlayScreen extends ConsumerStatefulWidget {
  const OverlayScreen({super.key});

  @override
  ConsumerState<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends ConsumerState<OverlayScreen> {
  String _query = '';
  List<Prompt> _prompts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Get intent data from Android
    final intentData = await ProcessTextChannel.getIntentData();
    if (intentData != null && mounted) {
      ref.read(overlayIntentProvider.notifier).state = intentData;
    }

    // Load ranked prompts
    final callingPkg = intentData?.callingPackage ?? '';
    final ranked = await ref.read(usageRepositoryProvider).getRankedPrompts(callingPkg);
    if (mounted) setState(() { _prompts = ranked; _loading = false; });
  }

  Future<void> _onPromptTapped(Prompt prompt) async {
    final vars = VariableDetector.detect(prompt.body);

    if (vars.isEmpty) {
      await _insertAndClose(prompt.body, prompt.id);
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (_) => VariableFillSheet(
          promptBody: prompt.body,
          variableNames: vars,
          onInsert: (assembled) async {
            Navigator.of(context).pop();
            await _insertAndClose(assembled, prompt.id);
          },
        ),
      );
    }
  }

  Future<void> _insertAndClose(String text, int promptId) async {
    final intentData = ref.read(overlayIntentProvider);
    if (intentData != null) {
      await ref.read(usageRepositoryProvider).recordUsage(
        promptId, intentData.callingPackage,
      );
    }
    await ProcessTextChannel.setResult(text);
  }

  List<Prompt> get _filtered {
    if (_query.isEmpty) return _prompts;
    final q = _query.toLowerCase();
    return _prompts
        .where((p) => p.title.toLowerCase().contains(q) || p.body.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dimmed scrim — tap to cancel
            GestureDetector(
              onTap: () => ProcessTextChannel.cancel(),
              child: Container(color: Colors.black54),
            ),
            // Bottom sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: OverlaySearchBar(onChanged: (q) => setState(() => _query = q)),
                    ),
                    if (_loading)
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Run flutter build to verify no compile errors**

```bash
flutter build apk --debug
```

Expected: compiles. No Dart errors.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: overlay screen with search, prompt list, variable fill-in"
```

---

## Task 9: Library Screen

**Files:**
- Modify: `lib/features/library/library_screen.dart`
- Create: `lib/features/library/widgets/prompt_card.dart`
- Create: `lib/features/library/widgets/prompt_list_section.dart`

- [ ] **Step 1: Create prompt_card.dart**

```dart
// lib/features/library/widgets/prompt_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/tables/prompts_table.dart';
import '../../../providers/repository_providers.dart';

class PromptCard extends ConsumerWidget {
  const PromptCard({
    super.key,
    required this.prompt,
    required this.onTap,
    this.onEdit,
  });

  final Prompt prompt;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (prompt.pinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.push_pin, size: 14, color: AppColors.accent),
                  ),
                Expanded(
                  child: Text(prompt.title, style: AppTypography.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: Icon(
                    prompt.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 18,
                    color: prompt.pinned ? AppColors.accent : AppColors.textTertiary,
                  ),
                  onPressed: () {
                    ref.read(promptRepositoryProvider).togglePin(prompt.id, !prompt.pinned);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textTertiary),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              prompt.body,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create prompt_list_section.dart**

```dart
// lib/features/library/widgets/prompt_list_section.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/tables/prompts_table.dart';
import 'prompt_card.dart';

class PromptListSection extends StatelessWidget {
  const PromptListSection({
    super.key,
    required this.title,
    required this.prompts,
    required this.onPromptTap,
    this.onPromptEdit,
  });

  final String title;
  final List<Prompt> prompts;
  final ValueChanged<Prompt> onPromptTap;
  final ValueChanged<Prompt>? onPromptEdit;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Text(title, style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          )),
        ),
        ...prompts.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PromptCard(
            prompt: p,
            onTap: () => onPromptTap(p),
            onEdit: onPromptEdit != null ? () => onPromptEdit!(p) : null,
          ),
        )),
      ],
    );
  }
}
```

- [ ] **Step 3: Build library_screen.dart**

```dart
// lib/features/library/library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/tables/prompts_table.dart';
import '../../providers/prompt_provider.dart';
import 'widgets/prompt_list_section.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final promptsAsync = _query.isEmpty
        ? ref.watch(promptsStreamProvider)
        : ref.watch(filteredPromptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('loadstash', style: AppTypography.screenTitle),
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => context.push('/editor'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (q) {
                setState(() => _query = q);
                ref.read(searchQueryProvider.notifier).state = q;
              },
              decoration: const InputDecoration(
                hintText: 'Search your library…',
                prefixIcon: Icon(Icons.search, color: AppColors.textTertiary, size: 20),
              ),
            ),
          ),
          Expanded(
            child: promptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(child: Text('Error: $e', style: AppTypography.bodySmall)),
              data: (prompts) {
                final mine = prompts.where((p) => !p.isStarter).toList();
                final starter = prompts.where((p) => p.isStarter).toList();

                if (prompts.isEmpty) {
                  return const Center(
                    child: Text('No prompts yet.\nTap + to create your first.', textAlign: TextAlign.center),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    PromptListSection(
                      title: 'YOUR PROMPTS',
                      prompts: mine,
                      onPromptTap: (p) => context.push('/editor', extra: p.id),
                      onPromptEdit: (p) => context.push('/editor', extra: p.id),
                    ),
                    PromptListSection(
                      title: 'STARTER LIBRARY',
                      prompts: starter,
                      onPromptTap: (p) => context.push('/editor', extra: p.id),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run app and verify library screen renders**

```bash
flutter run --debug
```

Expected: dark library screen with "loadstash" title, search bar, "+" button, empty state message.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: library screen with search, sections, pin toggle"
```

---

## Task 10: Prompt Editor Screen

**Files:**
- Modify: `lib/features/editor/editor_screen.dart`
- Create: `lib/features/editor/widgets/variable_preview.dart`

- [ ] **Step 1: Create variable_preview.dart**

```dart
// lib/features/editor/widgets/variable_preview.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// Shows the prompt body with {{variables}} highlighted as accent pills.
class VariablePreview extends StatelessWidget {
  const VariablePreview({super.key, required this.body, required this.variableNames});
  final String body;
  final List<String> variableNames;

  @override
  Widget build(BuildContext context) {
    if (variableNames.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Text(body.isEmpty ? 'Preview appears here…' : body,
            style: AppTypography.monoSmall.copyWith(color: AppColors.textTertiary)),
      );
    }

    // Build rich text with variable spans highlighted
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
          child: Text(m.group(0)!, style: AppTypography.monoSmall.copyWith(color: AppColors.accent)),
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
```

- [ ] **Step 2: Build editor_screen.dart**

```dart
// lib/features/editor/editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/tables/prompts_table.dart';
import '../../providers/repository_providers.dart';
import '../../services/variable_detector.dart';
import 'widgets/variable_preview.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.promptId});
  final int? promptId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _pinned = false;
  String _modelTags = '';
  List<String> _detectedVars = [];
  bool _loading = true;
  Prompt? _existing;

  @override
  void initState() {
    super.initState();
    _bodyCtrl.addListener(_onBodyChanged);
    _load();
  }

  Future<void> _load() async {
    if (widget.promptId != null) {
      final p = await ref.read(promptRepositoryProvider).getById(widget.promptId!);
      if (p != null && mounted) {
        setState(() {
          _existing = p;
          _titleCtrl.text = p.title;
          _bodyCtrl.text = p.body;
          _pinned = p.pinned;
          _modelTags = p.modelTags;
          _detectedVars = VariableDetector.detect(p.body);
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onBodyChanged() {
    setState(() {
      _detectedVars = VariableDetector.detect(_bodyCtrl.text);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final repo = ref.read(promptRepositoryProvider);
    if (_existing != null) {
      await repo.update(
        id: _existing!.id,
        title: title,
        body: body,
        pinned: _pinned,
        modelTags: _modelTags,
      );
    } else {
      await repo.create(title: title, body: body, pinned: _pinned, modelTags: _modelTags);
    }

    if (mounted) {
      // Show detected variable confirmation
      if (_detectedVars.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detected ${_detectedVars.length} variable(s): ${_detectedVars.join(', ')}')),
        );
      }
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (_existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Delete prompt?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(promptRepositoryProvider).delete(_existing!.id);
      context.pop();
    }
  }

  static const _modelOptions = ['claude', 'chatgpt', 'gemini', 'local', 'image'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.removeListener(_onBodyChanged);
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New prompt' : 'Edit prompt', style: AppTypography.label),
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        actions: [
          if (_existing != null)
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            style: AppTypography.label,
            decoration: const InputDecoration(hintText: 'Title', labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            style: AppTypography.mono.copyWith(fontSize: 14),
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Prompt body — use {{variable}} for fill-in fields',
              labelText: 'Body',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          // Live variable preview
          if (_bodyCtrl.text.isNotEmpty) ...[
            Text('Preview', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 6),
            VariablePreview(body: _bodyCtrl.text, variableNames: _detectedVars),
            const SizedBox(height: 16),
          ],
          // Model tags
          Text('Model tags', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _modelOptions.map((m) {
              final selected = _modelTags.split(',').contains(m);
              return FilterChip(
                label: Text(m),
                selected: selected,
                onSelected: (v) {
                  final tags = _modelTags.split(',').where((t) => t.isNotEmpty).toList();
                  v ? tags.add(m) : tags.remove(m);
                  setState(() => _modelTags = tags.join(','));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Pin toggle
          SwitchListTile(
            title: Text('Pinned', style: AppTypography.label),
            subtitle: Text('Always shows first in overlay', style: AppTypography.bodySmall),
            value: _pinned,
            onChanged: (v) => setState(() => _pinned = v),
            activeColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run and test editor manually**

```bash
flutter run --debug
```

Open Library → tap + → verify editor opens with title/body fields, model chips, pin toggle. Type `Hello {{name}}` in body → verify preview shows `{{name}}` with accent highlight.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: prompt editor with variable detection, preview, model tags"
```

---

## Task 11: Settings & Onboarding Screens

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Create: `lib/services/preferences_service.dart`
- Create: `lib/data/seeds/starter_prompts.dart`

- [ ] **Step 1: Create preferences_service.dart**

```dart
// lib/services/preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyStarterSeeded = 'starter_seeded';

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  static Future<bool> isStarterSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyStarterSeeded) ?? false;
  }

  static Future<void> markStarterSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStarterSeeded, true);
  }
}
```

- [ ] **Step 2: Create starter_prompts.dart**

```dart
// lib/data/seeds/starter_prompts.dart

// Each entry: {title, body, modelTags}
const List<Map<String, String>> kStarterPrompts = [
  {
    'title': 'Rewrite professionally',
    'body': 'Rewrite the following text in a clear, professional tone:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': 'Summarize concisely',
    'body': 'Summarize the following in 3 bullet points:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': 'Explain like I\'m 5',
    'body': 'Explain the following concept as if explaining to a 5-year-old:\n\n{{concept}}',
    'modelTags': '',
  },
  {
    'title': 'Fix grammar and spelling',
    'body': 'Fix any grammar, spelling, and punctuation errors in the following text. Return only the corrected text:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': 'Make it shorter',
    'body': 'Rewrite the following to be 50% shorter while keeping the key points:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': 'Translate to {{language}}',
    'body': 'Translate the following text to {{language}}:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': 'Write an email',
    'body': 'Write a professional email about: {{topic}}\n\nTone: {{tone}}\nRecipient: {{recipient}}',
    'modelTags': '',
  },
  {
    'title': 'Code review',
    'body': 'Review the following code for bugs, edge cases, and improvements:\n\n```\n{{code}}\n```\n\nLanguage: {{language}}',
    'modelTags': 'claude,chatgpt',
  },
  {
    'title': 'Explain this code',
    'body': 'Explain what this code does step by step:\n\n```\n{{code}}\n```',
    'modelTags': 'claude,chatgpt',
  },
  {
    'title': 'Write unit tests',
    'body': 'Write comprehensive unit tests for the following code. Cover happy path, edge cases, and error paths:\n\n```{{language}}\n{{code}}\n```',
    'modelTags': 'claude,chatgpt',
  },
  {
    'title': 'Debug this error',
    'body': 'I\'m getting this error:\n\n{{error}}\n\nHere is the relevant code:\n\n```\n{{code}}\n```\n\nWhat is causing it and how do I fix it?',
    'modelTags': 'claude,chatgpt',
  },
  {
    'title': 'Midjourney portrait',
    'body': 'portrait of {{subject}}, {{style}} style, dramatic lighting, highly detailed, 8k, cinematic, professional photography --ar 2:3 --q 2',
    'modelTags': 'image',
  },
  {
    'title': 'Midjourney landscape',
    'body': '{{scene}}, golden hour, {{mood}} atmosphere, hyperrealistic, landscape photography, award winning, 8k --ar 16:9 --q 2',
    'modelTags': 'image',
  },
  {
    'title': 'Brainstorm ideas',
    'body': 'Generate 10 creative ideas for: {{topic}}\n\nConstraints: {{constraints}}\nTarget audience: {{audience}}',
    'modelTags': '',
  },
  {
    'title': 'Claude XML structured prompt',
    'body': '<role>\n{{role}}\n</role>\n\n<task>\n{{task}}\n</task>\n\n<format>\n{{format}}\n</format>',
    'modelTags': 'claude',
  },
  {
    'title': 'Study flashcard',
    'body': 'Create 5 flashcard-style Q&A pairs to help me study:\n\n{{topic}}',
    'modelTags': '',
  },
  {
    'title': 'Pros and cons',
    'body': 'List the pros and cons of:\n\n{{decision}}\n\nContext: {{context}}',
    'modelTags': '',
  },
  {
    'title': 'Improve this prompt',
    'body': 'Improve the following AI prompt to be more effective, specific, and likely to produce better results:\n\n{{prompt}}',
    'modelTags': '',
  },
  {
    'title': 'Write a LinkedIn post',
    'body': 'Write a LinkedIn post about: {{topic}}\n\nTone: professional but approachable\nLength: 150-200 words\nInclude: a hook, insight, and call to action',
    'modelTags': '',
  },
  {
    'title': 'Meeting agenda',
    'body': 'Create a structured meeting agenda for:\n\nMeeting purpose: {{purpose}}\nDuration: {{duration}}\nAttendees: {{attendees}}',
    'modelTags': '',
  },
];
```

- [ ] **Step 3: Build onboarding_screen.dart**

```dart
// lib/features/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/seeds/starter_prompts.dart';
import '../../providers/repository_providers.dart';
import '../../services/preferences_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _seeding = true);

    final alreadySeeded = await PreferencesService.isStarterSeeded();
    if (!alreadySeeded) {
      final repo = ref.read(promptRepositoryProvider);
      for (final p in kStarterPrompts) {
        await repo.create(
          title: p['title']!,
          body: p['body']!,
          modelTags: p['modelTags']!,
          isStarter: true,
        );
      }
      await PreferencesService.markStarterSeeded();
    }

    await PreferencesService.markOnboardingDone();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('loadstash', style: AppTypography.screenTitle.copyWith(
                fontSize: 32, color: AppColors.accent,
              )),
              const SizedBox(height: 12),
              Text(
                'Your prompts, ready in any app.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),

              // Gesture illustration (animated)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('How to use', style: AppTypography.label),
                    const SizedBox(height: 24),
                    SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Text('loadstash', style: AppTypography.label.copyWith(color: AppColors.accent)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '1. Select text in any app\n2. Tap loadstash in the menu\n3. Pick a prompt → it\'s inserted',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              _seeding
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : FilledButton(
                      onPressed: _finish,
                      child: const Text('Get started'),
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire onboarding check into app.dart**

In `app.dart`, update the router `redirect` to check onboarding:

```dart
final _router = GoRouter(
  redirect: (context, state) async {
    final done = await PreferencesService.isOnboardingDone();
    if (!done && state.matchedLocation != '/overlay') return '/onboarding';
    return null;
  },
  routes: [ /* existing routes */ ],
);
```

Add the import: `import 'services/preferences_service.dart';`

- [ ] **Step 5: Build settings_screen.dart**

```dart
// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.screenTitle),
        backgroundColor: AppColors.bgBase,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Privacy'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Text(
              'All your prompts and usage data are stored locally on your device. '
              'Nothing is sent to any server. Your browsing habits and prompt choices never leave your phone.',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          _section('About'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('loadstash', style: AppTypography.label),
                const SizedBox(height: 4),
                Text('v1.0.0 · Local-first prompt library', style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title.toUpperCase(),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary, letterSpacing: 0.5, fontWeight: FontWeight.w600,
            )),
      );
}
```

- [ ] **Step 6: Run full app and test onboarding → library flow**

```bash
flutter run --debug
```

Expected: onboarding screen shows on first run. Tap "Get started" → seeds 20 starter prompts → navigates to Library → starter prompts visible in "STARTER LIBRARY" section.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: onboarding, settings, starter library seeding, preferences"
```

---

## Task 12: End-to-End Integration Test

**Files:**
- Create: `test/integration/overlay_flow_test.dart`

- [ ] **Step 1: Write integration test**

Create `test/integration/overlay_flow_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';
import 'package:loadstash/data/repositories/usage_repository.dart';
import 'package:loadstash/services/variable_detector.dart';

// Tests the core overlay user journey end-to-end (without Flutter UI):
// create prompt → rank → detect vars → substitute → record usage → re-rank

void main() {
  late AppDatabase db;
  late PromptRepository promptRepo;
  late UsageRepository usageRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    promptRepo = PromptRepository(db);
    usageRepo = UsageRepository(db);
  });

  tearDown(() async => db.close());

  test('full overlay flow: create, rank, fill vars, record usage', () async {
    // 1. Create a prompt with variables
    final id = await promptRepo.create(
      title: 'Rewrite in {{tone}} for {{audience}}',
      body: 'Rewrite the following in {{tone}} for {{audience}}:\n\n{{text}}',
    );

    // 2. Verify variables were auto-detected
    final vars = await promptRepo.getVariablesFor(id);
    expect(vars.map((v) => v.name).toList(), ['tone', 'audience', 'text']);

    // 3. Initial ranking — prompt should appear (no usage yet)
    final initial = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(initial.any((p) => p.id == id), true);

    // 4. Simulate overlay: detect vars, substitute values
    final prompt = await promptRepo.getById(id);
    final detectedVars = VariableDetector.detect(prompt!.body);
    expect(detectedVars, ['tone', 'audience', 'text']);

    final assembled = VariableDetector.substitute(prompt.body, {
      'tone': 'formal',
      'audience': 'executives',
      'text': 'We missed our Q3 targets.',
    });
    expect(assembled, contains('formal'));
    expect(assembled, contains('executives'));
    expect(assembled, isNot(contains('{{tone}}')));

    // 5. Record usage
    await usageRepo.recordUsage(id, 'com.anthropic.claude');
    await usageRepo.recordUsage(id, 'com.anthropic.claude');

    // 6. Re-rank — should now score higher for Claude
    final reRanked = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(reRanked.first.id, id);
  });
}
```

- [ ] **Step 2: Run integration test**

```bash
flutter test test/integration/overlay_flow_test.dart
```

Expected: 1 test passes.

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Final build verification**

```bash
flutter build apk --debug
```

Expected: APK builds successfully.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: end-to-end overlay flow integration test, v1 complete"
```

---

## Self-Review: Spec Coverage Check

| Spec requirement | Task |
|---|---|
| ACTION_PROCESS_TEXT intent filter | Task 6 |
| Translucent activity (transparent theme) | Task 6 |
| Selected text passed to Flutter | Task 6, 7 |
| Result returned to Android | Task 6, 7 |
| Overlay bottom sheet UI | Task 8 |
| Search bar autofocused | Task 8 |
| Recents/most-used ranking | Task 4, 5 |
| Pinned prompts always lead | Task 4, 5 |
| Model filter chips | Task 8 (overlay_prompt_row model dots — chips deferred, UI shows dots) |
| Variable fill-in sheet | Task 8 |
| `{{variable}}` highlight in preview | Task 10 |
| Dedupe variables | Task 4 |
| Malformed variables are literal | Task 4 |
| Save selection as prompt | Not in scope — overlay captures via standard PROCESS_TEXT flow |
| Library screen (home) | Task 9 |
| Prompt editor | Task 10 |
| Pin toggle | Task 9, 10 |
| Starter library | Task 11 |
| Onboarding (gesture + seed) | Task 11 |
| Settings + privacy statement | Task 11 |
| App-aware ranking (callingPackage) | Task 5 |
| Dark-first theme with exact color tokens | Task 2 |
| Inter + JetBrains Mono typography | Task 2 |
| Local storage, no network | Task 3 (drift SQLite) |
| Cold-start optimization (cached engine) | Task 6 |

**Gap:** Model filter chips in the overlay show as dots on rows, not interactive filter chips. Add after v1 if needed.
**Gap:** "Save selection as prompt" from overlay — the spec names this but it requires the overlay to have a create flow. Deferred: for v1, save via main app editor.
**Gap:** Folder/tag management screen — spec §4 mentions it. Deferred to post-v1 polish.
