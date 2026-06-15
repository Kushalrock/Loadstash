import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/export_service.dart';

void main() {
  group('ExportService.slugifyTitle', () {
    test('converts spaces to hyphens and lowercases', () {
      expect(ExportService.slugifyTitle('Cold Outreach Email'), 'cold-outreach-email');
    });
    test('strips special characters', () {
      expect(ExportService.slugifyTitle('Review PR (fast!)'), 'review-pr-fast');
    });
    test('truncates to 60 chars', () {
      final result = ExportService.slugifyTitle('a' * 80);
      expect(result.length, lessThanOrEqualTo(60));
    });
    test('collapses multiple spaces', () {
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
      expect(md, contains(r'${input:name}'));
      expect(md, isNot(contains('{{name}}')));
    });

    test('omits model: when no model tags', () {
      final md = ExportService.buildPromptMd(
        title: 'T', body: 'B', variableNames: [], variableHints: {},
        modelTags: [], path: [], searchTags: [], pinned: false,
      );
      expect(md, isNot(contains('model:')));
    });
  });

  group('ExportService.buildApmYml', () {
    test('builds valid apm.yml', () {
      final yml = ExportService.buildApmYml(name: 'my-pack', version: '1.0.0', description: 'desc');
      expect(yml, contains('name: my-pack'));
      expect(yml, contains('version: 1.0.0'));
      expect(yml, contains('type: prompts'));
    });
  });
}
