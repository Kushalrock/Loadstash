# Import / Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task.

**Goal:** Add APM-compatible ZIP import and export so users can share prompt packs as `.zip` files containing `apm.yml` + `.prompt.md` files.

**Architecture:** Three pure service classes handle parsing (`PromptFileParser`), import (`ImportService`), and export (`ExportService`). Two UI sheets handle scope selection (export) and folder assignment (import of path-less prompts). The settings screen wires them together. Variable syntax converts between `{{name}}` (internal) and `${input:name}` (APM) on import/export.

**Tech Stack:** Flutter · `archive` (ZIP) · `file_picker` (Android file picker) · `share_plus` (Android share sheet) · `yaml` (YAML frontmatter parsing) · Drift/PromptRepository (existing)

---

## File Structure

```
lib/services/
  prompt_file_parser.dart        CREATE — parse .prompt.md → ParsedPrompt + ApmPackage
  import_service.dart            CREATE — ZIP decode → PromptRepository.create() calls
  export_service.dart            CREATE — prompts → ZIP bytes (apm.yml + .prompt.md files)

lib/features/settings/widgets/
  export_scope_sheet.dart        CREATE — 3-option scope picker bottom sheet
  folder_assignment_sheet.dart   CREATE — FolderPickerSheet wrapper for path-less import

lib/features/settings/
  settings_screen.dart           MODIFY — wire Import ZIP + Export ZIP buttons

pubspec.yaml                     MODIFY — add archive, file_picker, share_plus, yaml

test/services/
  prompt_file_parser_test.dart   CREATE
  export_service_test.dart       CREATE
  import_service_test.dart       CREATE
```

---

## Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add packages to pubspec.yaml**

In `pubspec.yaml`, add to the `dependencies:` section:

```yaml
dependencies:
  flutter:
    sdk: flutter
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.2.7
  google_fonts: ^6.2.1
  shared_preferences: ^2.3.2
  # Import / Export
  archive: ^3.6.1
  file_picker: ^8.1.4
  share_plus: ^10.1.2
  yaml: ^3.1.2
```

- [ ] **Step 2: Install**

```bash
cd /Users/agrkushal/Documents/Promptezy/promptezy
flutter pub get
```

Expected: resolves without errors. If a version conflicts, try the next lower minor.

- [ ] **Step 3: Build to verify**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add archive, file_picker, share_plus, yaml dependencies"
```

---

## Task 2: PromptFileParser

**Files:**
- Create: `lib/services/prompt_file_parser.dart`
- Create: `test/services/prompt_file_parser_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/services/prompt_file_parser_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/prompt_file_parser.dart';

void main() {
  group('PromptFileParser.parseFile', () {
    test('parses description, input with hints, body with variable conversion', () {
      const content = '''---
description: Cold outreach email
input:
  - name: "Recipient name"
  - company: "Company name"
  - length: "Max words e.g. 120"
model: claude
x-loadstash-path: [Writing, Email, Cold]
x-loadstash-tags: [work, sales]
x-loadstash-pinned: true
x-loadstash-model-tags: [claude, chatgpt]
---

Write a cold email to \${input:name} at \${input:company}. Under \${input:length} words.
''';
      final p = PromptFileParser.parseFile(content);
      expect(p.title, 'Cold outreach email');
      expect(p.inputs.map((i) => i.name).toList(), ['name', 'company', 'length']);
      expect(p.inputs.first.hint, 'Recipient name');
      expect(p.path, ['Writing', 'Email', 'Cold']);
      expect(p.searchTags, ['work', 'sales']);
      expect(p.pinned, true);
      expect(p.modelTags, ['claude', 'chatgpt']);
      // Body has {{name}} not \${input:name}
      expect(p.body, contains('{{name}}'));
      expect(p.body, isNot(contains('\${input:name}')));
    });

    test('falls back to model: field when no x-loadstash-model-tags', () {
      const content = '''---
description: Review PR
input:
  - pr_url
model: gemini
---

Review \${input:pr_url}
''';
      final p = PromptFileParser.parseFile(content);
      expect(p.modelTags, ['gemini']);
    });

    test('handles simple input list (no hints)', () {
      const content = '''---
description: Simple
input: [topic, audience]
---

Write about \${input:topic} for \${input:audience}.
''';
      final p = PromptFileParser.parseFile(content);
      expect(p.inputs.map((i) => i.name).toList(), ['topic', 'audience']);
      expect(p.inputs.first.hint, '');
    });

    test('returns empty path/tags when no x-loadstash fields', () {
      const content = '''---
description: No loadstash fields
---

Just a body.
''';
      final p = PromptFileParser.parseFile(content);
      expect(p.path, isEmpty);
      expect(p.searchTags, isEmpty);
      expect(p.pinned, false);
      expect(p.modelTags, isEmpty);
    });

    test('convertFromApm replaces \${input:name} with {{name}}', () {
      const body = 'Hello \${input:name} from \${input:city}.';
      expect(PromptFileParser.convertFromApm(body), 'Hello {{name}} from {{city}}.');
    });
  });

  group('ExportService.convertToApm', () {
    test('replaces {{name}} with \${input:name}', () {
      const body = 'Hello {{name}} from {{city}}.';
      expect(PromptFileParser.convertToApm(body), 'Hello \${input:name} from \${input:city}.');
    });
  });
}
```

- [ ] **Step 2: Run to verify fail**

```bash
flutter test test/services/prompt_file_parser_test.dart
```

Expected: FAIL — `prompt_file_parser.dart` does not exist.

- [ ] **Step 3: Create prompt_file_parser.dart**

```dart
// lib/services/prompt_file_parser.dart
import 'package:yaml/yaml.dart';

