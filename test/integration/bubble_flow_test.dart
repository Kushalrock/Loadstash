import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';
import 'package:loadstash/data/repositories/usage_repository.dart';
import 'package:loadstash/services/variable_detector.dart';

// Verifies the bubble insertion path end-to-end (no Flutter UI needed):
// create prompt → rank without callingPackage → detect vars → substitute → record usage

void main() {
  late AppDatabase db;
  late PromptRepository promptRepo;
  late UsageRepository usageRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    promptRepo = PromptRepository(db);
    usageRepo = UsageRepository(db);
  });

  tearDown(() async => db.close());

  test('bubble path: create prompt, rank without callingPackage, substitute vars', () async {
    final id = await promptRepo.create(
      title: 'Write an email',
      body: 'Write a professional email about: {{topic}}\n\nTone: {{tone}}',
    );

    // Bubble mode ranks without callingPackage — should still return the prompt
    final ranked = await usageRepo.getRankedPrompts('');
    expect(ranked.any((p) => p.id == id), true);

    final prompt = await promptRepo.getById(id);
    final vars = VariableDetector.detect(prompt!.body);
    expect(vars, ['topic', 'tone']);

    final assembled = VariableDetector.substitute(
      prompt.body,
      {'topic': 'project update', 'tone': 'formal'},
    );
    expect(assembled, contains('project update'));
    expect(assembled, isNot(contains('{{topic}}')));

    // Record usage with empty package (bubble mode)
    await usageRepo.recordUsage(id, '');
    final stat = await db.usageDao.getUsageStat(id, '');
    expect(stat!.count, 1);
  });

  test('bubble mode does not require callingPackage', () async {
    await promptRepo.create(title: 'A', body: 'Body A');
    await promptRepo.create(title: 'B', body: 'Body B');

    final ranked = await usageRepo.getRankedPrompts('');
    expect(ranked.length, 2);
  });
}
