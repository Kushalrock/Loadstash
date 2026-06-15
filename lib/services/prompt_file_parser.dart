import 'package:yaml/yaml.dart';

class VariableInput {
  const VariableInput({required this.name, required this.hint});
  final String name;
  final String hint;
}

class ParsedPrompt {
  const ParsedPrompt({
    required this.title, required this.body, required this.inputs,
    required this.modelTags, required this.path, required this.searchTags, required this.pinned,
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
  const ApmPackage({required this.name, required this.version, required this.prompts});
  final String name;
  final String version;
  final List<ParsedPrompt> prompts;
  bool get hasPathlessPrompts => prompts.any((p) => p.path.isEmpty);
  int get pathlessCount => prompts.where((p) => p.path.isEmpty).length;
}

abstract final class PromptFileParser {
  static ParsedPrompt parseFile(String content) {
    final parts = content.split('---');
    if (parts.length < 3) {
      return ParsedPrompt(title: 'Untitled', body: content.trim(),
          inputs: [], modelTags: [], path: [], searchTags: [], pinned: false);
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
    final xModelTags = _parseStringList(fm?['x-loadstash-model-tags']);
    final modelFallback = fm?['model']?.toString();
    final modelTags = xModelTags.isNotEmpty ? xModelTags
        : (modelFallback != null ? [modelFallback] : <String>[]);
    final path = _parseStringList(fm?['x-loadstash-path']);
    final searchTags = _parseStringList(fm?['x-loadstash-tags']);
    final pinned = fm?['x-loadstash-pinned'] == true;

    return ParsedPrompt(title: title, body: convertFromApm(body),
        inputs: inputs, modelTags: modelTags, path: path, searchTags: searchTags, pinned: pinned);
  }

  static String convertFromApm(String body) => body.replaceAllMapped(
    RegExp(r'\$\{input:([A-Za-z][\w-]*)\}'), (m) => '{{${m.group(1)}}}');

  static String convertToApm(String body) => body.replaceAllMapped(
    RegExp(r'\{\{([A-Za-z][\w-]*)\}\}'), (m) => '\${input:${m.group(1)}}');

  static List<VariableInput> _parseInputs(dynamic input) {
    if (input is! YamlList) return [];
    return input.map<VariableInput?>((item) {
      if (item is String) return VariableInput(name: item, hint: '');
      if (item is YamlMap && item.isNotEmpty) {
        final e = item.entries.first;
        return VariableInput(name: e.key.toString(), hint: e.value?.toString() ?? '');
      }
      return null;
    }).whereType<VariableInput>().toList();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is YamlList) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }
}
