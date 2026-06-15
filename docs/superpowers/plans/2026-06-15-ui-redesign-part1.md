# UI Redesign Part 1 — Colors, Animations, DB Migration, Repository
## Tasks 1–4

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task.

**Goal:** Update color tokens, create animation primitives, migrate DB schema (path replaces folderId, add searchTags), update PromptRepository for path-based folder queries.

**Architecture:** Drift schema v1→v2 adds `path TEXT` and `searchTags TEXT` to Prompts; folders are derived at runtime from prompt paths (no stored folder entities). Animation widgets live in `lib/core/animations/`.

**Tech Stack:** Flutter · Drift · dart:convert (JSON encode/decode for path arrays)

---

## File Structure

```
lib/core/theme/app_colors.dart                    MODIFY — add 4 tokens, update 4 model colors
lib/core/animations/animations.dart               CREATE — BobWidget, RingWidget, FadeUpWidget, BlinkingCursor, PopWidget, kSpring
lib/data/database/tables/prompts_table.dart        MODIFY — remove folderId, add path + searchTags
lib/data/database/app_database.dart               MODIFY — schemaVersion 1→2, onUpgrade migration
lib/data/database/daos/prompt_dao.dart            MODIFY — remove folderId references
lib/data/repositories/prompt_repository.dart      MODIFY — path/searchTags APIs, folder derivation
lib/data/seeds/starter_prompts.dart               MODIFY — add path/searchTags per prompt
test/data/database/app_database_test.dart         MODIFY — update for new schema
test/data/repositories/usage_repository_test.dart MODIFY — update create() calls
```

---

## Task 1: Color Tokens

**Files:**
- Modify: `lib/core/theme/app_colors.dart`

- [ ] **Step 1: Update app_colors.dart**

Replace the entire file:

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Dark palette
  static const bgBase = Color(0xFF0E0F12);
  static const surface1 = Color(0xFF16181D);
  static const surface2 = Color(0xFF1B1E24);
  static const borderHairline = Color(0x12FFFFFF);  // 7% white
  static const borderHairline2 = Color(0x0DFFFFFF); // 5% white — subtler
  static const textPrimary = Color(0xFFECEEF2);
  static const textSecondary = Color(0xFF9BA0AA);
  static const textTertiary = Color(0xFF686D78);
  static const accent = Color(0xFF8B7DF6);
  static const accentText = Color(0xFFB9AEFF);      // lighter accent for icons/text
  static const accentTint = Color(0x238B7DF6);      // 14% accent
  static const accentDim = Color(0x4D8B7DF6);       // 30% accent — active borders
  static const confirm = Color(0xFF5BC58F);
  static const confirmTint = Color(0x215BC58F);     // 13% success bg

  // Light palette
  static const bgBaseLight = Color(0xFFFAFAF8);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF1A1B1E);
  static const textTertiaryLight = Color(0xFFA0A0A0);
  static const borderLight = Color(0x14000000);
  static const accentLight = Color(0xFF6F5EE0);
  static const accentLightTint = Color(0x236F5EE0);

  // Model tag colors — actual brand colors
  static const modelClaude = Color(0xFFD97757);   // Anthropic orange
  static const modelChatGpt = Color(0xFF10A37F);  // OpenAI green
  static const modelGemini = Color(0xFF5B9CF6);   // Google blue
  static const modelLocal = Color(0xFF8A909C);    // neutral grey

  // Model color by key
  static Color forModel(String key) => switch (key) {
    'claude' => modelClaude,
    'chatgpt' => modelChatGpt,
    'gemini' => modelGemini,
    _ => modelLocal,
  };
}
```

- [ ] **Step 2: Run tests to verify no breakage**

```bash
cd /Users/agrkushal/Documents/Promptezy/promptezy
flutter test test/core/theme/app_theme_test.dart
```

Expected: 4 tests pass. (accentTint 0x23 is still the same value — test still valid.)

- [ ] **Step 3: Build**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat: add accentText/accentDim/borderHairline2/confirmTint, update model brand colors"
```

---

## Task 2: Animation Primitives

**Files:**
- Create: `lib/core/animations/animations.dart`

- [ ] **Step 1: Create the animations file**

