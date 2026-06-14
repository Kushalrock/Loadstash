import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';
import 'package:loadstash/data/repositories/usage_repository.dart';

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

  test('app-specific usage ranks prompt higher', () async {
    final claudeId = await promptRepo.create(title: 'Claude prompt', body: 'XML structured...');
    final gptId = await promptRepo.create(title: 'GPT prompt', body: 'Direct and casual...');

    await usageRepo.recordUsage(claudeId, 'com.anthropic.claude');
    await usageRepo.recordUsage(claudeId, 'com.anthropic.claude');
    await usageRepo.recordUsage(gptId, 'com.openai.chatgpt');
    await usageRepo.recordUsage(gptId, 'com.openai.chatgpt');

    final ranked = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(ranked.first.id, claudeId);
  });

  test('pinned prompts always lead', () async {
    final normalId = await promptRepo.create(title: 'Normal', body: 'Text');
    final pinnedId = await promptRepo.create(title: 'Pinned', body: 'Text', pinned: true);

    for (var i = 0; i < 10; i++) {
      await usageRepo.recordUsage(normalId, 'com.anthropic.claude');
    }

    final ranked = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(ranked.first.id, pinnedId);
  });

  test('no usage returns all prompts (pinned first)', () async {
    await promptRepo.create(title: 'A', body: 'Text');
    final pinnedId = await promptRepo.create(title: 'B', body: 'Text', pinned: true);

    final ranked = await usageRepo.getRankedPrompts('com.anthropic.claude');
    expect(ranked.length, 2);
    expect(ranked.first.id, pinnedId);
  });

  test('variables auto-detected on create', () async {
    final id = await promptRepo.create(
      title: 'Template',
      body: 'Write a {{format}} about {{topic}} for {{audience}}',
    );
    final vars = await promptRepo.getVariablesFor(id);
    expect(vars.map((v) => v.name).toList(), ['format', 'topic', 'audience']);
  });
}
