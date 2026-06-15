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

  test('round-trip: export → import preserves title, body vars, path, tags, pinned', () async {
    await repo.create(
      title: 'Review this code',
      body: 'Review this {{language}} code for bugs:\n\n{{code}}',
      path: ['Dev', 'Reviews'],
      searchTags: ['dev', 'work'],
      modelTags: 'claude,chatgpt',
      pinned: true,
    );

    final all = await repo.getAll();
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

  test('x-loadstash-model-tags takes priority over model: field', () async {
    final archive = Archive();
    final apmBytes = utf8.encode('name: test\nversion: 1.0.0\n');
    archive.addFile(ArchiveFile('apm.yml', apmBytes.length, apmBytes));
    const md = '---\ndescription: Multi-model\nmodel: claude\n'
        'x-loadstash-model-tags: [claude, chatgpt, gemini]\n---\nBody.';
    final mdBytes = utf8.encode(md);
    archive.addFile(ArchiveFile('.apm/prompts/p.prompt.md', mdBytes.length, mdBytes));
    final zip = Uint8List.fromList(ZipEncoder().encode(archive)!);

    final pkg = ImportService.parseZip(zip);
    await ImportService.importParsed(pkg, repo, fallbackPath: []);
    final all = await repo.getAll();
    expect(all.first.modelTags.split(','), containsAll(['claude', 'chatgpt', 'gemini']));
  });

  test('export produces valid APM .prompt.md with variable syntax', () {
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
    expect(md, contains(r'${input:text}'));
    expect(md, contains(r'${input:length}'));
    expect(md, contains('- text: "Paste text"'));
    expect(md, isNot(contains('{{text}}')));
  });
}
