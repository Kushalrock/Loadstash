import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/variable_detector.dart';

void main() {
  group('VariableDetector.detect', () {
    test('detects single variable', () {
      expect(VariableDetector.detect('Hello {{name}}'), ['name']);
    });

    test('deduplicates repeated variables', () {
      expect(
        VariableDetector.detect('Rewrite in {{tone}} for {{audience}}, keep it {{tone}}'),
        ['tone', 'audience'],
      );
    });

    test('ignores malformed patterns', () {
      expect(VariableDetector.detect('{tone} {{}} {{1invalid}}'), []);
    });

    test('returns empty for no variables', () {
      expect(VariableDetector.detect('Just plain text.'), []);
    });

    test('preserves order of first appearance', () {
      expect(VariableDetector.detect('{{b}} {{a}} {{c}} {{b}}'), ['b', 'a', 'c']);
    });
  });

  group('VariableDetector.substitute', () {
    test('replaces known variables', () {
      final result = VariableDetector.substitute(
        'Rewrite in {{tone}} for {{audience}}',
        {'tone': 'formal', 'audience': 'clients'},
      );
      expect(result, 'Rewrite in formal for clients');
    });

    test('leaves unknown variables unchanged', () {
      final result = VariableDetector.substitute(
        'Hello {{name}} from {{city}}',
        {'name': 'Alice'},
      );
      expect(result, 'Hello Alice from {{city}}');
    });

    test('replaces all occurrences of same variable', () {
      final result = VariableDetector.substitute('{{tone}} and {{tone}}', {'tone': 'formal'});
      expect(result, 'formal and formal');
    });
  });
}
