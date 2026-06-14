import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/prompts_table.dart';
import '../tables/variables_table.dart';

part 'prompt_dao.g.dart';

@DriftAccessor(tables: [Prompts, PromptVariables])
class PromptDao extends DatabaseAccessor<AppDatabase> with _$PromptDaoMixin {
  PromptDao(super.db);

  Future<List<Prompt>> getAllPrompts() =>
      (select(prompts)..orderBy([(t) => OrderingTerm.desc(t.pinned), (t) => OrderingTerm.desc(t.updatedAt)])).get();

  Stream<List<Prompt>> watchAllPrompts() =>
      (select(prompts)..orderBy([(t) => OrderingTerm.desc(t.pinned), (t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<Prompt?> getPromptById(int id) =>
      (select(prompts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertPrompt(PromptsCompanion entry) => into(prompts).insert(entry);

  Future<bool> updatePrompt(PromptsCompanion entry) => update(prompts).replace(entry);

  Future<int> deletePrompt(int id) =>
      (delete(prompts)..where((t) => t.id.equals(id))).go();

  Future<List<PromptVariable>> getVariablesForPrompt(int promptId) =>
      (select(promptVariables)..where((t) => t.promptId.equals(promptId))).get();

  Future<void> replaceVariables(int promptId, List<PromptVariablesCompanion> vars) async {
    await (delete(promptVariables)..where((t) => t.promptId.equals(promptId))).go();
    for (final v in vars) {
      await into(promptVariables).insert(v);
    }
  }

  Future<List<Prompt>> searchPrompts(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(prompts)
          ..where((t) => t.title.lower().like(q) | t.body.lower().like(q))
          ..orderBy([(t) => OrderingTerm.desc(t.pinned)]))
        .get();
  }
}