class VariableInput {
  const VariableInput({required this.name, required this.hint});
  final String name;
  final String hint;
}

class ParsedPrompt {
  const ParsedPrompt({
    required this.title,
    required this.body,
    required this.inputs,
    required this.modelTags,
    required this.path,
    required this.searchTags,
    required this.pinned,
  });

  final String title;
  final String body;
  final List<VariableInput> inputs;
  final List<String> modelTags;
  final List<String> path;
  final List<String> searchTags;
  final bool pinned;
}

class ApmPackage {
  const ApmPackage({
    required this.name,
    required this.version,
    required this.prompts,
  });

  final String name;
  final String version;
  final List<ParsedPrompt> prompts;

  bool get hasPathlessPrompts => prompts.any((p) => p.path.isEmpty);
  int get pathlessCount => prompts.where((p) => p.path.isEmpty).length;
}

abstract final class PromptFileParser {
  // Parses a single .prompt.md file content into a ParsedPrompt.
  static ParsedPrompt parseFile(String content) {
    final parts = content.split('---');
    // parts[0] = '' (before first ---), parts[1] = frontmatter, parts[2+] = body
    if (parts.length < 3) {
      // No frontmatter — treat whole content as body
      return ParsedPrompt(
        title: 'Untitled',
        body: content.trim(),
        inputs: [],
        modelTags: [],
        path: [],
        searchTags: [],
        pinned: false,
      );
    }

    final frontmatter = parts[1];
    final body = parts.sublist(2).join('---').trim();

    YamlMap? fm;
    try {
      final loaded = loadYaml(frontmatter);
      if (loaded is YamlMap) fm = loaded;
    } catch (_) {}

    final title = fm?['description']?.toString() ?? 'Untitled';
    final inputs = _parseInputs(fm?['input']);

    // x-loadstash-model-tags overrides model:
    final xModelTags = _parseStringList(fm?['x-loadstash-model-tags']);
    final modelFallback = fm?['model']?.toString();
    final modelTags = xModelTags.isNotEmpty
        ? xModelTags
        : (modelFallback != null ? [modelFallback] : <String>[]);

    final path = _parseStringList(fm?['x-loadstash-path']);
    final searchTags = _parseStringList(fm?['x-loadstash-tags']);
    final pinned = fm?['x-loadstash-pinned'] == true;

    return ParsedPrompt(
      title: title,
      body: convertFromApm(body),
      inputs: inputs,
      modelTags: modelTags,
      path: path,
      searchTags: searchTags,
      pinned: pinned,
    );
  }

  // Converts ${input:name} → {{name}} for internal storage.
  static String convertFromApm(String body) {
    return body.replaceAllMapped(
      RegExp(r'\$\{input:([A-Za-z][\w-]*)\}'),
      (m) => '{{${m.group(1)}}}',
    );
  }

  // Converts {{name}} → ${input:name} for APM export.
  static String convertToApm(String body) {
    return body.replaceAllMapped(
      RegExp(r'\{\{([A-Za-z][\w-]*)\}\}'),
      (m) => '\${input:${m.group(1)}}',
    );
  }

