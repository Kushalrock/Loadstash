import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';
import 'package:loadstash/data/repositories/usage_repository.dart';
import 'package:loadstash/services/variable_detector.dart';

// Tests the core overlay user journey end-to-end (without Flutter UI):
// create prompt → rank → detect vars → substitute → record usage → re-rank

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

  test('full overlay flow: create, rank, fill vars, record usage', () async {
    // 1. Create a prompt with variables
    final id = await promptRepo.create(
      title: 'Rewrite in {{tone}} for {{audience}}',
      body: 'Rewrite the following in {{tone}} for {{audience}}:\n\n{{text}}',
    );

    // 2. Verify variables were auto-detected
    final vars = await promptRepo.getVariablesFor(id);
    expect(vars.map((v) => v.name).toList(), ['tone', 'audience', 'text']);

    // 3. Initial ranking — prompt should appear
    final initial = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(initial.any((p) => p.id == id), true);

    // 4. Simulate overlay: detect vars, substitute values
    final prompt = await promptRepo.getById(id);
    final detectedVars = VariableDetector.detect(prompt!.body);
    expect(detectedVars, ['tone', 'audience', 'text']);

    final assembled = VariableDetector.substitute(prompt.body, {
      'tone': 'formal',
      'audience': 'executives',
      'text': 'We missed our Q3 targets.',
    });
    expect(assembled, contains('formal'));
    expect(assembled, contains('executives'));
    expect(assembled, isNot(contains('{{tone}}')));

    // 5. Record usage
    await usageRepo.recordUsage(id, 'com.anthropic.claude');
    await usageRepo.recordUsage(id, 'com.anthropic.claude');

    // 6. Re-rank — should now be first for Claude
    final reRanked = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(reRanked.first.id, id);
  });

  test('starter prompts seed correctly', () async {
    // Seed a few starter prompts
    await promptRepo.create(title: 'Starter 1', body: 'Body 1', isStarter: true);
    await promptRepo.create(title: 'Starter 2', body: 'Body 2', isStarter: true);
    await promptRepo.create(title: 'My prompt', body: 'Custom body', isStarter: false);

    final all = await promptRepo.getAll();
    expect(all.length, 3);

    final starters = all.where((p) => p.isStarter).toList();
    final mine = all.where((p) => !p.isStarter).toList();
    expect(starters.length, 2);
    expect(mine.length, 1);
    expect(mine.first.title, 'My prompt');
  });
}