```bash
mkdir -p lib/core/animations
```

Create `lib/core/animations/animations.dart`:

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Spring easing from the design — fast-out with gentle overshoot.
const kSpring = Cubic(0.16, 1.0, 0.3, 1.0);

/// Sheet/transition durations
const kSheetDuration = Duration(milliseconds: 360);
const kFadeUpDuration = Duration(milliseconds: 280);

// ─────────────────────────────────────────────────────────────
// BobWidget — gentle float ±amplitude dp, 3 s ease-in-out loop
// ─────────────────────────────────────────────────────────────
class BobWidget extends StatefulWidget {
  const BobWidget({
    super.key,
    required this.child,
    this.amplitude = 5.0,
    this.duration = const Duration(seconds: 3),
  });

  final Widget child;
  final double amplitude;
  final Duration duration;

  @override
  State<BobWidget> createState() => _BobWidgetState();
}

class _BobWidgetState extends State<BobWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final dy = -widget.amplitude *
            sin(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut).value *
                pi);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RingWidget — pulse ring scale 1→2.2, opacity 0.55→0, 2.6 s loop
// ─────────────────────────────────────────────────────────────
class RingWidget extends StatefulWidget {
  const RingWidget({
    super.key,
    required this.child,
    required this.color,
    this.size = 52.0,
    this.maxScale = 2.2,
  });

  final Widget child;
  final Color color;
  final double size;
  final double maxScale;

  @override
  State<RingWidget> createState() => _RingWidgetState();
}

class _RingWidgetState extends State<RingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _scale = Tween(begin: 1.0, end: widget.maxScale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.55), weight: 10),
      TweenSequenceItem(
          tween: Tween(begin: 0.55, end: 0.0), weight: 60),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
    ]).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(_opacity.value),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FadeUpWidget — fade in + slide up 9 dp, optional stagger delay
// ─────────────────────────────────────────────────────────────
class FadeUpWidget extends StatefulWidget {
  const FadeUpWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = kFadeUpDuration,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<FadeUpWidget> createState() => _FadeUpWidgetState();
}

class _FadeUpWidgetState extends State<FadeUpWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final curved =
        CurvedAnimation(parent: _ctrl, curve: kSpring);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(curved);
    _slide = Tween(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PopWidget — scale 0.6→1.06→1.0 + fade, spring easing
// ─────────────────────────────────────────────────────────────
class PopWidget extends StatefulWidget {
  const PopWidget({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<PopWidget> createState() => _PopWidgetState();
}

class _PopWidgetState extends State<PopWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _scale = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4)));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BlinkingCursor — 1.1 s step blink (550 ms on / 550 ms off)
// ─────────────────────────────────────────────────────────────
class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({
    super.key,
    this.color,
    this.width = 1.5,
    this.height = 18.0,
  });

  final Color? color;
  final double width;
  final double height;

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _ctrl.value < 0.5 ? 1.0 : 0.0,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color ?? AppColors.accent,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AnimatedDot — pill/circle for onboarding progress indicator
// ─────────────────────────────────────────────────────────────
class AnimatedDot extends StatelessWidget {
  const AnimatedDot({super.key, required this.active, required this.past});

  final bool active;
  final bool past;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: kSpring,
      width: active ? 20.0 : 7.0,
      height: 7.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? AppColors.accent
            : past
                ? AppColors.accentDim
                : const Color(0x1FFFFFFF),
      ),
    );
  }
}
```

- [ ] **Step 2: Build to verify compilation**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: Commit**

```bash
git add lib/core/animations/
git commit -m "feat: animation primitives — BobWidget, RingWidget, FadeUpWidget, PopWidget, BlinkingCursor, AnimatedDot"
```

---

## Task 3: DB Schema Migration

**Files:**
- Modify: `lib/data/database/tables/prompts_table.dart`
- Modify: `lib/data/database/app_database.dart`
- Modify: `lib/data/database/daos/prompt_dao.dart`
- Delete ref: remove `folders_table.dart` import from prompts_table

- [ ] **Step 1: Rewrite prompts_table.dart**

```dart
// lib/data/database/tables/prompts_table.dart
import 'package:drift/drift.dart';