  static List<VariableInput> _parseInputs(dynamic input) {
    if (input == null) return [];
    // Simple list: [name, scope]
    if (input is YamlList) {
      return input.map<VariableInput?>((item) {
        if (item is String) return VariableInput(name: item, hint: '');
        if (item is YamlMap && item.isNotEmpty) {
          final entry = item.entries.first;
          return VariableInput(
            name: entry.key.toString(),
            hint: entry.value?.toString() ?? '',
          );
        }
        return null;
      }).whereType<VariableInput>().toList();
    }
    return [];
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is YamlList) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/services/prompt_file_parser_test.dart
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/prompt_file_parser.dart test/services/prompt_file_parser_test.dart
git commit -m "feat: PromptFileParser — .prompt.md parsing + APM variable conversion"
```

---

## Task 3: ExportService

**Files:**
- Create: `lib/services/export_service.dart`
- Create: `test/services/export_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/services/export_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/export_service.dart';
import 'package:loadstash/services/prompt_file_parser.dart';

void main() {
  group('ExportService.slugifyTitle', () {
    test('converts spaces to hyphens and lowercases', () {
      expect(ExportService.slugifyTitle('Cold Outreach Email'), 'cold-outreach-email');
    });

    test('strips special characters', () {
      expect(ExportService.slugifyTitle('Review PR (fast!)'), 'review-pr-fast');
    });

    test('truncates to 60 chars', () {
      final long = 'a' * 80;
      expect(ExportService.slugifyTitle(long).length, 60);
    });

    test('collapses multiple hyphens', () {
      expect(ExportService.slugifyTitle('hello   world'), 'hello-world');
    });
  });

  group('ExportService.buildPromptMd', () {
    test('writes APM frontmatter and converts variables', () {
      final md = ExportService.buildPromptMd(
        title: 'Cold outreach email',
        body: 'Write to {{name}} at {{company}}.',
        variableNames: ['name', 'company'],
        variableHints: {'name': 'Recipient name', 'company': 'Company name'},
        modelTags: ['claude', 'chatgpt'],
        path: ['Writing', 'Email'],
        searchTags: ['work'],
        pinned: false,
      );
      expect(md, contains('description: Cold outreach email'));
      expect(md, contains('- name: "Recipient name"'));
      expect(md, contains('- company: "Company name"'));
      expect(md, contains('model: claude'));
      expect(md, contains('x-loadstash-path: [Writing, Email]'));
      expect(md, contains('x-loadstash-tags: [work]'));
      expect(md, contains('x-loadstash-pinned: false'));
      expect(md, contains('x-loadstash-model-tags: [claude, chatgpt]'));
      // Body has APM syntax
      expect(md, contains('\${input:name}'));
      expect(md, isNot(contains('{{name}}')));
    });

    test('omits model when no model tags', () {
      final md = ExportService.buildPromptMd(
        title: 'T', body: 'B', variableNames: [], variableHints: {},
        modelTags: [], path: [], searchTags: [], pinned: false,
      );
      expect(md, isNot(contains('model:')));
    });

    test('builds apm.yml content', () {
      final yml = ExportService.buildApmYml(name: 'my-pack', version: '1.0.0', description: 'desc');
      expect(yml, contains('name: my-pack'));
      expect(yml, contains('version: 1.0.0'));
      expect(yml, contains('type: prompts'));
    });
  });
}
```

- [ ] **Step 2: Run to verify fail**

```bash
flutter test test/services/export_service_test.dart
```

Expected: FAIL — `export_service.dart` not found.

- [ ] **Step 3: Create export_service.dart**

```dart
// lib/services/export_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../data/database/app_database.dart';
import '../data/repositories/prompt_repository.dart';
import '../services/variable_detector.dart';
import 'prompt_file_parser.dart';

enum ExportScope { all, yours, starters }

abstract final class ExportService {
  /// Builds a ZIP containing apm.yml + one .prompt.md per prompt.
  static Future<Uint8List> buildZip(List<Prompt> prompts) async {
    final archive = Archive();

    // apm.yml
    final apmYml = buildApmYml(
      name: 'loadstash-export',
      version: '1.0.0',
      description: 'Exported prompts from Loadstash',
    );
    final apmBytes = utf8.encode(apmYml);
    archive.addFile(ArchiveFile('apm.yml', apmBytes.length, apmBytes));

    // .prompt.md files
    final usedNames = <String>{};
    for (final prompt in prompts) {
      final path = PromptRepository.decodePath(prompt.path);
      final searchTags = PromptRepository.decodePath(prompt.searchTags);
      final modelTags = prompt.modelTags.split(',').where((s) => s.isNotEmpty).toList();
      final varNames = VariableDetector.detect(prompt.body);

      // Build slug — deduplicate if needed
      var slug = slugifyTitle(prompt.title);
      if (slug.isEmpty) slug = 'prompt';
      var uniqueSlug = slug;
      var counter = 2;
      while (usedNames.contains(uniqueSlug)) {
        uniqueSlug = '$slug-$counter';
        counter++;
      }
      usedNames.add(uniqueSlug);

      final md = buildPromptMd(
        title: prompt.title,
        body: prompt.body,
        variableNames: varNames,
        variableHints: const {}, // no stored hints — leave blank on export
        modelTags: modelTags,
        path: path,
        searchTags: searchTags,
        pinned: prompt.pinned,
      );
      final mdBytes = utf8.encode(md);
      archive.addFile(ArchiveFile(
        '.apm/prompts/$uniqueSlug.prompt.md',
        mdBytes.length,
        mdBytes,
      ));
    }

    final zipBytes = ZipEncoder().encode(archive)!;
    return Uint8List.fromList(zipBytes);
  }

