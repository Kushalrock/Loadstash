import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/database/tables/prompts_table.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and retrieve a prompt', () async {
    final id = await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'Test', body: 'Hello {{name}}'),
    );
    expect(id, greaterThan(0));

    final prompt = await db.promptDao.getPromptById(id);
    expect(prompt, isNotNull);
    expect(prompt!.title, 'Test');
    expect(prompt.body, 'Hello {{name}}');
    expect(prompt.pinned, false);
  });

  test('search prompts by title substring', () async {
    await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'Rewrite for professional tone', body: 'Rewrite this...'),
    );
    await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'Summarize', body: 'Summarize this text...'),
    );

    final results = await db.promptDao.searchPrompts('rewrite');
    expect(results.length, 1);
    expect(results.first.title, contains('Rewrite'));
  });

  test('record usage increments count', () async {
    final promptId = await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'T', body: 'B'),
    );

    await db.usageDao.recordUsage(promptId, 'com.anthropic.claude');
    await db.usageDao.recordUsage(promptId, 'com.anthropic.claude');

    final stat = await db.usageDao.getUsageStat(promptId, 'com.anthropic.claude');
    expect(stat!.count, 2);
  });

  test('delete prompt cascades usage stats', () async {
    final promptId = await db.promptDao.insertPrompt(
      PromptsCompanion.insert(title: 'T', body: 'B'),
    );
    await db.usageDao.recordUsage(promptId, 'com.openai.chatgpt');
    await db.promptDao.deletePrompt(promptId);

    final stat = await db.usageDao.getUsageStat(promptId, 'com.openai.chatgpt');
    expect(stat, isNull);
  });
}
