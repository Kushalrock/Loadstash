# UI Redesign Part 2 — Library, Prompt Detail, Editor
## Tasks 5–7

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Run AFTER Part 1 is complete.

**Goal:** Implement the library folder browser with pinned row, new prompt detail screen, and updated editor with folder picker and search tags.

**Architecture:** Library is path-based (List<String> managed in screen state, no route params). Prompt detail is a full screen pushed via go_router `/prompt`. Editor gets a bottom-sheet folder picker and inline tag management. All screens use design tokens from Part 1.

**Tech Stack:** Flutter · Riverpod · go_router · AppColors · animation primitives from Part 1

**Context:**
- `PromptRepository.folderContentsAt(allPrompts, path)` returns `({folders, prompts})`
- `PromptRepository.decodePath(json)` / `encodePath(list)` for path ↔ JSON
- `AppColors.forModel(key)` returns the brand color for a model key
- Animation widgets: `FadeUpWidget`, `AnimatedDot` from `lib/core/animations/animations.dart`
- `kSpring = Cubic(0.16, 1.0, 0.3, 1.0)` for all transitions

---

## File Structure

```
lib/features/library/
  library_screen.dart                    MODIFY (complete rewrite)
  widgets/pinned_row.dart                CREATE
  widgets/folder_row.dart                CREATE
  widgets/prompt_card.dart               MODIFY (redesigned card)
  widgets/new_folder_sheet.dart          CREATE
  widgets/folder_picker_sheet.dart       CREATE (shared folder picker)

lib/features/prompt_detail/
  prompt_detail_screen.dart              CREATE

lib/features/editor/
  editor_screen.dart                     MODIFY
  widgets/variable_preview.dart          KEEP (no changes needed)

lib/app.dart                             MODIFY (add /prompt route)
lib/providers/prompt_provider.dart       MODIFY (add watchAll stream)
```

---

## Task 5: Library Screen Redesign

**Files:**
- Create: `lib/features/library/widgets/pinned_row.dart`
- Create: `lib/features/library/widgets/folder_row.dart`
- Modify: `lib/features/library/widgets/prompt_card.dart`
- Create: `lib/features/library/widgets/folder_picker_sheet.dart`
- Create: `lib/features/library/widgets/new_folder_sheet.dart`
- Modify: `lib/features/library/library_screen.dart`

- [ ] **Step 1: Create pinned_row.dart**

```dart
// lib/features/library/widgets/pinned_row.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/prompt_repository.dart';

class PinnedRow extends StatelessWidget {
  const PinnedRow({super.key, required this.prompts, required this.onTap});

  final List<Prompt> prompts;
  final ValueChanged<Prompt> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (_, i) => _PinnedCard(prompt: prompts[i], onTap: onTap),
      ),
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.prompt, required this.onTap});
  final Prompt prompt;
  final ValueChanged<Prompt> onTap;

  @override
  Widget build(BuildContext context) {
    final models = prompt.modelTags
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();

    return GestureDetector(
      onTap: () => onTap(prompt),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    prompt.title,
                    style: AppTypography.label.copyWith(fontSize: 13.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRect(
                    child: _MonoPreview(body: prompt.body),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: models
                      .map((m) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.forModel(m),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            // Pin icon top-right
            Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.push_pin, size: 14, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonoPreview extends StatelessWidget {
  const _MonoPreview({required this.body});
  final String body;

  @override
  Widget build(BuildContext context) {
    return Text(
      body.replaceAll(RegExp(r'\{\{(\w+)\}\}'), r'$1'),
      style: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 11,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
```

- [ ] **Step 2: Create folder_row.dart**

```dart
// lib/features/library/widgets/folder_row.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/prompt_repository.dart';

class FolderRow extends StatelessWidget {
  const FolderRow({super.key, required this.folder, required this.onTap});

  final FolderEntry folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_outlined,
                  size: 19, color: AppColors.accentText),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(folder.name,
                      style: AppTypography.label.copyWith(fontSize: 14.5)),
                  const SizedBox(height: 1),
                  Text(
                    '${folder.count} prompt${folder.count == 1 ? '' : 's'}',
                    style:
                        AppTypography.bodySmall.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Rewrite prompt_card.dart (updated design)**

```dart
// lib/features/library/widgets/prompt_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/prompt_repository.dart';
import '../../../providers/repository_providers.dart';

