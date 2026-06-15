import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../data/database/app_database.dart';
import '../data/repositories/prompt_repository.dart';
import '../services/variable_detector.dart';
import 'prompt_file_parser.dart';

enum ExportScope { all, yours, starters }

abstract final class ExportService {
  static Future<Uint8List> buildZip(List<Prompt> prompts) async {
    final archive = Archive();

    final apmYml = buildApmYml(
      name: 'loadstash-export', version: '1.0.0',
      description: 'Exported prompts from Loadstash');
    final apmBytes = utf8.encode(apmYml);
    archive.addFile(ArchiveFile('apm.yml', apmBytes.length, apmBytes));

    final usedNames = <String>{};
    for (final prompt in prompts) {
      final path = PromptRepository.decodePath(prompt.path);
      final searchTags = PromptRepository.decodePath(prompt.searchTags);
      final modelTags = prompt.modelTags.split(',').where((s) => s.isNotEmpty).toList();
      final varNames = VariableDetector.detect(prompt.body);

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
        variableHints: const {},
        modelTags: modelTags,
        path: path,
        searchTags: searchTags,
        pinned: prompt.pinned,
      );
      final mdBytes = utf8.encode(md);
      archive.addFile(ArchiveFile(
          '.apm/prompts/$uniqueSlug.prompt.md', mdBytes.length, mdBytes));
    }

    final zipBytes = ZipEncoder().encode(archive)!;
    return Uint8List.fromList(zipBytes);
  }

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

    if (modelTags.isNotEmpty) sb.writeln('model: ${modelTags.first}');
    if (path.isNotEmpty) sb.writeln('x-loadstash-path: ${_yamlList(path)}');
    if (searchTags.isNotEmpty) sb.writeln('x-loadstash-tags: ${_yamlList(searchTags)}');
    sb.writeln('x-loadstash-pinned: $pinned');
    if (modelTags.isNotEmpty) sb.writeln('x-loadstash-model-tags: ${_yamlList(modelTags)}');

    sb.writeln('---');
    sb.writeln();
    sb.write(PromptFileParser.convertToApm(body));
    return sb.toString();
  }

  static String buildApmYml({
    required String name, required String version, required String description,
  }) => 'name: $name\nversion: $version\ndescription: ${_yamlStr(description)}\ntype: prompts\n';

  static String slugifyTitle(String title) {
    final slug = title.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    return slug.length > 60 ? slug.substring(0, 60) : slug;
  }

  static String _yamlStr(String s) {
    if (s.contains(':') || s.contains('#') || s.contains('"')) {
      return '"${s.replaceAll('"', '\\"')}"';
    }
    return s;
  }

  static String _yamlList(List<String> list) =>
    '[${list.map(_yamlStr).join(', ')}]';
}
