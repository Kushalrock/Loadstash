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

    test('throws ArgumentError if apm.yml is missing', () {
      final archive = Archive();
      final zip = Uint8List.fromList(ZipEncoder().encode(archive)!);
      expect(() => ImportService.parseZip(zip), throwsArgumentError);
    });

    test('parses .prompt.md files', () {
      const promptContent = '---\n'
          'description: My prompt\n'
          'input:\n'
          '  - topic: "The topic"\n'
          '---\n\n'
          r'Write about ${input:topic}.';
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
      expect(ImportService.parseZip(zip).prompts.length, 1);
    });

    test('hasPathlessPrompts when a prompt has no x-loadstash-path', () {
      final zip = _buildZip(prompts: {'p.prompt.md': '---\ndescription: No path\n---\nBody'});
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

    test('uses fallback path for path-less prompts', () async {
      final zip = _buildZip(prompts: {
        'p.prompt.md': '---\ndescription: Path-less\n---\nHello {{name}}.',
      });
      final pkg = ImportService.parseZip(zip);
      await ImportService.importParsed(pkg, repo, fallbackPath: ['Inbox']);
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(PromptRepository.decodePath(all.first.path), ['Inbox']);
    });

    test('uses x-loadstash-path when present, ignores fallback', () async {
      const content = '---\ndescription: Has path\nx-loadstash-path: [Writing, Email]\n---\nBody.';
      final zip = _buildZip(prompts: {'p.prompt.md': content});
      final pkg = ImportService.parseZip(zip);
      await ImportService.importParsed(pkg, repo, fallbackPath: ['Inbox']);
      final all = await repo.getAll();
      expect(PromptRepository.decodePath(all.first.path), ['Writing', 'Email']);
    });
  });
}
