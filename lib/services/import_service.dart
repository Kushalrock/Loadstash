import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../data/repositories/prompt_repository.dart';
import 'prompt_file_parser.dart';

class ImportResult {
  const ImportResult({
    required this.imported, required this.skipped,
    required this.packName, required this.packVersion,
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

    final apmFile = archive.files
        .where((f) => f.isFile && f.name == 'apm.yml')
        .firstOrNull;
    if (apmFile == null) throw ArgumentError('ZIP must contain apm.yml at root');

    final apmContent = utf8.decode(apmFile.content as List<int>);
    final (name, version) = _parseApmYml(apmContent);

    final prompts = <ParsedPrompt>[];
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (!file.name.endsWith('.prompt.md')) continue;
      // Accept any .prompt.md under .apm/prompts/ (any depth)
      if (!file.name.contains('prompts/')) continue;

      try {
        final content = utf8.decode(file.content as List<int>);
        prompts.add(PromptFileParser.parseFile(content));
      } catch (_) {}
    }

    return ApmPackage(name: name, version: version, prompts: prompts);
  }

  /// Writes parsed prompts to the repository.
  static Future<ImportResult> importParsed(
    ApmPackage package,
    PromptRepository repo, {
    required List<String> fallbackPath,
  }) async {
    int imported = 0;
    int skipped = 0;

    for (final p in package.prompts) {
      try {
        await repo.create(
          title: p.title,
          body: p.body,
          path: p.path.isEmpty ? fallbackPath : p.path,
          searchTags: p.searchTags,
          modelTags: p.modelTags.join(','),
          pinned: p.pinned,
        );
        imported++;
      } catch (_) {
        skipped++;
      }
    }

    return ImportResult(
      imported: imported, skipped: skipped,
      packName: package.name, packVersion: package.version,
    );
  }

  static (String name, String version) _parseApmYml(String content) {
    String name = 'imported-pack';
    String version = '0.0.1';
    for (final line in content.split('\n')) {
      if (line.startsWith('name:')) name = line.substring(5).trim().replaceAll('"', '');
      else if (line.startsWith('version:')) version = line.substring(8).trim().replaceAll('"', '');
    }
    return (name, version);
  }
}
