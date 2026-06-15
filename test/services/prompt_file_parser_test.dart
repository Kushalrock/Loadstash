import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/prompt_file_parser.dart';

void main() {
  group('PromptFileParser.parseFile', () {
    test('parses description, inputs with hints, body with variable conversion', () {
      const content = '---\n'
          'description: Cold outreach email\n'
          'input:\n'
          '  - name: "Recipient name"\n'
          '  - company: "Company name"\n'
          '  - length: "Max words e.g. 120"\n'
          'model: claude\n'
          'x-loadstash-path: [Writing, Email, Cold]\n'
          'x-loadstash-tags: [work, sales]\n'
          'x-loadstash-pinned: true\n'
          'x-loadstash-model-tags: [claude, chatgpt]\n'
          '---\n\n'
          r'Write a cold email to ${input:name} at ${input:company}. Under ${input:length} words.';
      final p = PromptFileParser.parseFile(content);
      expect(p.title, 'Cold outreach email');
      expect(p.inputs.map((i) => i.name).toList(), ['name', 'company', 'length']);
      expect(p.inputs.first.hint, 'Recipient name');
      expect(p.path, ['Writing', 'Email', 'Cold']);
      expect(p.searchTags, ['work', 'sales']);
      expect(p.pinned, true);
      expect(p.modelTags, ['claude', 'chatgpt']);
      expect(p.body, contains('{{name}}'));
      expect(p.body, isNot(contains(r'${input:name}')));
    });

    test('falls back to model: when no x-loadstash-model-tags', () {
      const content = '---\ndescription: Review PR\ninput:\n  - pr_url\nmodel: gemini\n---\n\n'
          r'Review ${input:pr_url}';
      final p = PromptFileParser.parseFile(content);
      expect(p.modelTags, ['gemini']);
    });

    test('handles simple input list without hints', () {
      const content = '---\ndescription: Simple\ninput: [topic, audience]\n---\n\n'
          r'Write about ${input:topic} for ${input:audience}.';
      final p = PromptFileParser.parseFile(content);
      expect(p.inputs.map((i) => i.name).toList(), ['topic', 'audience']);
      expect(p.inputs.first.hint, '');
    });

    test('returns empty collections when no x-loadstash fields', () {
      const content = '---\ndescription: No loadstash fields\n---\n\nJust a body.';
      final p = PromptFileParser.parseFile(content);
      expect(p.path, isEmpty);
      expect(p.searchTags, isEmpty);
      expect(p.pinned, false);
      expect(p.modelTags, isEmpty);
    });

    test('convertFromApm replaces \${input:name} with {{name}}', () {
      const body = r'Hello ${input:name} from ${input:city}.';
      expect(PromptFileParser.convertFromApm(body), 'Hello {{name}} from {{city}}.');
    });

    test('convertToApm replaces {{name}} with \${input:name}', () {
      const body = 'Hello {{name}} from {{city}}.';
      expect(PromptFileParser.convertToApm(body), r'Hello ${input:name} from ${input:city}.');
    });
  });
}