  /// Builds a single .prompt.md file string.
  static String buildPromptMd({
    required String title,
    required String body,
    required List<String> variableNames,
    required Map<String, String> variableHints,
    required List<String> modelTags,
    required List<String> path,
    required List<String> searchTags,
    required bool pinned,
  }) {
    final sb = StringBuffer();
    sb.writeln('---');
    sb.writeln('description: ${_yamlStr(title)}');

    if (variableNames.isNotEmpty) {
      sb.writeln('input:');
      for (final v in variableNames) {
        final hint = variableHints[v] ?? '';
        if (hint.isNotEmpty) {
          sb.writeln('  - $v: "${hint.replaceAll('"', '\\"')}"');
        } else {
          sb.writeln('  - $v');
        }
      }
    }

    if (modelTags.isNotEmpty) {
      sb.writeln('model: ${modelTags.first}');
    }

    if (path.isNotEmpty) {
      sb.writeln('x-loadstash-path: ${_yamlStringList(path)}');
    }

    if (searchTags.isNotEmpty) {
      sb.writeln('x-loadstash-tags: ${_yamlStringList(searchTags)}');
    }

    sb.writeln('x-loadstash-pinned: $pinned');

    if (modelTags.isNotEmpty) {
      sb.writeln('x-loadstash-model-tags: ${_yamlStringList(modelTags)}');
    }

    sb.writeln('---');
    sb.writeln();
    sb.write(PromptFileParser.convertToApm(body));

    return sb.toString();
  }

  /// Builds apm.yml content.
  static String buildApmYml({
    required String name,
    required String version,
    required String description,
  }) {
    return '''name: $name
version: $version
description: ${_yamlStr(description)}
type: prompts
''';
  }

  /// Slugifies a title for use as a filename (no extension).
  static String slugifyTitle(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    return slug.length > 60 ? slug.substring(0, 60) : slug;
  }

  // Wraps a string in quotes only if it contains special YAML chars.
  static String _yamlStr(String s) {
    if (s.contains(':') || s.contains('#') || s.contains('"')) {
      return '"${s.replaceAll('"', '\\"')}"';
    }
    return s;
  }