class Prompts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get body => text()();
  // JSON-encoded List<String> e.g. '["Writing","Email"]'. Root = '[]'.
  TextColumn get path => text().withDefault(const Constant('[]'))();
  // JSON-encoded List<String> of user search tags e.g. '["work","sales"]'
  TextColumn get searchTags => text().withDefault(const Constant('[]'))();
  TextColumn get modelTags => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isStarter => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

Note: `folderId` is gone. The import of `folders_table.dart` is also removed.

- [ ] **Step 2: Update AppDatabase — schema v2 + migration**

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

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Prompts, PromptVariables, UsageStats, Folders, Tags, PromptTags],
  daos: [PromptDao, UsageDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(prompts, prompts.path);
            await m.addColumn(prompts, prompts.searchTags);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
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

Note: `FolderDao` removed from daos list (FolderDao file deleted next). `Folders`, `Tags`, `PromptTags` tables kept in list so they're still created/present in DB.

- [ ] **Step 3: Update prompt_dao.dart — remove folderId references**

Read `lib/data/database/daos/prompt_dao.dart`. The `insertPrompt` and `updatePrompt` calls currently pass `folderId`. Since `Prompts` table no longer has that column, the generated `PromptsCompanion` won't have it either after build_runner runs. No code changes needed in prompt_dao.dart itself — it uses `PromptsCompanion` which is auto-generated. The DAO is fine as-is.

- [ ] **Step 4: Delete folder_dao.dart**

```bash
rm lib/data/database/daos/folder_dao.dart
```

Also delete the generated file if it exists:
```bash
rm -f lib/data/database/daos/folder_dao.g.dart
```

- [ ] **Step 5: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -10
```

Expected: generates new `app_database.g.dart`, `prompt_dao.g.dart`. The `PromptsCompanion` now has `path` and `searchTags` fields instead of `folderId`.

If build_runner fails with a reference to `FolderDao` somewhere, grep and remove:
```bash
grep -r "FolderDao\|folder_dao\|FolderDao" lib/ --include="*.dart" -l
```

- [ ] **Step 6: Update test to use new schema**

In `test/data/database/app_database_test.dart`, update any `PromptsCompanion.insert()` calls that pass `folderId`. Remove `folderId:` parameter since it no longer exists:

```dart
// Before:
PromptsCompanion.insert(title: 'Test', body: 'Hello {{name}}')
// After: same — folderId was already optional/nullable, no change needed
// if any test passes folderId: Value(null), just remove that line
```

Run:
```bash
flutter test test/data/database/app_database_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: DB schema v2 — path + searchTags on prompts, remove folderId, drop FolderDao"
```

---

## Task 4: PromptRepository Update

**Files:**
- Modify: `lib/data/repositories/prompt_repository.dart`
- Modify: `lib/data/seeds/starter_prompts.dart`
- Modify: `lib/providers/repository_providers.dart` (remove usageRepositoryProvider if needed — no, keep it)
- Modify: `test/data/repositories/usage_repository_test.dart`

- [ ] **Step 1: Rewrite prompt_repository.dart**

```dart
// lib/data/repositories/prompt_repository.dart
import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/prompts_table.dart';
import '../../services/variable_detector.dart';

typedef FolderEntry = ({String name, int count});
typedef FolderContents = ({List<FolderEntry> folders, List<Prompt> prompts});

class PromptRepository {
  PromptRepository(this._db);

  final AppDatabase _db;

  // ── Basic CRUD ──────────────────────────────────────────────

  Future<List<Prompt>> getAll() => _db.promptDao.getAllPrompts();
  Stream<List<Prompt>> watchAll() => _db.promptDao.watchAllPrompts();
  Future<List<Prompt>> search(String query) => _db.promptDao.searchPrompts(query);
  Future<Prompt?> getById(int id) => _db.promptDao.getPromptById(id);
  Future<List<PromptVariable>> getVariablesFor(int promptId) =>
      _db.promptDao.getVariablesForPrompt(promptId);

  Future<int> create({
    required String title,
    required String body,
    List<String> path = const [],
    List<String> searchTags = const [],
    String modelTags = '',
    bool pinned = false,
    bool isStarter = false,
  }) async {
    final id = await _db.promptDao.insertPrompt(PromptsCompanion.insert(
      title: title,
      body: body,
      path: Value(encodePath(path)),
      searchTags: Value(encodePath(searchTags)),
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
    List<String> path = const [],
    List<String> searchTags = const [],
    String modelTags = '',
    bool pinned = false,
  }) async {
    await _db.promptDao.updatePrompt(PromptsCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      path: Value(encodePath(path)),
      searchTags: Value(encodePath(searchTags)),
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

  Future<void> moveTo(int id, List<String> newPath) async {
    await _db.promptDao.updatePrompt(PromptsCompanion(
      id: Value(id),
      path: Value(encodePath(newPath)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── Folder derivation ───────────────────────────────────────

  /// Returns subfolders and prompts directly at [currentPath].
  /// Folders are derived from all prompt paths — not stored entities.
  static FolderContents folderContentsAt(
      List<Prompt> allPrompts, List<String> currentPath) {
    final folderCounts = <String, int>{};
    final promptsHere = <Prompt>[];

    for (final p in allPrompts) {
      final pPath = decodePath(p.path);
      if (_pathEquals(pPath, currentPath)) {
        promptsHere.add(p);
      } else if (pPath.length > currentPath.length &&
          _pathStartsWith(pPath, currentPath)) {
        final next = pPath[currentPath.length];
        folderCounts[next] = (folderCounts[next] ?? 0) + 1;
      }
    }

    final folders = folderCounts.entries
        .map((e) => (name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return (folders: folders, prompts: promptsHere);
  }

  /// All unique folder paths across all prompts, for the folder picker.
  static List<List<String>> allFolderPaths(List<Prompt> allPrompts) {
    final seen = <String>{};
    final result = <List<String>>[[]]; // always include root
    for (final p in allPrompts) {
      final pPath = decodePath(p.path);
      for (var depth = 1; depth <= pPath.length; depth++) {
        final sub = pPath.sublist(0, depth);
        final key = sub.join('/');
        if (seen.add(key)) result.add(sub);
      }
    }
    return result;
  }

  // ── Encoding helpers ────────────────────────────────────────

  static List<String> decodePath(String json) {
    try {
      return List<String>.from(jsonDecode(json) as List);
    } catch (_) {
      return [];
    }
  }

  static String encodePath(List<String> path) => jsonEncode(path);

  static bool _pathEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _pathStartsWith(List<String> path, List<String> prefix) {
    if (path.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (path[i] != prefix[i]) return false;
    }
    return true;
  }

  Future<void> _syncVariables(int promptId, String body) async {
    final names = VariableDetector.detect(body);
    final companions = names
        .map((n) => PromptVariablesCompanion.insert(promptId: promptId, name: n))
        .toList();
    await _db.promptDao.replaceVariables(promptId, companions);
  }
}
```

- [ ] **Step 2: Update starter_prompts.dart with paths and searchTags**

Replace `lib/data/seeds/starter_prompts.dart`:

```dart
// lib/data/seeds/starter_prompts.dart
// Each entry: title, body, modelTags, path (List<String>), searchTags (List<String>)
const List<Map<String, dynamic>> kStarterPrompts = [
  {'title': 'Rewrite professionally', 'body': 'Rewrite the following text in a clear, professional tone:\n\n{{text}}', 'modelTags': '', 'path': ['Writing', 'Edit'], 'searchTags': ['writing']},
  {'title': 'Summarize concisely', 'body': 'Summarize the following in 3 bullet points:\n\n{{text}}', 'modelTags': '', 'path': ['Writing', 'Edit'], 'searchTags': ['writing']},
  {'title': "Explain like I'm 5", 'body': "Explain the following concept as if explaining to a 5-year-old:\n\n{{concept}}", 'modelTags': '', 'path': ['Learning', 'Explainers'], 'searchTags': ['learning']},
  {'title': 'Fix grammar and spelling', 'body': 'Fix any grammar, spelling, and punctuation errors in the following text. Return only the corrected text:\n\n{{text}}', 'modelTags': '', 'path': ['Writing', 'Edit'], 'searchTags': ['writing']},
  {'title': 'Make it shorter', 'body': 'Rewrite the following to be 50% shorter while keeping the key points:\n\n{{text}}', 'modelTags': '', 'path': ['Writing', 'Edit'], 'searchTags': ['writing']},
  {'title': 'Translate to {{language}}', 'body': 'Translate the following text to {{language}}:\n\n{{text}}', 'modelTags': '', 'path': ['Writing'], 'searchTags': ['writing']},
  {'title': 'Write an email', 'body': 'Write a professional email about: {{topic}}\n\nTone: {{tone}}\nRecipient: {{recipient}}', 'modelTags': '', 'path': ['Writing', 'Email'], 'searchTags': ['work', 'writing']},
  {'title': 'Cold outreach email', 'body': 'Write a cold email to {{name}} at {{company}} about {{product}}. Keep it under {{length}} words — friendly, specific, no fluff.', 'modelTags': 'claude,chatgpt', 'path': ['Writing', 'Email', 'Cold'], 'searchTags': ['work', 'sales']},
  {'title': 'Code review', 'body': 'Review the following code for bugs, edge cases, and improvements:\n\n```\n{{code}}\n```\n\nLanguage: {{language}}', 'modelTags': 'claude,chatgpt', 'path': ['Dev', 'Reviews'], 'searchTags': ['work', 'dev']},
  {'title': 'Explain this code', 'body': 'Explain what this code does step by step:\n\n```\n{{code}}\n```', 'modelTags': 'claude,chatgpt', 'path': ['Dev'], 'searchTags': ['dev']},
  {'title': 'Write unit tests', 'body': 'Write comprehensive unit tests for the following code. Cover happy path, edge cases, and error paths:\n\n```{{language}}\n{{code}}\n```', 'modelTags': 'claude,chatgpt', 'path': ['Dev'], 'searchTags': ['dev']},
  {'title': 'Debug this error', 'body': 'I\'m getting this error:\n\n{{error}}\n\nHere is the relevant code:\n\n```\n{{code}}\n```\n\nWhat is causing it and how do I fix it?', 'modelTags': 'claude,chatgpt', 'path': ['Dev'], 'searchTags': ['dev']},
  {'title': 'SQL from a question', 'body': 'Write a SQL query for: {{question}}. Use this schema: {{schema}}', 'modelTags': 'chatgpt,local', 'path': ['Dev', 'Data'], 'searchTags': ['dev', 'data']},
  {'title': 'Midjourney portrait', 'body': 'portrait of {{subject}}, {{style}} style, dramatic lighting, highly detailed, 8k, cinematic, professional photography --ar 2:3 --q 2', 'modelTags': 'local', 'path': ['Creative', 'Images'], 'searchTags': ['creative']},
  {'title': 'Midjourney landscape', 'body': '{{scene}}, golden hour, {{mood}} atmosphere, hyperrealistic, landscape photography, award winning, 8k --ar 16:9 --q 2', 'modelTags': 'local', 'path': ['Creative', 'Images'], 'searchTags': ['creative']},
  {'title': 'Claude XML structured prompt', 'body': '<role>\n{{role}}\n</role>\n\n<task>\n{{task}}\n</task>\n\n<format>\n{{format}}\n</format>', 'modelTags': 'claude', 'path': ['Dev'], 'searchTags': ['dev']},
  {'title': 'Brainstorm ideas', 'body': 'Generate 10 creative ideas for: {{topic}}\n\nConstraints: {{constraints}}\nTarget audience: {{audience}}', 'modelTags': '', 'path': ['Writing'], 'searchTags': ['creative']},
  {'title': 'Study flashcards', 'body': 'Create 5 flashcard-style Q&A pairs to help me study:\n\n{{topic}}', 'modelTags': '', 'path': ['Learning'], 'searchTags': ['learning']},
  {'title': 'Write a LinkedIn post', 'body': 'Write a LinkedIn post about: {{topic}}\n\nTone: professional but approachable\nLength: 150-200 words\nInclude: a hook, insight, and call to action', 'modelTags': '', 'path': ['Writing', 'Social'], 'searchTags': ['social', 'writing']},
  {'title': 'Meeting agenda', 'body': 'Create a structured meeting agenda for:\n\nMeeting purpose: {{purpose}}\nDuration: {{duration}}\nAttendees: {{attendees}}', 'modelTags': '', 'path': ['Work', 'Meetings'], 'searchTags': ['work']},
];
```

- [ ] **Step 3: Update onboarding_screen.dart seeding call**

In `lib/features/onboarding/onboarding_screen.dart`, find the seeding loop and update it to pass `path` and `searchTags`:

```dart
for (final p in kStarterPrompts) {
  await repo.create(
    title: p['title'] as String,
    body: p['body'] as String,
    modelTags: p['modelTags'] as String? ?? '',
    path: List<String>.from(p['path'] as List? ?? const []),
    searchTags: List<String>.from(p['searchTags'] as List? ?? const []),
    isStarter: true,
  );
}
```

- [ ] **Step 4: Fix any remaining callers of create() / update() that pass folderId**

Search for old API usage:
```bash
grep -rn "folderId" lib/ --include="*.dart"
```

For each file found, remove the `folderId:` parameter. The `path:` parameter defaults to `[]` so no replacement is needed for callers that don't care about folder placement.

- [ ] **Step 5: Write repository tests**

Update `test/data/repositories/usage_repository_test.dart` — the `create()` calls don't need `folderId` so they should work as-is. Run:

```bash
flutter test test/data/repositories/usage_repository_test.dart
```

Expected: 4 tests pass.

Also write a new test for folder derivation in `test/data/repositories/prompt_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';

void main() {
  late AppDatabase db;
  late PromptRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PromptRepository(db);
  });

  tearDown(() async => db.close());

  test('folderContentsAt returns correct subfolders and prompts', () async {
    await repo.create(title: 'A', body: 'B', path: ['Writing', 'Email']);
    await repo.create(title: 'C', body: 'D', path: ['Writing', 'Social']);
    await repo.create(title: 'E', body: 'F', path: ['Writing']);
    await repo.create(title: 'G', body: 'H', path: []); // root

    final all = await repo.getAll();

    final root = PromptRepository.folderContentsAt(all, []);
    expect(root.folders.map((f) => f.name).toList(), ['Writing']);
    expect(root.prompts.length, 1); // G is at root

    final writing = PromptRepository.folderContentsAt(all, ['Writing']);
    expect(writing.folders.map((f) => f.name).toList(), containsAll(['Email', 'Social']));
    expect(writing.prompts.length, 1); // E is at Writing
  });

  test('allFolderPaths includes root and all nested paths', () async {
    await repo.create(title: 'A', body: 'B', path: ['Writing', 'Email', 'Cold']);
    final all = await repo.getAll();
    final paths = PromptRepository.allFolderPaths(all);
    expect(paths, containsAll([
      [],
      ['Writing'],
      ['Writing', 'Email'],
      ['Writing', 'Email', 'Cold'],
    ]));
  });

  test('decodePath handles invalid JSON gracefully', () {
    expect(PromptRepository.decodePath(''), []);
    expect(PromptRepository.decodePath('not-json'), []);
    expect(PromptRepository.decodePath('["a","b"]'), ['a', 'b']);
  });
}
```

Run:
```bash
flutter test test/data/repositories/prompt_repository_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 6: Run full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Final build verification**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: PromptRepository path-based folder API, updated starter prompts with paths and tags"
```

---

## Self-Review

| Spec requirement | Task |
|---|---|
| 4 new color tokens (hair2, accentText, accentDim, confirmTint) | Task 1 |
| Updated model colors (brand-accurate) | Task 1 |
| `AppColors.forModel(key)` helper | Task 1 |
| `kSpring = Cubic(0.16,1,0.3,1)` | Task 2 |
| BobWidget, RingWidget, FadeUpWidget, PopWidget | Task 2 |
| BlinkingCursor, AnimatedDot | Task 2 |
| Prompts.path TEXT (JSON array) | Task 3 |
| Prompts.searchTags TEXT (JSON array) | Task 3 |
| Schema v1→v2 migration | Task 3 |
| folderId removed | Task 3 |
| FolderDao deleted | Task 3 |
| PromptRepository.create() with path/searchTags | Task 4 |
| folderContentsAt() — derive folders from prompt paths | Task 4 |
| allFolderPaths() — for folder picker | Task 4 |
| Starter prompts with real paths and searchTags | Task 4 |