class PromptCard extends ConsumerWidget {
  const PromptCard({super.key, required this.prompt, required this.onTap});

  final Prompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models =
        prompt.modelTags.split(',').where((s) => s.isNotEmpty).toList();
    final path = PromptRepository.decodePath(prompt.path);
    final searchTags = PromptRepository.decodePath(prompt.searchTags);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + model dots + pin
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    prompt.title,
                    style: AppTypography.label
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...models.map((m) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.forModel(m),
                            ),
                          ),
                        )),
                    if (prompt.pinned) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.push_pin,
                          size: 13, color: AppColors.accent),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mono body preview
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF), // borderHairline2
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.borderHairline2),
              ),
              child: Text(
                prompt.body
                    .replaceAll(RegExp(r'\{\{(\w+)\}\}'), r'$1')
                    .replaceAll('\n', ' '),
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 9),
            // Path crumb + tags
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _PathCrumb(path: path)),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 5,
                  children: searchTags
                      .take(2)
                      .map((t) => _TagChip(tag: t))
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PathCrumb extends StatelessWidget {
  const _PathCrumb({required this.path});
  final List<String> path;

  @override
  Widget build(BuildContext context) {
    final segments = ['Library', ...path];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Text('›',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary)),
            ),
          Text(
            segments[i],
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x33FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('#',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400)),
          Text(tag,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create folder_picker_sheet.dart**

```dart
// lib/features/library/widgets/folder_picker_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/prompt_repository.dart';

class FolderPickerSheet extends StatelessWidget {
  const FolderPickerSheet({
    super.key,
    required this.allPrompts,
    required this.currentPath,
    required this.onPick,
    this.title = 'Choose folder',
  });

  final List<Prompt> allPrompts;
  final List<String> currentPath;
  final ValueChanged<List<String>> onPick;
  final String title;

  @override
  Widget build(BuildContext context) {
    final paths = PromptRepository.allFolderPaths(allPrompts);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      AppTypography.screenTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 2),
              const Text('Pick where this prompt lives',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.46),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            itemCount: paths.length,
            itemBuilder: (_, i) {
              final pa = paths[i];
              final selected = PromptRepository._pathEquals(pa, currentPath);
              final indent = pa.isEmpty ? 0.0 : (pa.length - 1) * 10.0;
              return GestureDetector(
                onTap: () => onPick(pa),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accentTint : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentDim
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pa.isEmpty
                            ? Icons.book_outlined
                            : Icons.folder_outlined,
                        size: 18,
                        color: selected
                            ? AppColors.accentText
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 11),
                      Padding(
                        padding: EdgeInsets.only(left: indent),
                        child: pa.isEmpty
                            ? Text('Library (root)',
                                style: AppTypography.label.copyWith(
                                    fontSize: 13.5))
                            : _PathCrumbInline(path: pa, selected: selected),
                      ),
                      const Spacer(),
                      if (selected)
                        const Icon(Icons.check,
                            size: 17,
                            color: AppColors.accentText),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Private helper — same path logic exposed for FolderPickerSheet
extension _PathEq on PromptRepository {
  static bool _pathEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _PathCrumbInline extends StatelessWidget {
  const _PathCrumbInline({required this.path, required this.selected});
  final List<String> path;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (var i = 0; i < path.length; i++) ...[
          if (i > 0)
            Text(' › ',
                style: TextStyle(
                    fontSize: 13,
                    color: selected
                        ? AppColors.accentText
                        : AppColors.textTertiary)),
          Text(path[i],
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? AppColors.accentText
                      : AppColors.textPrimary)),
        ],
      ],
    );
  }
}
```

Note: The `_pathEquals` extension is a workaround — use `PromptRepository._pathEquals` directly since it's a static method. Actually, make `_pathEquals` public in `PromptRepository` (change `_pathEquals` to `pathEquals`) and use `PromptRepository.pathEquals(pa, currentPath)` in the sheet.

Update `prompt_repository.dart` to make `_pathEquals` and `_pathStartsWith` public:
```dart
static bool pathEquals(List<String> a, List<String> b) { ... }
static bool pathStartsWith(List<String> path, List<String> prefix) { ... }
```
And update `folderContentsAt` to call `pathEquals`/`pathStartsWith` (remove the `_` prefix).

Then `FolderPickerSheet` uses `PromptRepository.pathEquals(pa, currentPath)`.

- [ ] **Step 5: Create new_folder_sheet.dart**

```dart
// lib/features/library/widgets/new_folder_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/animations/animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class NewFolderSheet extends StatefulWidget {
  const NewFolderSheet({
    super.key,
    required this.currentPath,
    required this.onCreate,
  });

  final List<String> currentPath;
  final ValueChanged<String> onCreate;

  @override
  State<NewFolderSheet> createState() => _NewFolderSheetState();
}

class _NewFolderSheetState extends State<NewFolderSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.currentPath.isEmpty
        ? 'Library'
        : widget.currentPath.join(' › ');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New folder', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          Text('Creating in $location',
              style: AppTypography.bodySmall.copyWith(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 7),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.bgBase,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.accentDim),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined,
                    size: 18, color: AppColors.accentText),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: AppTypography.label,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Folder name',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) widget.onCreate(v.trim());
                    },
                  ),
                ),
                BlinkingCursor(color: AppColors.accent),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final name = _ctrl.text.trim();
                if (name.isNotEmpty) widget.onCreate(name);
              },
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Create folder'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Rewrite library_screen.dart**

```dart
// lib/features/library/library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/prompt_repository.dart';
import '../../providers/prompt_provider.dart';
import '../../providers/repository_providers.dart';
import 'widgets/folder_row.dart';
import 'widgets/new_folder_sheet.dart';
import 'widgets/pinned_row.dart';
import 'widgets/prompt_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<String> _path = [];
  String _query = '';
  bool _showNewFolder = false;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(promptsStreamProvider);

    return Scaffold(
      body: allAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) => _buildBody(context, all),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBody(BuildContext context, List<Prompt> all) {
    final atRoot = _path.isEmpty;
    final searching = _query.trim().isNotEmpty;
    final contents = PromptRepository.folderContentsAt(all, _path);
    final pinned = all.where((p) => p.pinned).toList();
    final searchResults = searching
        ? all.where((p) {
            final q = _query.toLowerCase();
            return p.title.toLowerCase().contains(q) ||
                p.body.toLowerCase().contains(q) ||
                PromptRepository.decodePath(p.searchTags)
                    .any((t) => t.contains(q));
          }).toList()
        : <Prompt>[];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    if (atRoot)
                      Row(
                        children: [
                          Text('Library',
                              style: AppTypography.screenTitle
                                  .copyWith(fontSize: 25, letterSpacing: -0.02 * 25)),
                          const Spacer(),
                          _IconBtn(
                            icon: Icons.add,
                            onTap: () => setState(() => _showNewFolder = true),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          _BackBtn(onTap: () =>
                              setState(() => _path = _path.sublist(0, _path.length - 1))),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _path.last,
                                  style: AppTypography.screenTitle.copyWith(
                                      fontSize: 19, letterSpacing: -0.01 * 19),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                _CrumbLine(path: ['Library', ..._path.sublist(0, _path.length - 1)]),
                              ],
                            ),
                          ),
                          _IconBtn(
                            icon: Icons.add,
                            onTap: () => setState(() => _showNewFolder = true),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Search bar
                    _SearchBar(
                      query: _query,
                      onChanged: (q) => setState(() => _query = q),
                    ),
                  ],
                ),
              ),
            ),

            if (searching) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${searchResults.length} result${searchResults.length == 1 ? '' : 's'} for "$_query"',
                    style: AppTypography.bodySmall
                        .copyWith(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverList.separated(
                  itemCount: searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => PromptCard(
                    prompt: searchResults[i],
                    onTap: () => context.push('/prompt', extra: searchResults[i].id),
                  ),
                ),
              ),
            ] else ...[
              // Pinned section (root only)
              if (atRoot && pinned.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 0, 8),
                    child: _SectionLabel(text: 'Pinned'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: PinnedRow(
                    prompts: pinned,
                    onTap: (p) => context.push('/prompt', extra: p.id),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 22)),
              ],

              // Folders
              if (contents.folders.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: _SectionLabel(text: atRoot ? 'Folders' : 'Subfolders'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  sliver: SliverList.separated(
                    itemCount: contents.folders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => FolderRow(
                      folder: contents.folders[i],
                      onTap: () => setState(
                          () => _path = [..._path, contents.folders[i].name]),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 22)),
              ],

              // Prompts
              if (contents.prompts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: _SectionLabel(
                        text: atRoot ? 'All prompts' : 'Prompts here'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                  sliver: SliverList.separated(
                    itemCount: contents.prompts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => PromptCard(
                      prompt: contents.prompts[i],
                      onTap: () => context.push('/prompt',
                          extra: contents.prompts[i].id),
                    ),
                  ),
                ),
              ],

              if (contents.folders.isEmpty && contents.prompts.isEmpty && !atRoot)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No prompts here yet.',
                        style: TextStyle(color: AppColors.textTertiary)),
                  ),
                ),
            ],
          ],
        ),

        // New folder sheet
        if (_showNewFolder)
          _BottomSheetOverlay(
            onDismiss: () => setState(() => _showNewFolder = false),
            child: NewFolderSheet(
              currentPath: _path,
              onCreate: (name) {
                setState(() {
                  _showNewFolder = false;
                  _path = [..._path, name];
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Folder "$name" created')),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 6),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(top: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Row(
        children: [
          _NavItem(icon: Icons.book_outlined, label: 'Library', active: true,
              onTap: () {}),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => context.push('/editor'),
                child: Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.6),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
              const Text('New prompt',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            active: false,
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable pieces ─────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.06,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.query, required this.onChanged});
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: query.isNotEmpty ? AppColors.accentDim : AppColors.borderHairline,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 17,
              color: query.isNotEmpty ? AppColors.accentText : AppColors.textTertiary),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search prompts, folders, tags',
                hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13.5),
              ),
            ),
          ),
          if (query.isNotEmpty)
            GestureDetector(
              onTap: () => onChanged(''),
              child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _CrumbLine extends StatelessWidget {
  const _CrumbLine({required this.path});
  final List<String> path;

  @override
  Widget build(BuildContext context) {
    return Text(
      path.join(' › '),
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22,
              color: active ? AppColors.accentText : AppColors.textTertiary),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? AppColors.accentText : AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _BottomSheetOverlay extends StatelessWidget {
  const _BottomSheetOverlay({required this.child, required this.onDismiss});
  final Widget child;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // don't bubble
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                    top: BorderSide(color: AppColors.borderHairline)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Center(
                      child: SizedBox(
                        width: 38,
                        height: 4.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x2EFFFFFF),
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Add `/prompt` route to app.dart**

Read `lib/app.dart`. Add to the routes list:
```dart
GoRoute(
  path: '/prompt',
  builder: (_, state) => PromptDetailScreen(promptId: state.extra as int),
),
```

Add import: `import 'features/prompt_detail/prompt_detail_screen.dart';`

Also add `/tags` route inside the ShellRoute:
```dart
GoRoute(path: '/tags', builder: (_, __) => const TagsScreen()),
```

Add import: `import 'features/settings/tags_screen.dart';` (created in Task 9).

For now create placeholder `lib/features/prompt_detail/prompt_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';
class PromptDetailScreen extends StatelessWidget {
  const PromptDetailScreen({super.key, required this.promptId});
  final int promptId;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Prompt detail')));
}
```

And `lib/features/settings/tags_screen.dart`:
```dart
import 'package:flutter/material.dart';
class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Tags')));
}
```

- [ ] **Step 8: Build and verify**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: library redesign — pinned row, folder browser, breadcrumb nav, new prompt card"
```

---

## Task 6: Prompt Detail Screen

**Files:**
- Modify: `lib/features/prompt_detail/prompt_detail_screen.dart` (replace placeholder)

- [ ] **Step 1: Implement prompt_detail_screen.dart**

```dart
// lib/features/prompt_detail/prompt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/prompt_repository.dart';
import '../../providers/prompt_provider.dart';
import '../../providers/repository_providers.dart';
import '../library/widgets/folder_picker_sheet.dart';

class PromptDetailScreen extends ConsumerStatefulWidget {
  const PromptDetailScreen({super.key, required this.promptId});
  final int promptId;

  @override
  ConsumerState<PromptDetailScreen> createState() =>
      _PromptDetailScreenState();
}

class _PromptDetailScreenState extends ConsumerState<PromptDetailScreen> {
  bool _showMovePicker = false;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(promptsStreamProvider);

    return allAsync.when(
      loading: () => const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.accent))),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (all) {
        final prompt = all.firstWhere(
          (p) => p.id == widget.promptId,
          orElse: () => all.first,
        );
        return _buildScreen(context, prompt, all);
      },
    );
  }

  Widget _buildScreen(
      BuildContext context, Prompt prompt, List<Prompt> all) {
    final pinned = prompt.pinned;
    final path = PromptRepository.decodePath(prompt.path);
    final models =
        prompt.modelTags.split(',').where((s) => s.isNotEmpty).toList();
    final tags = PromptRepository.decodePath(prompt.searchTags);
    final vars = RegExp(r'\{\{(\w+)\}\}')
        .allMatches(prompt.body)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Nav bar
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Row(
                          children: const [
                            Icon(Icons.chevron_left,
                                size: 20, color: AppColors.textSecondary),
                            Text('Library',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Pin toggle
                      GestureDetector(
                        onTap: () => ref
                            .read(promptRepositoryProvider)
                            .togglePin(prompt.id, !pinned),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: pinned
                                ? AppColors.accentTint
                                : AppColors.surface1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: pinned
                                  ? AppColors.accentDim
                                  : AppColors.borderHairline,
                            ),
                          ),
                          child: Icon(
                            Icons.push_pin,
                            size: 18,
                            color: pinned
                                ? AppColors.accentText
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scrollable body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                  children: [
                    Text(prompt.title,
                        style: AppTypography.screenTitle.copyWith(
                            fontSize: 23, letterSpacing: -0.02 * 23,
                            height: 1.2)),
                    const SizedBox(height: 12),

                    // Path + Move
                    Row(
                      children: [
                        Expanded(
                          child: _CrumbLine(
                              path: ['Library', ...path], size: 12),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showMovePicker = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.borderHairline),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.folder_outlined,
                                    size: 13,
                                    color: AppColors.textSecondary),
                                SizedBox(width: 5),
                                Text('Move',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Models
                    _Section(label: 'Models'),
                    const SizedBox(height: 8),
                    models.isNotEmpty
                        ? Wrap(
                            spacing: 7,
                            children:
                                models.map((m) => _ModelChip(m)).toList())
                        : const Text('No model tags',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textTertiary)),
                    const SizedBox(height: 18),

                    // Tags
                    _Section(label: 'Search tags'),
                    const SizedBox(height: 8),
                    tags.isNotEmpty
                        ? Wrap(
                            spacing: 7,
                            children: tags.map((t) => _TagPill(t)).toList())
                        : const Text('No tags',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textTertiary)),
                    const SizedBox(height: 18),

                    // Prompt body
                    _Section(label: 'Prompt'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.borderHairline),
                      ),
                      child: Text(
                        prompt.body,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.65,
                        ),
                      ),
                    ),
                    if (vars.isNotEmpty) ...[
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          const Icon(Icons.tune,
                              size: 15, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          Text(
                            '${vars.length} variable${vars.length == 1 ? '' : 's'} filled in when used',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),

          // Bottom actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              decoration: BoxDecoration(
                color: AppColors.bgBase,
                border: Border(
                    top: BorderSide(color: AppColors.borderHairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 0,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/editor', extra: prompt.id),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(
                            color: AppColors.borderHairline),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: prompt.body));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied to clipboard')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy to clipboard'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Move folder sheet
          if (_showMovePicker)
            _SheetOverlay(
              onDismiss: () => setState(() => _showMovePicker = false),
              child: FolderPickerSheet(
                allPrompts: all,
                currentPath: path,
                title: 'Move to folder',
                onPick: (newPath) async {
                  await ref
                      .read(promptRepositoryProvider)
                      .moveTo(prompt.id, newPath);
                  if (mounted) setState(() => _showMovePicker = false);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.06,
            color: AppColors.textTertiary));
  }
}

class _CrumbLine extends StatelessWidget {
  const _CrumbLine({required this.path, this.size = 11.0});
  final List<String> path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (var i = 0; i < path.length; i++) ...[
          if (i > 0)
            Text(' › ',
                style: TextStyle(
                    fontSize: size, color: AppColors.textTertiary)),
          Text(path[i],
              style: TextStyle(
                  fontSize: size,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class _ModelChip extends StatelessWidget {
  const _ModelChip(this.key_);
  final String key_;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forModel(key_);
    final label = switch (key_) {
      'claude' => 'Claude',
      'chatgpt' => 'ChatGPT',
      'gemini' => 'Gemini',
      _ => 'Local',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 9, 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill(this.tag);
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x33FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('#',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textTertiary)),
          Text(tag,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SheetOverlay extends StatelessWidget {
  const _SheetOverlay({required this.child, required this.onDismiss});
  final Widget child;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface2,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                border:
                    Border(top: BorderSide(color: AppColors.borderHairline)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 0),
                    child: Center(
                      child: SizedBox(
                        width: 38,
                        height: 4.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x2EFFFFFF),
                            borderRadius:
                                BorderRadius.all(Radius.circular(999)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Build and verify**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: prompt detail screen — full body, models, tags, path, copy + edit actions"
```

---

## Task 7: Editor Screen Update

**Files:**
- Modify: `lib/features/editor/editor_screen.dart`

- [ ] **Step 1: Rewrite editor_screen.dart**

Read the current `lib/features/editor/editor_screen.dart` first. Then replace with:

```dart
// lib/features/editor/editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/prompt_repository.dart';
import '../../providers/prompt_provider.dart';
import '../../providers/repository_providers.dart';
import '../../services/variable_detector.dart';
import '../library/widgets/folder_picker_sheet.dart';
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
  List<String> _path = [];
  List<String> _searchTags = [];
  List<String> _models = [];
  List<String> _detectedVars = [];
  bool _loading = true;
  int? _existingId;
  bool _showFolderPicker = false;
  final _newTagCtrl = TextEditingController();

  static const _modelOptions = [
    ('claude', 'Claude'),
    ('chatgpt', 'ChatGPT'),
    ('gemini', 'Gemini'),
    ('local', 'Local'),
  ];

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
          _existingId = p.id;
          _titleCtrl.text = p.title;
          _bodyCtrl.text = p.body;
          _pinned = p.pinned;
          _path = PromptRepository.decodePath(p.path);
          _searchTags = PromptRepository.decodePath(p.searchTags);
          _models = p.modelTags.split(',').where((s) => s.isNotEmpty).toList();
          _detectedVars = VariableDetector.detect(p.body);
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onBodyChanged() {
    setState(() => _detectedVars = VariableDetector.detect(_bodyCtrl.text));
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    final repo = ref.read(promptRepositoryProvider);
    final modelTags = _models.join(',');
    if (_existingId != null) {
      await repo.update(
        id: _existingId!,
        title: title,
        body: body,
        path: _path,
        searchTags: _searchTags,
        modelTags: modelTags,
        pinned: _pinned,
      );
    } else {
      await repo.create(
        title: title,
        body: body,
        path: _path,
        searchTags: _searchTags,
        modelTags: modelTags,
        pinned: _pinned,
      );
    }
    if (mounted) {
      if (_detectedVars.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Detected ${_detectedVars.length} variable(s): ${_detectedVars.join(', ')}')),
        );
      }
      context.pop();
    }
  }

  Future<void> _delete() async {
    if (_existingId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Delete prompt?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(promptRepositoryProvider).delete(_existingId!);
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _bodyCtrl.removeListener(_onBodyChanged);
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _newTagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.accent)));
    }

    final allAsync = ref.watch(promptsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ),
        leadingWidth: 80,
        title: Text(
          _existingId == null ? 'New prompt' : 'Edit prompt',
          style: AppTypography.label,
        ),
        actions: [
          if (_existingId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.accentText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              _field('Title',
                TextField(
                  controller: _titleCtrl,
                  style: AppTypography.label,
                  decoration: const InputDecoration(
                      hintText: 'Name your prompt',
                      labelText: 'Title'),
                )),
              const SizedBox(height: 4),

              // Body
              _field('Prompt',
                TextField(
                  controller: _bodyCtrl,
                  style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.65),
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText:
                        'Write your prompt. Wrap variables in {{braces}}.',
                    labelText: 'Body',
                    alignLabelWithHint: true,
                  ),
                )),

              // Variable preview
              if (_bodyCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionLabel('Preview'),
                const SizedBox(height: 6),
                VariablePreview(
                    body: _bodyCtrl.text, variableNames: _detectedVars),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 16),

              // Folder picker
              _SectionLabel('Folder'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _showFolderPicker = true),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.accentTint,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.folder_outlined,
                            size: 17, color: AppColors.accentText),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _path.isEmpty
                            ? const Text('Library (root)',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textSecondary))
                            : _CrumbText(path: ['Library', ..._path]),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Models
              _SectionLabel('Models'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _modelOptions.map((entry) {
                  final (key, label) = entry;
                  final selected = _models.contains(key);
                  final color = AppColors.forModel(key);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _models.remove(key);
                      } else {
                        _models.add(key);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? color.withOpacity(0.13) : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? color.withOpacity(0.47)
                              : AppColors.borderHairline,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: color),
                          ),
                          const SizedBox(width: 6),
                          Text(label,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: selected
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                          if (selected) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.check,
                                size: 13, color: AppColors.textPrimary),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Search tags
              _SectionLabel('Search tags'),
              const SizedBox(height: 8),
              if (_searchTags.isNotEmpty) ...[
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: _searchTags
                      .map((t) => GestureDetector(
                            onTap: () => setState(() => _searchTags.remove(t)),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 3, 8, 3),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0x33FFFFFF)),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('#',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textTertiary)),
                                  Text(t,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.close,
                                      size: 12,
                                      color: AppColors.textTertiary),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTagCtrl,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                          hintText: 'add a search tag'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final tag = _newTagCtrl.text.trim();
                      if (tag.isNotEmpty && !_searchTags.contains(tag)) {
                        setState(() {
                          _searchTags.add(tag);
                          _newTagCtrl.clear();
                        });
                      }
                    },
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.borderHairline),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 15, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Text('Add',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pin
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: SwitchListTile(
                  title: Text('Pinned', style: AppTypography.label),
                  subtitle: Text('Always shows first in overlay',
                      style: AppTypography.bodySmall),
                  value: _pinned,
                  onChanged: (v) => setState(() => _pinned = v),
                  activeColor: AppColors.accent,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),

          // Bottom save button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              color: AppColors.bgBase,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, size: 17),
                    const SizedBox(width: 8),
                    Text(_existingId == null ? 'Create prompt' : 'Save changes',
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),

          // Folder picker overlay
          if (_showFolderPicker)
            allAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (all) => _SheetOverlay(
                onDismiss: () => setState(() => _showFolderPicker = false),
                child: FolderPickerSheet(
                  allPrompts: all,
                  currentPath: _path,
                  onPick: (p) => setState(() {
                    _path = p;
                    _showFolderPicker = false;
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(String label, Widget input) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 6),
        input,
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.06,
            color: AppColors.textTertiary),
      );
}

class _CrumbText extends StatelessWidget {
  const _CrumbText({required this.path});
  final List<String> path;

  @override
  Widget build(BuildContext context) => Text(
        path.join(' › '),
        style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      );
}

class _SheetOverlay extends StatelessWidget {
  const _SheetOverlay({required this.child, required this.onDismiss});
  final Widget child;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.borderHairline)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Center(
                      child: SizedBox(
                        width: 38,
                        height: 4.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x2EFFFFFF),
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Build and run tests**

```bash
flutter test && flutter build apk --debug 2>&1 | tail -3
```

Expected: all tests pass, APK builds.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: editor redesign — folder picker sheet, search tags, model chips, clean layout"
```