  static String _yamlStringList(List<String> list) {
    return '[${list.map((s) => s).join(', ')}]';
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/services/export_service_test.dart
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/export_service.dart test/services/export_service_test.dart
git commit -m "feat: ExportService — ZIP builder with APM .prompt.md format"
```

---

## Task 4: ImportService

**Files:**
- Create: `lib/services/import_service.dart`
- Create: `test/services/import_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/services/import_service_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';
import 'package:loadstash/services/import_service.dart';

Uint8List _buildZip({
  String apmYml = 'name: test-pack\nversion: 1.2.3\ntype: prompts\n',
  Map<String, String> prompts = const {},
}) {
  final archive = Archive();
  final apmBytes = utf8.encode(apmYml);
  archive.addFile(ArchiveFile('apm.yml', apmBytes.length, apmBytes));
  for (final entry in prompts.entries) {
    final bytes = utf8.encode(entry.value);
    archive.addFile(ArchiveFile('.apm/prompts/${entry.key}', bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  group('ImportService.parseZip', () {
    test('reads pack name and version from apm.yml', () {
      final zip = _buildZip();
      final pkg = ImportService.parseZip(zip);
      expect(pkg.name, 'test-pack');
      expect(pkg.version, '1.2.3');
    });

    test('throws if apm.yml is missing', () {
      final archive = Archive();
      final zip = Uint8List.fromList(ZipEncoder().encode(archive)!);
      expect(() => ImportService.parseZip(zip), throwsArgumentError);
    });

    test('parses .prompt.md files', () {
      const promptContent = '''---
description: My prompt
input:
  - topic: "The topic"
---

Write about \${input:topic}.
''';
      final zip = _buildZip(prompts: {'my-prompt.prompt.md': promptContent});
      final pkg = ImportService.parseZip(zip);
      expect(pkg.prompts.length, 1);
      expect(pkg.prompts.first.title, 'My prompt');
      expect(pkg.prompts.first.body, contains('{{topic}}'));
    });

    test('ignores non-.prompt.md files', () {
      final zip = _buildZip(prompts: {
        'valid.prompt.md': '---\ndescription: Valid\n---\nBody',
        'README.md': '# ignore me',
        'config.json': '{}',
      });
      final pkg = ImportService.parseZip(zip);
      expect(pkg.prompts.length, 1);
    });

    test('hasPathlessPrompts is true when a prompt has no x-loadstash-path', () {
      const promptContent = '---\ndescription: No path\n---\nBody';
      final zip = _buildZip(prompts: {'p.prompt.md': promptContent});
      expect(ImportService.parseZip(zip).hasPathlessPrompts, true);
    });
  });

  group('ImportService.importParsed', () {
    late AppDatabase db;
    late PromptRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = PromptRepository(db);
    });
    tearDown(() async => db.close());

    test('creates prompts with fallback path for path-less entries', () async {
      const promptContent = '---\ndescription: Path-less prompt\n---\nHello {{name}}.';
      final zip = _buildZip(prompts: {'p.prompt.md': promptContent});
      final pkg = ImportService.parseZip(zip);

      final result = await ImportService.importParsed(
        pkg, repo, fallbackPath: ['Inbox'],
      );
      expect(result.imported, 1);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(PromptRepository.decodePath(all.first.path), ['Inbox']);
    });

    test('uses x-loadstash-path when present, ignores fallback', () async {
      const promptContent = '''---
description: Has path
x-loadstash-path: [Writing, Email]
---
Body.''';
      final zip = _buildZip(prompts: {'p.prompt.md': promptContent});
      final pkg = ImportService.parseZip(zip);

      await ImportService.importParsed(pkg, repo, fallbackPath: ['Inbox']);
      final all = await repo.getAll();
      expect(PromptRepository.decodePath(all.first.path), ['Writing', 'Email']);
    });
  });
}
```

- [ ] **Step 2: Run to verify fail**

```bash
flutter test test/services/import_service_test.dart
```

Expected: FAIL.

- [ ] **Step 3: Create import_service.dart**

```dart
// lib/services/import_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../data/repositories/prompt_repository.dart';
import 'prompt_file_parser.dart';

class ImportResult {
  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.packName,
    required this.packVersion,
  });

  final int imported;
  final int skipped;
  final String packName;
  final String packVersion;
}

abstract final class ImportService {
  /// Decodes a ZIP and returns an [ApmPackage] without writing to the DB.
  /// Throws [ArgumentError] if apm.yml is missing.
  static ApmPackage parseZip(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Find apm.yml
    final apmFile = archive.files.where((f) => f.isFile && f.name == 'apm.yml').firstOrNull;
    if (apmFile == null) {
      throw ArgumentError('ZIP must contain apm.yml at root');
    }

    final apmContent = utf8.decode(apmFile.content as List<int>);
    final (name, version) = _parseApmYml(apmContent);

    // Find .prompt.md files anywhere under .apm/prompts/
    final prompts = <ParsedPrompt>[];
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (!file.name.endsWith('.prompt.md')) continue;
      if (!file.name.contains('.apm/prompts/') &&
          !file.name.startsWith('.apm/prompts/')) continue;

      try {
        final content = utf8.decode(file.content as List<int>);
        prompts.add(PromptFileParser.parseFile(content));
      } catch (_) {
        // Skip malformed files
      }
    }

    return ApmPackage(name: name, version: version, prompts: prompts);
  }

  /// Writes parsed prompts to the repository.
  /// Prompts with no path use [fallbackPath].
  static Future<ImportResult> importParsed(
    ApmPackage package,
    PromptRepository repo, {
    required List<String> fallbackPath,
  }) async {
    int imported = 0;
    int skipped = 0;

    for (final p in package.prompts) {
      try {
        final effectivePath = p.path.isEmpty ? fallbackPath : p.path;
        final modelTags = p.modelTags.join(',');

        await repo.create(
          title: p.title,
          body: p.body,
          path: effectivePath,
          searchTags: p.searchTags,
          modelTags: modelTags,
          pinned: p.pinned,
        );
        imported++;
      } catch (_) {
        skipped++;
      }
    }

    return ImportResult(
      imported: imported,
      skipped: skipped,
      packName: package.name,
      packVersion: package.version,
    );
  }

  static (String name, String version) _parseApmYml(String content) {
    String name = 'imported-pack';
    String version = '0.0.1';
    for (final line in content.split('\n')) {
      if (line.startsWith('name:')) {
        name = line.substring(5).trim().replaceAll('"', '');
      } else if (line.startsWith('version:')) {
        version = line.substring(8).trim().replaceAll('"', '');
      }
    }
    return (name, version);
  }
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/services/import_service_test.dart
```

Expected: all 6 tests pass.

- [ ] **Step 5: Run full test suite**

```bash
flutter test 2>&1 | tail -3
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/services/import_service.dart test/services/import_service_test.dart
git commit -m "feat: ImportService — ZIP parsing + DB import with fallback path"
```

---

## Task 5: UI Sheets

**Files:**
- Create: `lib/features/settings/widgets/export_scope_sheet.dart`
- Create: `lib/features/settings/widgets/folder_assignment_sheet.dart`

- [ ] **Step 1: Create export_scope_sheet.dart**

```dart
// lib/features/settings/widgets/export_scope_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/prompt_provider.dart';
import '../../../services/export_service.dart';

class ExportScopeSheet extends ConsumerWidget {
  const ExportScopeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(promptsStreamProvider);

    return allAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('$e'),
      ),
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
              const Text('Choose what to include in the ZIP',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 16),
              _ScopeOption(
                label: 'All prompts',
                count: all.length,
                onTap: () => context.pop(ExportScope.all),
              ),
              const SizedBox(height: 8),
              _ScopeOption(
                label: 'Your prompts',
                count: yourCount,
                onTap: yourCount > 0 ? () => context.pop(ExportScope.yours) : null,
              ),
              const SizedBox(height: 8),
              _ScopeOption(
                label: 'Starter library',
                count: starterCount,
                onTap: starterCount > 0 ? () => context.pop(ExportScope.starters) : null,
              ),
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
    final enabled = onTap != null && count > 0;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              Text(
                '$count prompt${count == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create folder_assignment_sheet.dart**

```dart
// lib/features/settings/widgets/folder_assignment_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/database/app_database.dart';
import '../../library/widgets/folder_picker_sheet.dart';

class FolderAssignmentSheet extends StatelessWidget {
  const FolderAssignmentSheet({
    super.key,
    required this.count,
    required this.allPrompts,
  });

  final int count;
  final List<Prompt> allPrompts;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assign a folder', style: AppTypography.screenTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              '$count prompt${count == 1 ? '' : 's'} '
              'in this pack ${count == 1 ? 'has' : 'have'} no folder assigned. '
              'Where should ${count == 1 ? 'it' : 'they'} go?',
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5),
            ),
            const SizedBox(height: 12),
          ]),
        ),
        FolderPickerSheet(
          allPrompts: allPrompts,
          currentPath: const [],
          title: '', // title handled above
          onPick: (path) => Navigator.of(context).pop(path),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Build to verify**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/widgets/
git commit -m "feat: ExportScopeSheet and FolderAssignmentSheet UI"
```

---

## Task 6: Wire Settings Screen

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

Read `lib/features/settings/settings_screen.dart` first.

- [ ] **Step 1: Add imports to settings_screen.dart**

At the top of `settings_screen.dart`, add these imports (after existing ones):

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/prompt_repository.dart';
import '../../providers/prompt_provider.dart';
import '../../services/export_service.dart';
import '../../services/import_service.dart';
import '../../providers/repository_providers.dart';
import 'widgets/export_scope_sheet.dart';
import 'widgets/folder_assignment_sheet.dart';
```

- [ ] **Step 2: Add import and export methods to _SettingsScreenState**

Inside `_SettingsScreenState`, add these methods before `build()`:

```dart
Future<void> _onImport() async {
  // 1. Pick ZIP file
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['zip'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;
  final bytes = result.files.first.bytes;
  if (bytes == null) return;

  // 2. Parse ZIP
  ApmPackage pkg;
  try {
    pkg = ImportService.parseZip(bytes);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid ZIP: $e')));
    }
    return;
  }

  if (pkg.prompts.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No prompts found in this ZIP')));
    }
    return;
  }

  // 3. Folder assignment for path-less prompts
  List<String> fallbackPath = [];
  if (pkg.hasPathlessPrompts && mounted) {
    final allPrompts = await ref.read(promptRepositoryProvider).getAll();
    if (!mounted) return;
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => FolderAssignmentSheet(
        count: pkg.pathlessCount,
        allPrompts: allPrompts,
      ),
    );
    if (picked == null) return; // user cancelled
    fallbackPath = picked;
  }

  // 4. Import
  final repo = ref.read(promptRepositoryProvider);
  final importResult = await ImportService.importParsed(pkg, repo, fallbackPath: fallbackPath);

  // 5. Show result
  if (mounted) {
    final msg = importResult.skipped > 0
        ? 'Imported ${importResult.imported} prompts from ${importResult.packName} '
          '(${importResult.skipped} skipped)'
        : 'Imported ${importResult.imported} prompts from ${importResult.packName} v${importResult.packVersion}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

Future<void> _onExport() async {
  // 1. Scope picker
  if (!mounted) return;
  final scope = await showModalBottomSheet<ExportScope>(
    context: context,
    backgroundColor: AppColors.surface2,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const ExportScopeSheet(),
  );
  if (scope == null) return;

  // 2. Get prompts
  final all = await ref.read(promptRepositoryProvider).getAll();
  final prompts = switch (scope) {
    ExportScope.all => all,
    ExportScope.yours => all.where((p) => !p.isStarter).toList(),
    ExportScope.starters => all.where((p) => p.isStarter).toList(),
  };

  if (prompts.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No prompts to export')));
    }
    return;
  }

  // 3. Build ZIP
  final zipBytes = await ExportService.buildZip(prompts);

  // 4. Share
  final tempDir = await getTemporaryDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final file = File('${tempDir.path}/loadstash-export-$timestamp.zip');
  await file.writeAsBytes(zipBytes);

  if (mounted) {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Loadstash prompt pack',
    );
  }
}
```

- [ ] **Step 3: Wire the Import and Export buttons**

Find the two `_SettingsRow` entries for import and export. Replace their `onTap` callbacks and update labels from "YAML" to "ZIP":

```dart
_SettingsRow(
  icon: Icons.download_outlined,
  title: 'Import from ZIP',
  desc: 'Add prompts from an APM .zip pack',
  right: _Badge(label: 'Import', accent: true),
  onTap: _onImport,
),
_SettingsRow(
  icon: Icons.upload_outlined,
  title: 'Export to ZIP',
  desc: 'Share prompts as an APM .zip pack',
  right: const _Badge(label: 'Export'),
  onTap: _onExport,
),
```

- [ ] **Step 4: Build and verify**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

If you see `Undefined name 'ApmPackage'` — it comes from `import_service.dart`. Ensure the import is present at top of settings_screen.dart.

- [ ] **Step 5: Run full tests**

```bash
flutter test 2>&1 | tail -3
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat: wire Import ZIP + Export ZIP in settings, scope picker, folder assignment"
```

---

## Task 7: Integration Test + Final Build

**Files:**
- Create: `test/integration/import_export_test.dart`

- [ ] **Step 1: Write integration test**

Create `test/integration/import_export_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';
import 'package:loadstash/services/export_service.dart';
import 'package:loadstash/services/import_service.dart';
import 'package:loadstash/services/prompt_file_parser.dart';

void main() {
  late AppDatabase db;
  late PromptRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PromptRepository(db);
  });
  tearDown(() async => db.close());

  test('round-trip: export → import preserves title, body, path, tags', () async {
    // Seed a prompt
    await repo.create(
      title: 'Review this code',
      body: 'Review this {{language}} code for bugs:\n\n{{code}}',
      path: ['Dev', 'Reviews'],
      searchTags: ['dev', 'work'],
      modelTags: 'claude,chatgpt',
      pinned: true,
    );

    final all = await repo.getAll();

    // Export
    final zipBytes = await ExportService.buildZip(all);

    // Import into fresh DB
    final db2 = AppDatabase.forTesting(NativeDatabase.memory());
    final repo2 = PromptRepository(db2);
    final pkg = ImportService.parseZip(zipBytes);
    await ImportService.importParsed(pkg, repo2, fallbackPath: []);

    final imported = await repo2.getAll();
    expect(imported.length, 1);
    expect(imported.first.title, 'Review this code');
    expect(imported.first.body, contains('{{language}}'));
    expect(imported.first.body, contains('{{code}}'));
    expect(PromptRepository.decodePath(imported.first.path), ['Dev', 'Reviews']);
    expect(PromptRepository.decodePath(imported.first.searchTags), containsAll(['dev', 'work']));
    expect(imported.first.pinned, true);

    await db2.close();
  });

  test('import respects x-loadstash-model-tags over model:', () async {
    const promptMd = '''---
description: Multi-model prompt
model: claude
x-loadstash-model-tags: [claude, chatgpt, gemini]
---
Body here.
''';
    final archive = Archive();
    final apmBytes = utf8.encode('name: test\nversion: 1.0.0\n');
    archive.addFile(ArchiveFile('apm.yml', apmBytes.length, apmBytes));
    final mdBytes = utf8.encode(promptMd);
    archive.addFile(ArchiveFile('.apm/prompts/p.prompt.md', mdBytes.length, mdBytes));
    final zip = Uint8List.fromList(ZipEncoder().encode(archive)!);

    final pkg = ImportService.parseZip(zip);
    await ImportService.importParsed(pkg, repo, fallbackPath: []);
    final all = await repo.getAll();
    expect(all.first.modelTags.split(','), containsAll(['claude', 'chatgpt', 'gemini']));
  });

  test('ExportService produces valid APM .prompt.md with variable conversion', () {
    final md = ExportService.buildPromptMd(
      title: 'Summarize',
      body: 'Summarize {{text}} in {{length}} words.',
      variableNames: ['text', 'length'],
      variableHints: {'text': 'Paste text', 'length': 'Word count'},
      modelTags: [],
      path: [],
      searchTags: [],
      pinned: false,
    );
    // APM variable syntax in exported file
    expect(md, contains('\${input:text}'));
    expect(md, contains('\${input:length}'));
    expect(md, contains('- text: "Paste text"'));
    expect(md, isNot(contains('{{text}}')));
  });
}
```

- [ ] **Step 2: Run integration test**

```bash
flutter test test/integration/import_export_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 3: Run full test suite**

```bash
flutter test 2>&1 | tail -3
```

Expected: all tests pass (50+).

- [ ] **Step 4: Final build**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 5: Commit**

```bash
git add test/integration/import_export_test.dart
git commit -m "feat: import/export integration tests, APM ZIP import/export complete"
```

---

## Self-Review

| Spec requirement | Task |
|---|---|
| ZIP with apm.yml + .prompt.md files | Task 4 (ImportService.parseZip) + Task 3 (ExportService.buildZip) |
| `x-loadstash-*` frontmatter fields | Task 2 (PromptFileParser) + Task 3 (ExportService.buildPromptMd) |
| `${input:name}` ↔ `{{name}}` conversion | Task 2 (convertFromApm / convertToApm) |
| Input list with hints | Task 2 (VariableInput), Task 3 (buildPromptMd) |
| Missing apm.yml → throw ArgumentError | Task 4 (ImportService.parseZip) |
| Path-less prompts → FolderAssignmentSheet | Task 5 + Task 6 (_onImport) |
| Export scope picker (All/Yours/Starters) | Task 5 (ExportScopeSheet) + Task 6 (_onExport) |
| Empty scope → snackbar, no ZIP | Task 6 (_onExport) |
| Share via Android share sheet | Task 6 (_onExport, Share.shareXFiles) |
| Settings Import + Export buttons wired | Task 6 |
| Round-trip test | Task 7 |
| Duplicate filename deduplication | Task 3 (ExportService.buildZip, usedNames set) |
